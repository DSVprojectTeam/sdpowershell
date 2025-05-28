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
                    $user = Get-QADUser -Identity $member.DN -SizeLimit 0 -IncludeAllProperties
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
    $result | ConvertTo-Json -Depth 4

}
