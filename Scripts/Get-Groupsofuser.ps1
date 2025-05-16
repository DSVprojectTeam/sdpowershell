function Get-Groupsofuser {
    param(
        [Parameter(Position=0)]
        [string]$UploadID
    )

    # Pomiar czasu
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $ErrorActionPreference = "Stop"

        # Pobranie wszystkich grup (bezposrednich i posrednich), wypisanie nazw
        $groups = Get-QADMemberOf -Identity $UploadID -Indirect | Select-Object -ExpandProperty SAMAccountName

        if ($groups) {
            $result = @{ groups = $groups }
        } else {
            $result = @{ error = "Raptor404" }
        }
    }
    catch {
        $result = @{ error = "Raptor404" }
    }

    # Zatrzymanie stopera i dodanie czasu wykonania
    $stopwatch.Stop()
    $result.duration = [math]::Round($stopwatch.Elapsed.TotalSeconds, 3)

    # Zwrocenie wyniku jako JSON
    $result | ConvertTo-Json -Depth 2
}
# === Automatyczne wywolanie, jesli podano argument ===
if ($MyInvocation.InvocationName -ne '.' -and $args.Count -eq 1) {
    Get-Groupsofuser -UploadID $args[0]
}
# Zastap "user.name" nazwa konta uzytkownika (pre2000)
# Get-UserGroups user.name
