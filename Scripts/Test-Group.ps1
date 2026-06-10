param ( 
    [Parameter(Mandatory=$true)]
    [string]$GroupName
)

# Generate a safe filename for the CSV in the TEMP folder
$safeGroupName = $GroupName -replace '[^a-zA-Z0-9]', ''
$CsvPath = "$env:TEMP\Members_$safeGroupName.csv"

# 1. Find the Group's Distinguished Name (DN)
$groupSearcher = [adsisearcher]"(cn=$GroupName)"
$groupResult = $groupSearcher.FindOne()

if (-not $groupResult) {
    Write-Host "Error: Group '$GroupName' not found in Active Directory." -ForegroundColor Red
    return
}

$groupDN = $groupResult.Properties["distinguishedname"][0]

# 2. Find all members of this group
$userSearcher = [adsisearcher]"(memberOf=$groupDN)"
$userSearcher.PageSize = 1000
$userSearcher.PropertiesToLoad.Add("name") | Out-Null

$results = $userSearcher.FindAll()
$totalCount = $results.Count

# Check if the group has any members
if ($totalCount -eq 0) {
    Write-Host "Group '$GroupName' is empty. No file created." -ForegroundColor Yellow
    return
}

# Print the total count to the console
Write-Host "======================================" -ForegroundColor Cyan
Write-Host " SUCCESS! Found $totalCount users." -ForegroundColor Green
Write-Host " Generating CSV and opening Excel..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# 3. Create a numbered list and export to CSV
$counter = 1
$results | ForEach-Object {
    [PSCustomObject]@{
        "#" = $counter
        "User Name" = $_.Properties['name'][0]
    }
    $counter++
} | Export-Csv -Path $CsvPath -NoTypeInformation -Delimiter ';' -Encoding UTF8

# 4. Automatically open the file in the default application (usually Excel)
Invoke-Item $CsvPath
