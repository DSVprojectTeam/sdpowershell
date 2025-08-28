function Build-QADUserExportCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Country,   # Example: Egypt

        [Parameter(Mandatory = $true)]
        [string[]]$Properties  # Example: employeeID, SamAccountName, UserPrincipalName
    )

    try {
        $ErrorActionPreference = "Stop"

        # Join properties into a string
        $propertiesList = $Properties -join ", "

        # Build one-liner
        $command = @"
Get-QADUser -LdapFilter "(co=$Country)" -IncludeAllProperties -SizeLimit 0 |
    Select-Object $propertiesList |
    Export-Csv -Path ".\$($Country).csv" -Encoding UTF8 -NoTypeInformation -Delimiter ";"
"@

        Write-Host "`n=== COPY & PASTE ONE-LINER ===`n"
        Write-Host $command -ForegroundColor Cyan
        return $command
    }
    catch {
        return @{ error = "Raptor404"; reason = $_.Exception.Message } | ConvertTo-Json
    }
    #Build-QADUserExportCommand "Egypt" employeeId, sn
}