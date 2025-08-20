function Get-UserPhoneNumbers {
    param(
        [Parameter(Mandatory = $true, Position=0)]
        [string]$UserIdentifier  # Can be samAccountName, DisplayName, Email, or DN
    )

    try {
        $ErrorActionPreference = "Stop"

        # Try to resolve user
        $user = Get-QADUser -Identity $UserIdentifier -IncludeAllProperties -SizeLimit 0
        if (-not $user) {
            return @{ Error = "Raptor404"; Reason = "User not found" } | ConvertTo-Json
        }

        # Collect phone attributes (some may be empty)
        $phones = [PSCustomObject]@{
            Name               = $user.Name
            SamAccountName     = $user.SamAccountName
            DN                 = $user.DN
            TelephoneNumber    = $user.TelephoneNumber
            Mobile             = $user.Mobile
            OtherMobile        = $user.otherMobile
        }

        return $phones | ConvertTo-Json -Depth 3
    }
    catch {
        return @{ Error = "Raptor404"; Reason = $_.Exception.Message } | ConvertTo-Json
    }
}

# === Auto-invoke if argument passed ===
if ($MyInvocation.InvocationName -ne '.' -and $args.Count -eq 1) {
    $result = Get-UserPhoneNumbers -UserIdentifier $args[0]
    Write-Host $result
}
