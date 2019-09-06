# Get-DS_IPS_Rules
AUTHOR		: Yanni Kashoqa

TITLE		: Deep Security Agent Integrity Monitoring Rules Removal

DESCRIPTION	: This Powershell script will retrieve Deep Security IPS Rules of all systems based on assigned Policy ID:

FEATURES
The ability to retreived the following IPS rules:-
- Assigned 
- Scan Recommendations for Assignment
- Scan Recommendations for Un-Assignment

REQUIRMENTS
- Supports Deep Security as a Service
- PowerShell 6.x
- An API key that is created on DSaaS console
- Policy ID
- Create a DS-Config.json in the same folder with the following content:
{
    "MANAGER": "app.deepsecurity.trendmicro.com",
    "PORT": "443",
    "APIKEY" : "",
    "POLICYID" : "",
    "LOOKUP_OBJECT" : "Assigned",
    "REPORTNAME" : "DSaaS_Agent_Report"
}

LOOKUP_OBJECT options are:
    - Assigned
    - RecommendedToAssign
    - RecommendedToUnAssign