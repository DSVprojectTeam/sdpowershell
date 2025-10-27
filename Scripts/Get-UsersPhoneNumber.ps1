param(
    [
        Parameter(Mandatory=$true)]
            [ValidatePattern("^[a-zA-Z0-9_.-]+$")]
            [string]$SAMAccountName,
        
            [Parameter(Mandatory=$true)]
            [string]$ADUsername,
        
            [Parameter(Mandatory=$true)]
            [string]$ADPassword
        
)

$SecurePassword = ConvertTo-SecureString $ADPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($ADUsername, $SecurePassword)

$result = @{}

try {

    $user = Get-QADUser -Identity $SAMAccountName -Credential $Credential -Properties Name, SamAccountName, TelephoneNumber, Mobile, OtherMobile

    if ($user) {
        $result = @{
            Name           = $user.Name
            sAMAccountName = $user.SamAccountName
            Telephone      = $user.TelephoneNumber
            Mobile         = $user.Mobile
            OtherMobile    = $user.OtherMobile
        }
    } else {
        $result.error = "UserNotFound"
    }
}
catch {
    $result.error = "LookupError"
    $result.details = $_.Exception.Message
}

return $result | ConvertTo-Json -Depth 3
