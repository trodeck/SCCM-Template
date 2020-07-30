<#
.SYNOPSIS
	This script is a template that allows you to extend the toolkit with your own custom functions.
.DESCRIPTION
	The script is automatically dot-sourced by the AppDeployToolkitMain.ps1 script.
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
)

##*===============================================
##* VARIABLE DECLARATION
##*===============================================

# Variables: Script
[string]$appDeployToolkitExtName = "PSAppDeployToolkitExt"
[string]$appDeployExtScriptFriendlyName = "App Deploy Toolkit Extensions"
[version]$appDeployExtScriptVersion = [version]"1.5.0"
[string]$appDeployExtScriptDate = "06/11/2015"
[hashtable]$appDeployExtScriptParameters = $PSBoundParameters

##*===============================================
##* FUNCTION LISTINGS
##*===============================================

# Fonction qui test au debut de l'installation si un "reboot pending" est en cours
Function Test-RebootRequired 
{
    $result = @{
        CBSRebootPending =$false
        WindowsUpdateRebootRequired = $false
        FileRenamePending = $false
        SCCMRebootPending = $false
    }

    #Check CBS Registry
    $key = Get-ChildItem "HKLM:Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
    if ($key -ne $null) 
    {
        $result.CBSRebootPending = $true
    }
   
    #Check Windows Update
    $key = Get-Item "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue
    if($key -ne $null) 
    {
        $result.WindowsUpdateRebootRequired = $true
    }

    #Check PendingFileRenameOperations
    #$prop = Get-ItemProperty "HKLM:SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue
    #if($prop -ne $null) 
    #{
        #PendingFileRenameOperations is not *must* to reboot?
        #$result.FileRenamePending = $true
    #}
    
    #Check SCCM Client <http://gallery.technet.microsoft.com/scriptcenter/Get-PendingReboot-Query-bdb79542/view/Discussions#content>
    try 
    { 
        $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
        $status = $util.DetermineIfRebootPending()
        if(($status -ne $null) -and $status.RebootPending){
            $result.SCCMRebootPending = $true
        }
    }catch{}

    #Return Reboot required
    return $result.ContainsValue($true)
}

# Fonction qui permet de mettre un mode compatibilité sur un .exe
Function Set-ApplicationCompatibility {
<#
 	.SYNOPSIS
        Set-ApplicationCompatibility is an advanced function which can be used to set application's compatibility settings on all users.
    .PARAMETER  ApplicationLocation
		Specifies location of appliaction
    .PARAMETER  CompatibilityModes
		Specifies compatibility Modes
    .PARAMETER  DisplaySettings
		Specifies display settings
#>
    [CmdletBinding()]
    Param (
        [Parameter()]
        [String[]]$ApplicationLocation,

        [Parameter()]
        [ValidateSet("Windows95","Windows98","WindowsXPSP2","WindowsXPSP3","Windows7","Windows8")]
        [String]$CompatibilityModes,

        [Parameter()]
        [ValidateSet("640*480","256Colors","HighDPI")]
        [String[]]$DisplaySettings	
    )
     
    Begin {
        ## Get the name of this function and write header
        [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }
    Process {
        Try {
			$CompatRules = @{"Windows95" = "WIN95"; "Windows98" = "WIN98"; "WindowsXPSP2" = "WINXPSP2"; "WindowsXPSP3" = "WINXPSP3"; "Windows7"= "WIN7RTM"; "Windows8"= "WIN8RTM"}
			$DisplayRules = @{"640*480" = "640X480"; "256Colors"="256COLOR";"HighDPI"="HIGHDPIAWARE"}

			#Define a variable named $Rules
			$Rules = "~ "

			#Check if CompatibilityModes parameter is used by users.
			If($CompatibilityModes)
			{
				If($CompatRules.ContainsKey($CompatibilityModes))
				{
					$Rules += $CompatRules.$CompatibilityModes+" "
				}
			}

			#Check if DisplaySetting parameter is used by users.
			If($DisplaySettings)
			{
				Foreach($DisplaySetting in $DisplaySettings)
				{
					If($DisplayRules.ContainsKey($DisplaySetting))
					{
						$Rules += $DisplayRules.$DisplaySetting+" "
					}
				}
			}
			$RegPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\"
			If(Test-Path "$RegPath\Layers")
			{
				Set-ItemProperty -Path "$RegPath\Layers" -Name "$ApplicationLocation" -Value "$Rules" -ErrorAction Stop
				Write-Log -Message "Compatibility mode pour : $ApplicationLocation -> OK" -Source $appDeployToolkitExtName
			}
			Else
			{
				New-Item -Path $RegPath -Name "Layers"
				Set-ItemProperty -Path "$RegPath\Layers" -Name "$ApplicationLocation" -Value "$Rules" -ErrorAction Stop
				Write-Log -Message "Compatibility mode pour : $ApplicationLocation -> OK" -Source $appDeployToolkitExtName
			}
			
        }
        Catch {
            Write-Log -Message "-> ERREUR: $_" -Severity 3 -Source $appDeployToolkitExtName
        }
    }
}

# Fonction qui permet de mettre un mode compatibilité sur un .exe
Function Remove-ApplicationCompatibility {
<#
 	.SYNOPSIS
        Remove-ApplicationCompatibility is an advanced function which can be used to remove application's compatibility settings.
    .DESCRIPTION
        Remove-ApplicationCompatibility is an advanced function which can be used to remove application's compatibility settings.
    .PARAMETER  ApplicationLocation
		Specifies location of appliaction
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [String[]]$ApplicationLocation
    )
     
    Begin {
        ## Get the name of this function and write header
        [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }
    
	Process {
        Try {
				Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name $ApplicationLocation
				Write-Log -Message "Suppression Compatibility mode pour : $ApplicationLocation -> OK" -Source $appDeployToolkitExtName
			}			
        Catch {
            Write-Log -Message "-> ERREUR: $_" -Severity 3 -Source $appDeployToolkitExtName
        }
			}
}

##*===============================================
##* END FUNCTION LISTINGS
##*===============================================

##*===============================================
##* SCRIPT BODY
##*===============================================

If ($scriptParentPath) {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] dot-source invoked by [$(((Get-Variable -Name MyInvocation).Value).ScriptName)]" -Source $appDeployToolkitExtName
}
Else {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] invoked directly" -Source $appDeployToolkitExtName
}

##*===============================================
##* END SCRIPT BODY
##*===============================================