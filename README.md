# Exchange Migrate Script

## Overview
The New-MigrationApp function is a PowerShell script designed to automate the creation of a new application and service principal in Microsoft 365 for migration purposes. This script simplifies the process outlined in the MigrationWiz documentation by handling the necessary steps to set up an application with the required permissions.
The Documentation: https://help.bittitan.com/hc/en-us/articles/360034124813-Authentication-Methods-for-Microsoft-365-All-Products-Migrations#h_01H9J5G42WAQWTBGHFKC3JRQC9

## Prerequisites
Before using this script, make sure you have the following:

PowerShell environment configured with the required modules. Powershell 7, with The Exchange Online Module and Mgraph Module
Appropriate permissions to create applications and service principals in Microsoft 365.
Knowledge of the application name ($AppName) and the username of the impersonation user ($Impersonator).


## Usage

1. Save the file, to a folder
2. Open the powershell eviroment and navigate the folder in which you saved the file
3. Start the script by running  ".\migrate3.ps1"
   
´´´powershell
New-MigrationApp -AppName "YourApplicationName" -Impersonator "ImpersonationUserName"
´´´
## Parameters
* AppName: The name of the new application. Mandatory parameter.
* Impersonator: The username of the impersonation/Global Admin user. Mandatory parameter.
* Define the name of the logfile. I recommend the Project name/domain name

## Author

Emil Mathiasen

