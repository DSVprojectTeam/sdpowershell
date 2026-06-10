function Get-GroupMembers {
    param(
        [Parameter(Position=0)]
        [string]$GroupName # Dokladny cn ldapname grupy 
    )

    # Pomiar czasu
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $OutputEncoding = [System.Text.Encoding]::UTF8 
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8


    try {
        $ErrorActionPreference = "Stop"

        # Spróbuj pobrać grupę po DN
        $group = Get-QADGroup -Identity $GroupName -ErrorAction SilentlyContinue 

        # Jeśli nie znaleziono, spróbuj po CN
        if (-not $group) {
            $group = Get-QADGroup -LdapFilter "(cn=$GroupName)" -ErrorAction SilentlyContinue 
        }

         if ($group) {
            
            # Find all objects that are members of this group (using its DN)
            $searcher = [adsisearcher]"(&(memberOf=$($group.DN))(objectCategory=person)(objectClass=user))"
            # PageSize is critical! It allows fetching more than default AD limits (1000) by paging the results
            $searcher.PageSize = 1000 
            # Specify that we only need the 'name' attribute (improves performance)
            $searcher.PropertiesToLoad.Add("samaccountname") | Out-Null
            $searcher.PropertiesToLoad.Add("name") | Out-Null
            
            # Execute the search and extract the string value from the 'name' property
            $members = $searcher.FindAll() | ForEach-Object { 
              $sam = $_.Properties['samaccountname'][0]
              $disp = $_.Properties['name'][0]
    
              if ($disp) { "$disp ($sam)" } else { $sam }
            }


            if ($members) {
                $countString = "Total users: $(@($members).Count)"
                $result = @{ users = @($countString) + @($members) }
            } else {
                $result = @{ error = @("1Raptor408") }
            }
        } else {
            $result = @{ error = @("2Raptor403") }
        }
    }

    catch {
        $errorMsg = $_.ExceptionMessage 
        $result = @{ error = @("3Raptor402:$errorMsg") }
       
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
