# Migrate a mailbox from on-premise Exchange to Office 365

Import-Module MSOnline

$O365Username = ""
$O365Password = ""

$OnPremUsername = ""
$OnPremPassword = ""

$MailboxAliasToMove = ""
$Domain = ""
$UserPrincipalName = $MailboxAliasToMove + "@" + $Domain
$RemoteHostName = ""
$TargetDeliverySubDomain = ""
$TargetDeliveryDomain = $TargetDeliverySubDomain + ".mail.onmicrosoft.com"

$O365SecurePassword = $O365Password | ConvertTo-SecureString -AsPlainText -Force
$OnPremSecurePassword = $OnPremPassword | ConvertTo-SecureString -AsPlainText -Force
$O365CREDS = New-Object System.Management.Automation.PSCredential($O365Username,$O365SecurePassword)
$OnPremCREDS = New-Object System.Management.Automation.PSCredential($OnPremUsername,$OnPremSecurePassword)

$SESSION = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Authentication Basic -AllowRedirection -Credential $O365CREDS
Import-PSSession $SESSION
Connect-MsolService -Credential $O365CREDS

New-MoveRequest -Identity $MailboxAliasToMove -Remote -RemoteHostName $RemoteHostName -TargetDeliveryDomain $TargetDeliveryDomain -RemoteCredential $OnPremCREDS -BadItemLimit 100

Do
{
  Start-Sleep -s 10
  Write-Host "Migration not completed yet.. still waiting..."
  $Status = Get-MoveRequest | Where-Object {$_.Alias -like $MailboxAliasToMove} | Select Status | Select -Expand Status
}
While($Status -ne "Completed")

Write-Host "Migration completed."

Get-MoveRequest | Where-Object {$_.Alias -like $MailboxAliasToMove}

Set-MsolUser -UserPrincipalName $UserPrincipalName -UsageLocation US
Set-MsolUserLicense -UserPrincipalName $UserPrincipalName -AddLicenses ""
