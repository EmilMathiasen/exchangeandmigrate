function New-MigrationApp {
    # Todo; Check if each of these scopes are actually necessary for this project.
    #       Consider using Microsoft Graph to set ApplicationImpersonation role assignment instead. So that the user does not need to logon twice.
    #       Author: emil.mathiasen@team.blue
    #       Version: 1.0.1
    param (
          [Parameter(Mandatory = $true, HelpMessage = "Insert Name of the New Application.")]
          [string]$AppName,
          [Parameter(Mandatory = $true, HelpMessage = "Insert username of the Impersonation User.")]
          [string]$Impersonator
    )
    Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All", "Application.ReadWrite.All", "Directory.AccessAsUser.All", "Directory.ReadWrite.All"
    Connect-ExchangeOnline

    # OrganizationCustomization is necessary in order to apply Impersonation.
    $orgconf = Get-OrganizationConfig
    if ($orgconf.IsDehydrated) {
          Enable-OrganizationCustomization
          Write-Host "Microsoft services are taking longer than expected. Please try again later"
          return 
    }

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

    New-ManagementRoleAssignment -Role ApplicationImpersonation -User $Impersonator
    Get-Mailbox -ResultSize Unlimited | Set-Mailbox -MaxReceiveSize 153600000 -MaxSendSize 153600000

    
    return @{
          TenantID    = $((Get-MgOrganization).Id)
          AppClientID = $app.AppId
    }
}
New-MigrationApp
