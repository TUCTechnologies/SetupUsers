# Migrate a mailbox from on-premise Exchange to Office 365

Import-Module MSOnline

# Fill in variables
$O365Username = ""
$O365Password = ""
$OnPremUsername = ""
$OnPremPassword = ""
$MailboxToMove = ""
$RemoteHostName = ""
$TargetDeliveryDomain = "" + mail.onmicrosoft.com

$O365SecurePassword = $O365Password | ConvertTo-SecureString -AsPlainText -Force
$OnPremSecurePassword = $OnPremPassword | ConvertTo-SecureString -AsPlainText -Force
$O365CREDS = New-Object System.Management.Automation.PSCredential($O365Username,$O365SecurePassword)
$OnPremCREDS = New-Object System.Management.Automation.PSCredential($OnPremUsername,$OnPremSecurePassword)

$SESSION = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $O365CREDS -Authentication Basic -AllowRedirection
Import-PSSession $SESSION
Connect-MsolService -Credential $O365CREDS

New-MoveRequest -Identity $MailboxToMove -Remote -RemoteHostName $RemoteHostName -TargetDeliveryDomain $TargetDeliveryDomain -RemoteCredential $OnPremCREDS -BadItemLimit 100
