Properties {
	$ProjectRoot = Resolve-Path $PSScriptRoot
	$ModuleRoot = (Get-ChildItem -Recurse -Filter *.psm1 | Select-Object -First 1).DirectoryName
}

TaskSetup {
	Write-Output "".PadRight(70, '-')
}

Task Default -depends Test

Task Init {
	Set-Location $ProjectRoot
	Set-BuildEnvironment
	"Build System Details:"
	Get-Item ENV:BH*
}

Task Test -depends Init {
	# Pester
	Import-Module Pester
	$PesterConf = [PesterConfiguration]@{
		Run        = @{
			Path     = "$ProjectRoot\Tests"
			PassThru = $true
		}
		TestResult = @{
			Enabled      = $true
			OutputPath   = ("{0}\Unit.Tests.xml" -f $ProjectRoot)
			OutputFormat = "NUnitXml"
		}
	}
	$TestResults = Invoke-Pester -Configuration $PesterConf
	If ($TestResults.FailedCount -gt 0) {
		Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed" -ErrorAction Stop
	}

	# PSScriptAnalyzer
	Invoke-ScriptAnalyzer -Path (Join-Path $ModuleRoot *.ps1) -Recurse -OutVariable issues
	$errors = $issues.Where({ $_.Severity -eq 'Error' })
	$warnings = $issues.Where({ $_.Severity -eq 'Warning' })
	if ($errors) {
		Write-Error "There were $($errors.Count) errors and $($warnings.Count) warnings total." -ErrorAction Stop
	} else {
		Write-Output "There were $($errors.Count) errors and $($warnings.Count) warnings total."
	}
}

Task Build -depends Test {
	Write-Output "Updating Module Manifest:"
	$ManifestData = Import-PowerShellDataFile -Path (Get-ChildItem -Path $ModuleRoot -Filter '*.psd1').FullName

	# FunctionsToExport, AliasesToExport; from BuildHelpers
	Write-Output "-Functions"
	Set-ModuleFunction
	Write-Output "-Aliases"
	Set-ModuleAlias

	# Version from Tag/CI
	$pattern = '(\d+(\.\d+)+)?$'
	if ($env:BHBranchName -match $pattern) {
		[Version] $Ver = $Matches[0]
	} else {
		[Version] $Ver = Get-Metadata -Path $env:BHPSModuleManifest -PropertyName 'ModuleVersion'
	}
	if ($env:GITHUB_RUNNUMBER) {
		$Build = $env:GITHUB_RUNNUMBER
	} else {
		$Build = $Env:BHBuildNumber
	}
	Update-Metadata -Path $env:BHPSModuleManifest -PropertyName 'ModuleVersion' -Value (@($Ver.Major, $Ver.Minor, $Build) -join '.')
	Write-Output ("-Version {0}" -f $Ver.ToString())

	# Prerelease
	If ($env:BHBranchName -match 'tags') {
		Write-Output "-Release Metadata"
		# Remove "Prerelease" from Manifest
		Set-Content -Path $env:BHPSModuleManifest -Value (Get-Content -Path $env:BHPSModuleManifest | Select-String -Pattern 'Prerelease' -NotMatch)
	} else {
		Write-Output "-Prerelease Metadata"
		# Update Prerelease Version
		Update-Metadata -Path $env:BHPSModuleManifest -PropertyName Prerelease -Value "PRE$(($env:BHCommitHash).Substring(0,7))"
	}
}

Task Publish -depends Build {
	$publishParams = @{
		Path        = $ModuleRoot
		NuGetApiKey = $env:NuGetApiKey
	}

	if ($Repository) {
		$publishParams['Repository'] = $Repository
	}

	Publish-Module @publishParams
}