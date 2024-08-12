BeforeAll {
	$ModuleName = 'PS-SentinelOne'
	$RootDir = (Get-Location).Path
	$ModuleDir = Join-Path $RootDir $ModuleName
	$ModulePsm1Path = Join-Path $ModuleDir "$ModuleName.psm1"
	$ModulePsd1Path = Join-Path $ModuleDir "$ModuleName.psd1"
	$PublicFunctionsDir = Join-Path $ModuleDir 'Public'
	$PrivateFunctionsDir = Join-Path $ModuleDir 'Private'
	$TestDir = Join-Path $RootDir 'Tests'
}

Describe "Module Basics" {
	Context "Module Files Exist" {
		It "Psm1 file exists" {
			Write-Output "PSM" $ModulePsm1Path
			$ModulePsm1Path | Should -Exist
		}

		It "Psd1 file exists" {
			$ModulePsd1Path | Should -Exist
		}
	}

	Context "Module Files are Valid" {
		It "Psm1 file can be parsed" {
			$Content = Get-Content -Path $ModulePsm1Path -Raw
			$null = [System.Management.Automation.PSParser]::Tokenize($Content, [ref]$null)
		}

		It "Psd1 file can be imported" {
			{ Import-Module $ModulePsd1Path -ErrorAction Stop } | Should -Not -Throw
		}
	}
}

Describe "Module Function FIles" {
	BeforeAll {
		$ApprovedVerbs = Get-Verb | Select-Object -ExpandProperty Verb
		$Functions = Get-Command -Module (Split-Path $ModulePsm1Path -Leaf) | Where-Object { $_.CommandType -eq 'Function' }
	}

	Context "Module Function <_>" -ForEach $Functions {
		$Function = $_

		It "$($Function.Name) uses an approved verb" {
			$Function.Verb | Should -BeIn $ApprovedVerbs
		}

		It "$($Function.Name).ps1 exists in Public or Private" {
			$PublicFunctionPath = Join-Path $PublicFunctionsDir "$($Function.Name).ps1"
			$PrivateFunctionPath = Join-Path $PrivateFunctionsDir "$($Function.Name).ps1"
                ($PublicFunctionPath | Test-Path -Or ($PrivateFunctionPath | Test-Path)) | Should -BeTrue
		}

		It "$($Function.Name).ps1 has help content" {
			$FunctionHelp = Get-Help -Name $Function.Name -ErrorAction SilentlyContinue
			$FunctionHelp | Should -Not -BeNull
		}
	}
}

# Ideas https://www.red-gate.com/simple-talk/sysadmin/powershell/testing-powershell-modules-with-pester/
#       https://www.burkard.it/2019/08/pester-tests-for-powershell-functions/