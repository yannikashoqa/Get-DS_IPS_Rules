Clear-Host
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

$ErrorActionPreference = 'Stop'

$Config     	= (Get-Content "$PSScriptRoot\DS-Config.json" -Raw) | ConvertFrom-Json
$Manager    	= $Config.MANAGER
$Port       	= $Config.PORT
$APIKEY     	= $Config.APIKEY
$LOOKUP_OBJECT	= $Config.LOOKUP_OBJECT
$REPORTNAME 	= $Config.REPORTNAME
$POLICYID		= $Config.POLICYID

$REPORTFILE          = $REPORTNAME + ".csv"
$StartTime  = $(get-date)

$PS_Version =	$PSVersionTable.PSVersion.Major
$PSVersionRequired = "6"

If ($PS_Version -ne $PSVersionRequired){
	Write-Host "[ERROR]	Pwershell version is $PS_Version. Powershell version $PSVersionRequired is required."
	Exit
}

$DSM_URI             = "https://" + $Manager + ":" + $Port
$Search_Uri			= "$DSM_URI/api/computers/search"

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("api-secret-key", $APIKEY)
$headers.Add("api-version", 'v1')
$Headers.Add("Content-Type", 'application/json')

$SearchCriteria = @{
	searchCriteria = @{
		fieldName = "policyID"
		numericTest = "equal"
		numericValue = $POLICYID
		}
	sortByObjectID = "true"
}

$SearchCriteria_JSON = $SearchCriteria | ConvertTo-Json

$Computers = Invoke-RestMethod -Uri $Search_Uri -Method Post -Headers $Headers -Body $SearchCriteria_JSON

if ((Test-Path $REPORTFILE) -eq $true){
	$BackupDate          = get-date -format MMddyyyy-HHmm
	$BackupReportName    = $REPORTNAME + "_" + $BackupDate + ".csv"
	copy-item -Path $REPORTFILE -Destination $BackupReportName
	Remove-item $REPORTFILE
}

$ReportHeader = 'Computer ID, Host Name, Display Name, DPI Rule Identifier, Severity, Name'
Add-Content -Path $REPORTFILE -Value $ReportHeader

foreach ($Computer in $Computers.computers){
	$ComputerID		= $Computer.ID
	$HostName		= $Computer.hostName
	$DisplayName	= $Computer.displayName
	$DPI_apipath	= "/api/computers/$ComputerID/intrusionprevention/assignments"
	$DPI_Uri		= $DSM_URI + $DPI_apipath

	$DPIAssignment	= Invoke-RestMethod -Uri $DPI_Uri -Method Get -Headers $Headers

	Switch ($LOOKUP_OBJECT) {
		"Assigned" {
			$AssignedDPIRules = $DPIAssignment.assignedRuleIDs
			$LookupObject = $AssignedDPIRules
		}
		"RecommendedToAssign" {
			$RecommendedToAssignDPIRules = $DPIAssignment.recommendedToAssignRuleIDs
			$LookupObject = $RecommendedToAssignDPIRules			
		}
		"RecommendedToUnAssign" {			
			$RecommendedToUnassignDPIRules = $DPIAssignment.recommendedToUnassignRuleIDs
			$LookupObject = $RecommendedToUnassignDPIRules
		}
		Default {
			Write-Host "Look Up Object not Found.  Please update DS-Config with correct values."
			Exit	
		}
	}

	foreach ($item in $LookupObject){
		$DPIRuleURL			= $DSM_URI + "/api/intrusionpreventionrules/$item"
		$objDPIRule			= Invoke-RestMethod -Uri $DPIRuleURL -Method Get -Headers $Headers
		$DPIRuleIdentifier	= $objDPIRule.identifier
		$DPIRuleName		= $objDPIRule.Name
		$DPIRuleSeverity	= $objDPIRule.severity
		
		Write-Host $ComputerID	$HostName	$DisplayName	$DPIRuleIdentifier	$DPIRuleSeverity	$DPIRuleName 
	
		$ReportData =  "$ComputerID, $HostName, $DisplayName, $DPIRuleIdentifier, $DPIRuleSeverity, $DPIRuleName"
		Add-Content -Path $REPORTFILE -Value $ReportData
	
	}
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)

Write-Host "Report Generation is Complete.  It took $totalTime"