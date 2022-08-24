function Get-S1DvQueryResult {
	[CmdletBinding(DefaultParameterSetName="Default")]
	Param(
		[Parameter(Mandatory=$True)]
		[String]
		$QueryID,

		[Parameter(Mandatory=$True,ParameterSetName="CountOnly")]
		[Switch]
		$CountOnly
	)

	# Log the function and parameters being executed
	$InitializationLog = $MyInvocation.MyCommand.Name
	$MyInvocation.BoundParameters.GetEnumerator() | ForEach-Object { $InitializationLog = $InitializationLog + " -$($_.Key) $($_.Value)" }
	Write-Log -Message $InitializationLog -Level Informational


	$URI = "/web/api/v2.1/dv/events"
	$Parameters = @{}
	$Parameters.Add("queryId", $QueryID)
	$Method = "GET"

	if ($PSCmdlet.ParameterSetName -eq "CountOnly") {
		$Response = Invoke-S1Query -URI $URI -Method $Method -Parameters $Parameters
		return $Response.pagination.totalItems
	}

	$Response = Invoke-S1Query -URI $URI -Method $Method -Parameters $Parameters -Recurse -MaxCount 100
	return $Response.data
}