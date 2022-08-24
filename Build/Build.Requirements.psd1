@{
	# Some defaults for all dependencies
	PSDependOptions		= @{
		Target			= '$ENV:USERPROFILE\Documents\WindowsPowerShell\Modules'
		AddToPath		= $True
		<# Parameters = @{
			Force = $True
		} #>
	}

	# Grab some modules without depending on PowerShellGet
	'psake'				= @{
		DependencyType	= 'PSGalleryNuget'
		Force			= $True
	}

	'PSDeploy'			= @{
		DependencyType	= 'PSGalleryNuget'
		Force			= $True
	}

	'BuildHelpers'		= @{
		DependencyType	= 'PSGalleryNuget'
		Force			= $True
	}

	'Pester'			= @{
		DependencyType	= 'PSGalleryNuget'
		Force			= $True
	}

	'PSDocs'			= @{
		DependencyType	= 'PSGalleryNuget'
		Force			= $True
	}

}