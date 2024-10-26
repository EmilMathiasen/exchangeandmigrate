# Exchange Migrate Script

## Overview
The New-MigrationApp function is a PowerShell script designed to automate the creation of a new application and service principal in Microsoft 365 for migration purposes. This script simplifies the process outlined in the MigrationWiz documentation by handling the necessary steps to set up an application with the required permissions.
The Documentation: https://help.bittitan.com/hc/en-us/articles/27481872521115-M365-Mailbox-and-Archive-Migrations-Performing-Migration-using-only-API-permissions#h_01J32YXTKMC07Q7YZD218GRMGX

## Prerequisites
Before using this script, make sure you have the following:

PowerShell environment configured with the required modules.
Appropriate permissions to create applications and service principals in Microsoft 365.
Knowledge of the application name ($AppName) and the username of the impersonation user ($Impersonator).

## Usage

1. Open a PowerShell environment.
2. Copy and paste the content of New-MigrationApp function into the PowerShell console.
3. Call the function New-MigrationApp with the required parameters:
   
´´´powershell
New-MigrationApp -AppName "YourApplicationName" -Impersonator "ImpersonationUserName"
´´´
## Parameters
* AppName: The name of the new application. Mandatory parameter.
* Impersonator: The username of the impersonation user. Mandatory parameter.

## Author

Emil Mathiasen

