function Build-QADUserExportCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Country,

        [switch]$GivenName,
        [switch]$Surname,
        [switch]$Mail,
        [switch]$EmployeeID,
        [switch]$Username,
        [switch]$Title,
        [switch]$Department
    )

    try {
        $ErrorActionPreference = "Stop"

        # Collect properties based on switches
        $properties = @()
        if ($GivenName)  { $properties += "GivenName" }
        if ($Surname)    { $properties += "sn" }
        if ($Mail)       { $properties += "mail" }
        if ($EmployeeID) { $properties += "employeeID" }
        if ($Username)   { $properties += "SamAccountName" }
        if ($Title)      { $properties += "Title" }
        if ($Department) { $properties += "Department" }

        if ($properties.Count -eq 0) {
            return "Raptor404: No properties selected."
        }

        $propertiesList = $properties -join ", "

        # Build one-liner
        $command = @"
Get-QADUser -LdapFilter "(co=$Country)" -IncludeAllProperties -SizeLimit 0 |
    Select-Object $propertiesList |
    Export-Csv -Path ".\$($Country).csv" -Encoding UTF8 -NoTypeInformation
"@

        Write-Host "`n=== COPY & PASTE ONE-LINER ===`n"
        Write-Host $command -ForegroundColor Cyan
        return $command
    }
    catch {
        return @{ error = "Raptor404"; reason = $_.Exception.Message } | ConvertTo-Json
    }
}
# === Auto-invoke if argument passed ===
if ($MyInvocation.InvocationName -ne '.' -and $args.Count -eq 1) {
    $result = Build-QADUserExportCommand -UserIdentifier $args[0]
    Write-Host $result
}
