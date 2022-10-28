function Remove-S1Site {
	<#
	.NOTES
		Author:			Michael Stafford
		Date-Modified:	2022-08-25 12:23:35

	.SYNOPSIS
		Delete SentinelOne site

	.PARAMETER ID
		Site's ID number as a string

	#>

	[CmdletBinding(DefaultParameterSetName="All")]
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$ID
	)
	Process {
		# Log the function and parameters being executed
		$InitializationLog = $MyInvocation.MyCommand.Name
		$MyInvocation.BoundParameters.GetEnumerator() | ForEach-Object { $InitializationLog += " -$($_.Key) $($_.Value)"}
		Write-Log -Message $InitializationLog -Level Informational

		$URI = "/web/api/v2.1/sites/$ID"

		$Response = Invoke-S1Query -URI $URI -Method DELETE

		Write-Output $Response.data
	}
}