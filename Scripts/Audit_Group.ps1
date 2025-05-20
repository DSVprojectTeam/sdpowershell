function Audit_Group {
    param (
        [Parameter(Mandatory = $true)]
        [string]$GroupName
    )

    try {
        # Get the group
        $group = Get-QADGroup -LdapFilter "(name=$GroupName)"
        if (-not $group) {
            return "Raptor404"
        }

        # Get direct members (users and groups)
        $members = Get-QADGroupMember -Identity $group.DN

        # Process members
        $result = foreach ($member in $members) {
            switch ($member.Type) {
                'User' {
                    $user = Get-QADUser -Identity $member.DN -IncludeAllProperties
                    if ($null -eq $user) { continue }

                    [PSCustomObject]@{
                        ObjectType    = 'User'
                        Name          = $user.Name
                        Login         = $user.SamAccountName
                        Email         = $user.Email
                        Country       = $user.c
                        Title         = $user.Title
                        Company       = $user.Company
                        Department    = $user.Department
                        Manager       = ($user.Manager -split ',')[0] -replace '^CN='
                        Deprovisioned = if ($user.DN -like "*OU=Deprovisioned Objects*") { "yes" } else { "no" }
                    }
                }
                'Group' {
                    [PSCustomObject]@{
                        ObjectType = 'Group'
                        Name       = $member.Name
                        DN         = $member.DN
                        Email      = $member.Email
                    }
                }
                default {
                    [PSCustomObject]@{
                        ObjectType = $member.Type
                        Name       = $member.Name
                        DN         = $member.DN
                        Email      = $member.Email
                    }
                }
            }
        }

        # Save result as JSON
        $jsonPath = ".\$($GroupName)_members.json"
        $result | ConvertTo-Json -Depth 4 | ForEach-Object { $_ -replace '\\u0027', "'" } | Set-Content -Path $jsonPath -Encoding UTF8

        return $result
    }
    catch {
        return "Raptor404"
    }
}


# === Auto-invoke if group name is passed as argument ===
if ($MyInvocation.InvocationName -ne '.' -and $args.Count -eq 1) {
    $result = Audit_Group -GroupName $args[0]
    Write-Host $result
}

function Audit_AllGroupsFromCsv {
    param (
        [Parameter(Mandatory = $true)]
        [string]$CsvPath
    )

    try {
        # Check if file exists
        if (-Not (Test-Path -Path $CsvPath)) {
            return ConvertTo-Json -InputObject @{Error = "Raptor404"; Message = "CSV file not found"}
        }

        # Read group names from CSV
        $groupNames = Get-Content -Path $CsvPath | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

        if ($groupNames.Count -eq 0) {
            return ConvertTo-Json -InputObject @{Error = "Raptor404"; Message = "No valid group names found in CSV"}
        }

        $allResults = @()

        # Process each group
        foreach ($group in $groupNames) {
            Write-Host "Processing group: $group"
            $result = Audit_Group -GroupName $group

            if ($result -eq "Raptor404") {
                $allResults += @{GroupName = $group; Status = "Raptor404"; Message = "Error processing the group"}
            }
            else {
                $allResults += @{GroupName = $group; Status = "Success"; Data = $result}
            }
        }

        # Convert all results to JSON
        $allResults | ConvertTo-Json -Depth 4
    }
    catch {
        return ConvertTo-Json -InputObject @{Error = "Raptor404"; Message = "Unexpected error occurred"}
    }
}
# === Auto-invoke if script called with a CSV path ===
if ($MyInvocation.InvocationName -ne '.' -and $args.Count -eq 1) {
    $csvArg = $args[0]
    $auditResult = Audit_AllGroupsFromCsv -CsvPath $csvArg
    Write-Host $auditResult
}
