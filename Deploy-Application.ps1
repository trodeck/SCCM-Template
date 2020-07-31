﻿<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK 
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet("Install","Uninstall")]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet("Interactive","Silent","NonInteractive")]
	[string]$DeployMode = "Interactive",
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy "ByPass" -Scope "Process" -Force -ErrorAction "Stop" } Catch {}
	
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
    
	## Entrer le nom complet de l'application tel qu'affiché sous SCCM, la date, ainsi que votre nom
    ##-----------------------------------------------------------------------------------------------
    [string]$appName = ""
	[string]$appScriptDate = ""
	[string]$appScriptAuthor = ""
    ##-----------------------------------------------------------------------------------------------
	
	[string]$appVendor = ""
	[string]$appVersion = ""
	[string]$appArch = ""
	[string]$appLang = ""
	[string]$appRevision = "1.0"
	[string]$appScriptVersion = "1.0"
	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ""
	[string]$installTitle = ""
	
	##* Do not modify section below
	#region DoNotModify
	
	## Variables: Exit Code
	[int32]$mainExitCode = 0
	
	## Variables: Script
	[string]$deployAppScriptFriendlyName = "Deploy Application"
	[version]$deployAppScriptVersion = [version]"3.6.8"
	[string]$deployAppScriptDate = "02/06/2016"
	[hashtable]$deployAppScriptParameters = $psBoundParameters
	
	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
	
	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}
	
	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================

	######################################################
	#### Includes helper functions for Cascades SCCM  ####
	######################################################
			
	$incSupport = $dirFiles + "\LIBS\Support.ps1"
	& $incSupport	
	
	$os_lang = ((Get-Culture).Name.SubString(0,2)).ToLower() 

	######################################################
	#### End of helper function for Cascades SCCM     ####
    ######################################################
		
    #$deploymentType ="UnInstall"
	If ($deploymentType -ine "Uninstall") {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = "Pre-Installation"
		
        ## Test si un "reboot pending" est en cours, si oui l'installation ne s'effectue pas et sort en erreur 70000 pour un redemarrage du poste avant installation 
		if(Test-RebootRequired)
		{
			[int32]$mainExitCode = 70000
			Write-Log -Message "Le poste a besoin d'un redémarrage avant de lancer l'installation, ErrorCode : $mainExitCode." -Severity 2 -Source ${CmdletName}
			Show-BalloonTip -BalloonTipIcon 'Warning' -BalloonTipText (Get-ResourceText -ResourceID "REBOOT_REQUIRED")
			Exit-Script -ExitCode $mainExitCode
		}
			
        ############################################
		#### Uninstallation of previous version ####
		############################################

			
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = "Installation"

		Show-BalloonTip -BalloonTipIcon "Info" -BalloonTipText (Get-ResourceText -ResourceID "APP_INSTALL_START")

		#Install the base package
        
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = "Post-Installation"
		
		## <Perform Post-Installation tasks here>

         # Copy files to the Desktop for all users
        If( Test-Path -Path "$dirFiles\Desktop" ) { 
            $Path = "$envCommonDesktop"
            Copy-File -Path "$dirFiles\Desktop\*.*" -Destination $Path -ContinueOnError $False -Recurse
        }

        # Copy files to the StartMenu for all users
        If( Test-Path -Path "$dirFiles\StartMenu" ) {
            $Path = "$envCommonStartMenuPrograms"
            Set-Folder -Path $Path
            Copy-File -Path "$dirFiles\StartMenu\*.*" -Destination $Path  -ContinueOnError $False -Recurse
        }

		RegisterSCCMInstall

		If( Test-RebootRequired ) {
			Show-BalloonTip -BalloonTipIcon "Warning" -BalloonTipText (Get-ResourceText -ResourceID "REBOOT_REQUIRED")
		}
	}
	ElseIf ($deploymentType -ieq "Uninstall")
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = "Pre-Uninstallation"
		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = "Uninstallation"
		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = "Post-Uninstallation"
		
		## <Perform Post-Uninstallation tasks here>
		RegisterSCCMUninstall
		
		If( Test-RebootRequired ) {
			Show-BalloonTip -BalloonTipIcon "Warning" -BalloonTipText (Get-ResourceText -ResourceID "REBOOT_REQUIRED")
		}
	}
	
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================
	
	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon "Stop"
	Exit-Script -ExitCode $mainExitCode
}