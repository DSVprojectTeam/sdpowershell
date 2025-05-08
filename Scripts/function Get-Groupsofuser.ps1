function Get-Groupsofuser {
    param(
        [Parameter(Position=0)]
        [string]$UploadID
    )

    # Pomiar czasu
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $ErrorActionPreference = "Stop"

        # Pobranie wszystkich grup (bezpośrednich i pośrednich), wypisanie nazw
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

    # Zwrócenie wyniku jako JSON
    $result | ConvertTo-Json -Depth 2
}
# === Automatyczne wywołanie, jeśli podano argument ===
if ($MyInvocation.InvocationName -ne '.' -and $args.Count -eq 1) {
    Get-Groupsofuser -UploadID $args[0]
}
# Zastąp "user.name" nazwą konta użytkownika (pre2000)
# Get-UserGroups user.name