function Get-GroupMembers {
    param(
        [Parameter(Position=0)]
        [string]$GroupName # Dokładny cn ldapname grupy 
    )

    # Pomiar czasu
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $ErrorActionPreference = "Stop"

        # Wyszukaj grupę po nazwie (LDAP filter)
        $group = Get-QADGroup -LdapFilter "(name=$GroupName)"

        if ($group) {
            # Pobierz członków tej grupy i ich SAMAccountName
            $members = Get-QADGroupMember -Identity $group.DN |
                       Select-Object -ExpandProperty SAMAccountName

            if ($members) {
                $result = @{ users = $members }
            } else {
                $result = @{ error = "Raptor404" }
            }
        } else {
            $result = @{ error = "Raptor404" }
        }
    }
    catch {
        $result = @{ error = "Raptor404" }
    }

    # Zatrzymaj stoper i dodaj czas wykonania
    $stopwatch.Stop()
    $result.duration = [math]::Round($stopwatch.Elapsed.TotalSeconds, 3)

    # Zwróć wynik jako JSON
    $result | ConvertTo-Json -Depth 2
}
# === Automatyczne wywołanie, jeśli podano argument ===
if ($MyInvocation.InvocationName -ne '.' -and $args.Count -eq 1) {
    Get-GroupMembers -GroupName $args[0]
}
# Get-GroupMembers "group.name"
# Cudzysłów jest wymagany, jeśli nazwa grupy zawiera spacje