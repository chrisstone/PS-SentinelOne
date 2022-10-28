
Properties {
	# Find the build folder based on build system
	$ProjectRoot = $ENV:BHProjectPath
	If (-not $ProjectRoot) {
		$ProjectRoot = Resolve-Path "$PSScriptRoot\.."
	}

	$Timestamp = ((Get-Date).ToUniversalTime() | Get-Date -f 's').Replace(':','-') + 'Z'

	$Verbose = @{}
	if($ENV:BHCommitMessage -match "!verbose")
	{
		$Verbose = @{Verbose = $True}
	}
}

TaskSetup {

	Write-Output "".PadRight(70,'-')

}

Task Default -depends Test

Task Init {

	Set-Location $ProjectRoot
	"Build System Details:"
	Get-Item ENV:BH*
	Write-Output $Timestamp

	# Testing links on github requires >= tls 1.2
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

}

Task Test -depends Init  {

	# Gather test results. Store them in a variable and file
	$PesterConf = [PesterConfiguration]@{
		Run = @{
			Path = "$ProjectRoot\Tests"
			PassThru = $true
		}
		TestResult = @{
			Enabled = $true
			OutputPath = ("{0}\TestResult_{1}_{2}.xml" -f $ProjectRoot, $PSVersionTable.PSVersion.Major, $TimeStamp)
			OutputFormat = "NUnitXml"
		}
	}
	$TestResults = Invoke-Pester -Configuration $PesterConf

	# In Appveyor?  Upload our tests! #Abstract this into a function?
	If ($ENV:BHBuildSystem -eq 'AppVeyor') {
		(New-Object 'System.Net.WebClient').UploadFile(
			"https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
			$PesterConf.TestResult.OutputPath.Value )
	}

	# Cleanup
	Remove-Item -Path $PesterConf.TestResult.OutputPath.Value -Force -ErrorAction SilentlyContinue

	# Failed tests?
	# Need to tell psake or it will proceed to the deployment. Danger!
	If ($TestResults.FailedCount -gt 0) {
		Write-Error ("Failed {0} tests, build failed" -f $TestResults.FailedCount)
	}

}

Task Build -depends Test {

	Write-Output "Updating Module Manifest:"
	Write-Output "    Functions"
	Set-ModuleFunction
	Write-Output "    Aliases"
	Set-ModuleAlias

	# Prerelease
	Write-Output "    Prerelease Metadata"
	If ($env:BHBranchName -eq 'release') {
		# Remove "Prerelease" from Manifest
		Set-Content -Path $env:BHPSModuleManifest -Value (Get-Content -Path $env:BHPSModuleManifest | Select-String -Pattern 'Prerelease' -NotMatch)
	} else {
		# Add/Update Prerelease Version
		Update-Metadata -Path $env:BHPSModuleManifest -PropertyName Prerelease -Value "PRE$(($env:BHCommitHash).Substring(0,7))"
	}

	# Build Number from CI
	Write-Output "    Version Build"
	[Version] $Ver = Get-Metadata -Path $env:BHPSModuleManifest -PropertyName 'ModuleVersion'
	Update-Metadata -Path $env:BHPSModuleManifest -PropertyName 'ModuleVersion' -Value (@($Ver.Major,$Ver.Minor,$Env:BHBuildNumber) -join '.')

}

Task Deploy -depends Build {

	$Params = @{
		Path = "$ProjectRoot"
		Force = $true
		Recurse = $false # We keep psdeploy artifacts, avoid deploying those : )
	}
	Write-Output "Invoking PSDeploy"
	Invoke-PSDeploy @Verbose @Params

}
