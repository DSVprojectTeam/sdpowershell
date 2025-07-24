function Get-GroupMembers {
    param(
        [Parameter(Position=0)]
        [string]$GroupName # Dokladny cn ldapname grupy 
    )

    # Pomiar czasu
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $ErrorActionPreference = "Stop"

        # Spróbuj pobrać grupę po DN
        $group = Get-QADGroup -Identity $GroupName -ErrorAction SilentlyContinue 

        # Jeśli nie znaleziono, spróbuj po CN
        if (-not $group) {
            $group = Get-QADGroup -LdapFilter "(cn=$GroupName)" -ErrorAction SilentlyContinue 
        }

        if ($group) {
            $members = Get-QADGroupMember -SizeLimit 0 -Identity $group.DN | Select-object -ExpandProperty Name

            if ($members) {
                $result = @{ users = $members }
            } else {
                $result = @{ error = "1Raptor404" }
            }
        } else {
            $result = @{ error = "2Raptor404" }
        }
    }
    catch {
        $result = @{ error = "3Raptor404" }
    }

    # Zatrzymaj stoper i dodaj czas wykonania
    $stopwatch.Stop()
    $result.duration = [math]::Round($stopwatch.Elapsed.TotalSeconds, 3)

    # Zwroc wynik jako JSON
    $result | ConvertTo-Json -Depth 2
}
# === Automatyczne wywolanie, jesli podano argument ===
if ($MyInvocation.InvocationName -ne '.' -and $args.Count -eq 1) {
    Get-GroupMembers -GroupName $args[0]
}
# Get-GroupMembers "group.name"
# Cudzyslow jest wymagany, jesli nazwa grupy zawiera spacje
