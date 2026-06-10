param( 
    [Parameter(Mandatory=$true)]
    [string]$SAMAccountName
)

$result = @{}

try {
    # Create an LDAP filter to find the specific user
    $searcher = [adsisearcher]"(&(objectCategory=person)(objectClass=user)(sAMAccountName=$SAMAccountName))"
    
    # Specify which attributes to load to avoid pulling the entire object (improves performance)
    $searcher.PropertiesToLoad.AddRange(@('name', 'samaccountname', 'telephonenumber', 'mobile', 'othermobile'))
    
    # Execute the search
    $user = $searcher.FindOne()

    if ($user) {
        $result = @{
            Name = $user.Properties['name'][0]
            sAMAccountName = $user.Properties['samaccountname'][0]
            Telephone = $user.Properties['telephonenumber'][0]
            Mobile = $user.Properties['mobile'][0]
            OtherMobile = $user.Properties['othermobile'][0]
        }
    } else {
        $result.error = "UserNotFound"
    }
} catch {
    $result.error = "LookupError"
    $result.details = $_.Exception.Message
}

# Output the result as JSON
$jsonOutput = $result | ConvertTo-Json -Depth 3

# --- DEBUG LOG ---
# Saving to scripts folder
#$logFilePath = Join-Path -Path $PSScriptRoot -ChildPath "debug_output.json"
#$jsonOutput | Out-File -FilePath $logFilePath -Encoding UTF8

# Return JSON to python
return $jsonOutput
