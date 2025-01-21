function New-MigrationApp {
      #       Todo; Check if each of these scopes are actually necessary for this project.
      #       Changed to applying full acces
      #       Author: emilthisen@gmail.com
      #       Version: 2.0.3
      param (
            [Parameter(Mandatory = $true, HelpMessage = "Insert Name of the New Application.")]
            [string]$AppName,
            [Parameter(Mandatory = $true, HelpMessage = "Insert username of the Impersonation/Global Admin User.")]
            [string]$Impersonator
      )
      write-host "Disconnecting from leftover sessions Graph Sessions" 
      
      Disconnect-MgGraph -ErrorAction SilentlyContinue

      Write-host "Connecting in Exchange Online"

      Connect-ExchangeOnline
      Write-host "Checking for OrganizationCustomization - Enables it, if possible"
      
      # OrganizationCustomization is necessary in order to apply Impersonation.
      $orgconf = Get-OrganizationConfig
      if ($orgconf.IsDehydrated) {
            Enable-OrganizationCustomization
            Write-Host "Microsoft services are taking longer than expected. Please try again later"
            return 
      }

      Write-host "Setting MaxReceiveSize to 153600000 and MaxSendSize  to 153600000"
      Get-Mailbox -ResultSize Unlimited | Set-Mailbox -MaxReceiveSize 153600000 -MaxSendSize 153600000
      ##Dansk sprog sættes her? ja nej:
      Write-Host "Language for the mailbox?"
      $confirmation = Read-Host "Do you want to update All mailboxes regional configuration to Danish/Dansk? (Yes/No)"

      if ($confirmation -eq "Yes") {
            # Execute the command if the answer is Yes
            Get-Mailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited | Set-MailboxRegionalConfiguration -Language da-dk -DateFormat "dd-MM-yyyy" -TimeFormat H:mm -LocalizeDefaultFolderName -TimeZone "Romance Standard Time"
            Write-Host "Mailboxes updated"
        } else {
            # Carry on if the answer is No
            Write-Host "No changes made. Carrying on..."
        }
       
      Write-Host "Still thinking... Almost there..."
      Start-Sleep -Seconds 4


      write-host  "Done - Lets do the application"
      Start-Sleep -Seconds 4
      Write-Host "Connecting to MgGraph"
      Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All", "Application.ReadWrite.All", "Directory.AccessAsUser.All", "Directory.ReadWrite.All", "RoleManagement.ReadWrite.Directory", "AppRoleAssignment.ReadWrite.All", "Organization.ReadWrite.All"
    

      # Creating the application per MigrationWiz documentation: https://help.bittitan.com/hc/en-us/articles/360034124813-Authentication-Methods-for-Microsoft-365-All-Products-Migrations#h_01HHZ272SHGCV7MN61R1CJ1TC5
      $app = New-MgApplication -DisplayName $AppName -SignInAudience "AzureADMultipleOrgs" -PublicClient @{ RedirectUris = "urn:ietf:wg:oauth:2.0:oob" } -IsFallbackPublicClient 

      # This creates service principal for the app. The Object ID from this object is necessary when granting permissions to the app.
      $clientsp = New-MgServicePrincipal -AppId $app.AppId
      # Get ResourceID for Office 365 Exchange Online - This ID is unique on each tenant. Used to add Permission scopes to the app.
      $eoresource = Get-MgServicePrincipal -Filter "appId eq '00000002-0000-0ff1-ce00-000000000000'"
      
      New-MgOauth2PermissionGrant -BodyParameter @{
            clientId    = $clientsp.Id
            consentType = "AllPrincipals"
            resourceId  = $eoresource.Id 
            scope       = "EWS.AccessAsUser.All"
      }
      
      #New-MgServicePrincipalAppRoleAssignment 
      Write-Host "Waiting for creating ServicePrincipal AppRoleAssignment"
      Start-Sleep -Seconds 10
      
      #Step 1: Get the Exchange Online Service Principal
      $exchangeSP = Get-MgServicePrincipal -Filter "appId eq '00000002-0000-0ff1-ce00-000000000000'"

      #Step 2: Find the full_access_as_app App Role ID
      $exchangeAppRoles = $exchangeSP.AppRoles
      $fullAccessRole = $exchangeAppRoles | Where-Object {$_.Value -eq "full_access_as_app"}

      $fullAccessRoleId = $fullAccessRole.Id
      $fullAccessRoleId
      
      #Step 3: Get the Target Application's Service Principal
      $findmgapp = Get-MgApplication -filter "displayName eq '$appname'"
      $findmgappid = $findmgapp.AppId

      $targetAppId = "$findmgappid"
      $targetAppSP = Get-MgServicePrincipal -Filter "appId eq '$targetAppId'"

      New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $targetAppSP.Id `
      -PrincipalId $targetAppSP.Id `
      -ResourceId $exchangeSP.Id `
      -AppRoleId $fullAccessRoleId



      # Using MGRAPH / 
      ## Documentation: https://help.bittitan.com/hc/en-us/articles/27481872521115-M365-Mailbox-and-Archive-Migrations-Performing-Migration-using-only-API-permissions#h_01J32YXTKMC07Q7YZD218GRMGX
      # Setting full_ascces_as_app
   
      
      ## Seting a client secret on application
      ## Documentation: https://help.bittitan.com/hc/en-us/articles/27481872521115-M365-Mailbox-and-Archive-Migrations-Performing-Migration-using-only-API-permissions#h_01J32YXTKMC07Q7YZD218GRMGX
      Write-host "Setting a client Secret"
      Start-Sleep -Seconds 5
      $appc = Get-MgApplication -Filter "displayName eq '$AppName'"
      $appidsecret = $appc.Id
      $passwordCredential = Add-MgApplicationPassword -ApplicationId $appidsecret -PasswordCredential @{displayName="NewClientSecret"; endDateTime=(Get-Date).AddYears(1)}
      $clientSecret = $passwordCredential.SecretText
      Write-Output "Client Secret: $clientSecret"

      return @{
            AppClientID = $app.AppId
            TenantID    = $((Get-MgOrganization).Id)
      }

      Write-Host "Remember to write down the client secret."
      Write-host "Disconnecting from Mgraph-Module"
}

## Loggin
Write-host "Starting the log"

$logFileName = Read-Host "Enter the name for the log file (Ex. the migration Project name)"
$logFilePath = Join-Path -Path "C:\logs\" -ChildPath "$logFileName.txt"
Start-Transcript -Path $logFilePath

New-MigrationApp
write-host "Stop transcript"
write-host "The logfile will be located in c:\logs\"
Stop-Transcript

Disconnect-MgGraph
Disconnect-ExchangeOnline
