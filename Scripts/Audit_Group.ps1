function Audit_Group {
    param(
        [Parameter(Position=0)]
        [string]$GroupName
    )

    try {
        $ErrorActionPreference = "Stop"

        # Wyszukaj grupę po nazwie (LDAP filter)
        $group = Get-QADGroup -LdapFilter "(name=$GroupName)"

        if ($group) {
            # Pobierz członków grupy z dodatkowymi właściwościami
            $members = Get-QADGroupMember -Identity $group.DN -IncludedProperties mail, c, co, title, company, department, manager, name, DN

            $exportData = foreach ($member in $members) {
                # Pobierz nazwę managera, jeśli istnieje
                $managerName = $null
                if ($member.Manager) {
                    $managerObj = Get-QADUser -Identity $member.Manager -IncludedProperties displayName
                    $managerName = $managerObj.DisplayName
                }

                # Przypisz country (co lub c)
                $country = if ($member.co) { $member.co } elseif ($member.c) { $member.c } else { "" }

                # Sprawdź czy użytkownik jest w OU=Deprovisioned Objects
                $isDeprovisioned = if ($member.DN -like "*OU=Deprovisioned Objects*") { "yes" } else { "no" }

                [PSCustomObject]@{
                    Name          = $member.Name
                    Login         = $member.SamAccountName
                    Email         = $member.Mail
                    Country       = $country
                    Title         = $member.Title
                    Company       = $member.Company
                    Department    = $member.Department
                    Manager       = $managerName
                    Deprovisioned = $isDeprovisioned
                }
            }

            # Zbuduj nazwę pliku CSV
            $safeName = ($GroupName -replace '[^\w\.-]', '_') + ".csv"
            $exportData | Export-Csv -Path $safeName -NoTypeInformation -Encoding UTF8 -Delimiter ';'

            Write-Host "Eksportowano do pliku: $safeName"
        }
        else {
            Write-Host "Raptor404"
        }
    }
    catch {
        Write-Host "Raptor404"
    }
}

# === Automatyczne wywołanie, jeśli podano argument ===
if ($MyInvocation.InvocationName -ne '.' -and $args.Count -eq 1) {
    Audit_Group -GroupName $args[0]
}

function Audit_AllGroupsFromCsv {
    param (
        [Parameter(Mandatory = $true)]
        [string]$CsvPath
    )

    # Sprawdzenie istnienia pliku
    if (-Not (Test-Path -Path $CsvPath)) {
        Write-Host "Plik nie istnieje: $CsvPath"
        return
    }

    # Wczytanie nazw grup z pliku
    $groupNames = Get-Content -Path $CsvPath | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

    if ($groupNames.Count -eq 0) {
        Write-Host "Brak poprawnych nazw grup w pliku CSV."
        return
    }

    # Przetworzenie każdej grupy
    foreach ($group in $groupNames) {
        if ($null -ne $group -and $group -ne "") {
            Write-Host "Przetwarzanie grupy: $group"
            Audit_Group -GroupName $group
        }
    }

    Write-Host "Zakonczono przetwarzanie " $groupNames.Count "grup."
}