# Configuration parameters 
$maxPasswordAgeDays = 90
$daysToExpiry = 7

# 1. Calculate timestamps for LDAP (converted to FileTime)
# Target window: passwords set between 83 and 90 days ago
$now = Get-Date
$upperLimit = $now.AddDays(-($maxPasswordAgeDays - $daysToExpiry)).ToFileTime()
$lowerLimit = $now.AddDays(-$maxPasswordAgeDays).ToFileTime()

# 2. Build the LDAP filter for expiring users
# Filters for: Person + Active + Password set within the 7-day window
$ldapFilter = "(&(objectCategory=person)(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2))(pwdLastSet>=$lowerLimit)(pwdLastSet<=$upperLimit))"

# 3. Configure .NET adsisearcher for the main query
$searcher = [adsisearcher]$ldapFilter
$searcher.PageSize = 1000
$searcher.PropertiesToLoad.AddRange(@("displayname", "mail", "manager", "pwdlastset", "samAccountName", "distinguishedname"))

# 4. Execute search (Directly targeting the required records)
$results = $searcher.FindAll()

# 5. Build the data collection as Objects
$reportData = $results | Where-Object {
    $dn = $_.Properties["distinguishedname"][0]
    $dn -match "OU=(users|External Accounts|External Agents),OU=[^,]+,OU=Countries"
} | ForEach-Object {
    $props = $_.Properties
    
    # Calculate password age
    $setAt = [datetime]::FromFileTime($props["pwdlastset"][0])
    $age = (New-TimeSpan -Start $setAt -End $now).Days
    $expiresIn = $maxPasswordAgeDays - $age
    $expStr = "$expiresIn ($age days)"
    
    # Safely extract properties
    $mgr = if ($props.Contains("manager")) { ($props["manager"][0] -split ',')[0].Replace("CN=", "") } else { "---" }
    $mail = if ($props.Contains("mail")) { $props["mail"][0] } else { "---" }
    $disp = if ($props.Contains("displayname")) { $props["displayname"][0] } else { $props["samaccountname"][0] }
    
    # Create an object instead of a text string
    [PSCustomObject]@{
        DisplayName = $disp
        Login = $props["samaccountname"][0]
        ExpiresIn = $expStr
        Manager = $mgr
        Email = $mail
    }
}

# 6. Form final output
$finalOutput = @{
    count = if ($reportData) { @($reportData).Count } else { 0 }
    users = if ($reportData) { @($reportData) } else { @() }
}

# 7. Convert to JSON and output to stdout
# Output compressed JSON (no Write-Host to avoid breaking Python parsing)
$finalOutput | ConvertTo-Json -Depth 3 -Compress
