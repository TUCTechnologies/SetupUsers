# Sets up a new user
# -Create user in Active Directory
# -Create on-premise Exchange mailbox
# -Migrate a mailbox from on-premise Exchange to Office 365

Import-Module ActiveDirectory
Import-Module MSOnline

$Users = Import-Csv -Path $args[0]

$O365Username = ""
$O365Password = ""

$OnPremUsername = ""
$OnPremPassword = ""

$Domain = ""
$RemoteHostName = ""
$MailboxDatabase = ""
$TargetDeliverySubDomain = ""
$TargetDeliveryDomain = $TargetDeliverySubDomain + ".mail.onmicrosoft.com"

$O365SecurePassword = $O365Password | ConvertTo-SecureString -AsPlainText -Force
$OnPremSecurePassword = $OnPremPassword | ConvertTo-SecureString -AsPlainText -Force
$O365CREDS = New-Object System.Management.Automation.PSCredential($O365Username,$O365SecurePassword)
$OnPremCREDS = New-Object System.Management.Automation.PSCredential($OnPremUsername,$OnPremSecurePassword)

$SESSION = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Authentication Basic -AllowRedirection -Credential $O365CREDS
Import-PSSession $SESSION
Connect-MsolService -Credential $O365CREDS

ForEach($User in $Users) {
  $Username = $User.Username
  $DisplayName = $User.DisplayName
  $UserPrincipalName = $User.UserPrincipalName
  $GivenName = $User.GivenName
  $Surname = $User.Surname
  $Department = $User.Department
  $Title = $User.Title
  $Company = $User.Company
  $Path = $User.Path
  $Password = $User.Password
  $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
  $ChangePasswordAtLogon = $True
  $PasswordNeverExpires = $False

  New-ADUser -Name $DisplayName -UserPrincipalName $UserPrincipalName -SamAccountName $Username -GivenName $GivenName -DisplayName `
    $DisplayName -SurName $Surname -Title $Title -Company $Company -Path $Path -AccountPassword $SecurePassword `
  	-Enabled $True -PasswordNeverExpires $PasswordNeverExpires -ChangePasswordAtLogon $ChangePasswordAtLogon

  Enable-Mailbox $UserPrincipalName -Database $MailboxDatabase

  New-MoveRequest -Identity $Username -Remote -RemoteHostName $RemoteHostName -TargetDeliveryDomain $TargetDeliveryDomain -RemoteCredential $OnPremCREDS -BadItemLimit 100

  Do
  {
    Start-Sleep -s 30
    Write-Host "Migration not completed yet.. still waiting..."
    $Status = Get-MoveRequest | Where-Object {$_.Alias -like $MailboxAliasToMove} | Select Status | Select -Expand Status
  }
  While($Status -ne "Completed")
  Write-Host "Migration completed for $GivenName $Surname"

  Set-MsolUser -UserPrincipalName $UserPrincipalName -UsageLocation US
  Set-MsolUserLicense -UserPrincipalName $UserPrincipalName -AddLicenses ""
}

Write-Host "Users have been created."
