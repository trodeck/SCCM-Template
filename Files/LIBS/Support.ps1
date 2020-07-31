Function Get-PropOrNull {
    [CmdletBinding()]
    param($thing, [string]$prop)
    Try {
        $thing.$prop
    } Catch {
    }
}

Function global:Get-ResourceText { 
    Param (
        [Parameter(Mandatory=$true)] 
        [String] $ResourceID
    )

    $lstResourceText = @{}
    Get-Content ($dirFiles + '\RES\ResourceText') | ForEach-Object { $data = $_.Split("="); $lstResourceText.Add( $data[0], $data[1] ) }

    $ResourceID = ($ResourceID  + '_' + (Get-Culture).Name.SubString(0,2)).ToUpper() 
    $rtnVal = $lstResourceText[($ResourceID)]
    
    If ($rtnVal) {
        $rtnVal = $rtnVal.Replace('#appName#', $appName)
        $rtnVal = $rtnVal.Replace('#appVendor#', $appVendor)
        $rtnVal = $rtnVal.Replace('#appVersion#', $appName)
        Return $rtnVal.toString()
    } else {
        Return ""
    }
}

Function global:Set-EnvironmentVariable
{
  param
  (
    [Parameter(Mandatory=$true)]
    [String]
    $Name,
    
    [Parameter(Mandatory=$true)]
    [String]
    $Value,
    
    [Parameter(Mandatory=$true)]
    [EnvironmentVariableTarget]
    $Target
  )
  [System.Environment]::SetEnvironmentVariable($Name, $Value, $Target)
}

Function global:RegisterInstall() 
{
    $Path = "HKLM:\SOFTWARE\Policies\SCCM\$appVendor\$appName"
    If(Test-Path -Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
    }

    $Path = $Path + "\$appVersion\$appRevision"
    $Path = $Path.Split('\')
    $buildPath = ''
    Try {
        foreach( $itm in $Path ) {
            $buildPath = $buildPath + $itm
            If((Test-Path -Path $buildPath) -eq $False)
            {
                New-Item -Path $buildPath
            }
            $buildPath = $buildPath + '\'
        }          
    } catch { }
}

Function global:RegisterUninstall() 
{
    $Path = "HKLM:\SOFTWARE\Policies\SCCM\$appVendor\$appName"  
    Try {
        If((Test-Path -Path $Path) -eq $True) {
            Remove-Item -Path $Path -Recurse -Force
        }
    } Catch { }
}
Function Get-PropOrNull {
    [CmdletBinding()]
    param($thing, [string]$prop)
    Try {
        $thing.$prop
    } Catch {
    }
}

Function global:Get-ResourceText { 
    Param (
        [Parameter(Mandatory=$true)] 
        [String] $ResourceID
    )

    $lstResourceText = @{}
    Get-Content ($dirFiles + '\RES\ResourceText') | ForEach-Object { $data = $_.Split("="); $lstResourceText.Add( $data[0], $data[1] ) }

    $ResourceID = ($ResourceID  + '_' + (Get-Culture).Name.SubString(0,2)).ToUpper() 
    $rtnVal = $lstResourceText[($ResourceID)]
    
    If ($rtnVal) {
        $rtnVal = $rtnVal.Replace('#appName#', $appName)
        $rtnVal = $rtnVal.Replace('#appVendor#', $appVendor)
        $rtnVal = $rtnVal.Replace('#appVersion#', $appName)
        Return $rtnVal.toString()
    } else {
        Return ""
    }
}

Function global:Set-EnvironmentVariable
{
  param
  (
    [Parameter(Mandatory=$true)]
    [String]
    $Name,
    
    [Parameter(Mandatory=$true)]
    [String]
    $Value,
    
    [Parameter(Mandatory=$true)]
    [EnvironmentVariableTarget]
    $Target
  )
  [System.Environment]::SetEnvironmentVariable($Name, $Value, $Target)
}

Function global:RegisterSCCMInstall() 
{
    $Path = "HKLM:\SOFTWARE\Policies\SCCM\$appVendor\$appName\$appVersion\$appRevision"
    Set-RegistryKeyValue -Path $Path -Name "LastUpdate" -Value (Get-Date -Format G).toString() -PropertyType "String"
    Set-RegistryKeyValue -Path $Path -Name "Status" -Value "Installed" -PropertyType "String"
}

Function global:RegisterSCCMUninstall() 
{
    $Path = "HKLM:\SOFTWARE\Policies\SCCM\$appVendor\$appName"  
    Try {
        If((Test-Path -Path $Path) -eq $True) {
            Remove-Item -Path $Path -Recurse -Force
        }
    } Catch { }
}



# Registry Functions

Function Global:Test-RegistryKeyValue
{
    <#
    .SYNOPSIS
    Tests if a registry value exists.

    .DESCRIPTION
    The usual ways for checking if a registry value exists don't handle when a value simply has an empty or null value.  This function actually checks if a key has a value with a given name.

    .EXAMPLE
    Test-RegistryKeyValue -Path 'hklm:\Software\Carbon\Test' -Name 'Title'

    Returns `True` if `hklm:\Software\Carbon\Test` contains a value named 'Title'.  `False` otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key where the value should be set.  Will be created if it doesn't exist.
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the value being set.
        $Name
    )

    If( -not (Test-Path -Path $Path -PathType Container) ) {
        return $False
    }

    Return ((Get-ItemProperty $Path).PSObject.Properties.Name) -contains $Name

}

Function Global:Set-RegistryKeyValue
{
    <#
    .SYNOPSIS
    Tests if a registry value exists.

    .DESCRIPTION
    The usual ways for checking if a registry value exists don't handle when a value simply has an empty or null value.  This function actually checks if a key has a value with a given name.

    .EXAMPLE
    Test-RegistryKeyValue -Path 'hklm:\Software\Carbon\Test' -Name 'Title'

    Returns `True` if `hklm:\Software\Carbon\Test` contains a value named 'Title'.  `False` otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key where the value should be set.  Will be created if it doesn't exist.
        $Path,
  
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        
        # The Value to be set
        [Parameter(Mandatory=$true)]
        [string]
        $Value,

        # The Value to be set
        [Parameter(Mandatory=$true)]
        [string]
        $PropertyType
    )
        
    $TmpPath = $Path.Split('\')
    $BuildPath = ""

    ForEach( $itm in $TmpPath ) {
        $BuildPath = $BuildPath + $itm
        If((Test-Path -Path $BuildPath) -eq $False)
        {
            New-Item -Path $BuildPath
        }
        $BuildPath = $BuildPath + "\"
    }

    If(Test-RegistryKeyValue -Path $Path -Name $Name) {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value 
    } else {
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType
    }
}

Function Global:Get-RegistryKeyValue
{
    <#
    .SYNOPSIS
    Tests if a registry value exists.

    .DESCRIPTION
    The usual ways for checking if a registry value exists don't handle when a value simply has an empty or null value.  This function actually checks if a key has a value with a given name.

    .EXAMPLE
    Test-RegistryKeyValue -Path 'hklm:\Software\Carbon\Test' -Name 'Title'

    Returns `True` if `hklm:\Software\Carbon\Test` contains a value named 'Title'.  `False` otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key where the value should be set.  Will be created if it doesn't exist.
        $Path,
  
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    If( Test-RegistryKeyValue -Path $Path -Name $Name ) {
        Return (Get-ItemProperty -Path $Path -Name $Name).$Name
    }
}

Function Global:Kill-ProcessByName
{
    [CmdletBinding()]
    param
    (  
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )
    If( (Get-Process | Select ProcessName | Select-String -Pattern "$Name").Length -gt 0 ) {
        Stop-Process -Name "$Name" -Force
    }
    If( (Get-Process | Select ProcessName | Select-String -Pattern "$Name").Length -eq 0 ) {
        Return $True
    } Else {
        Return $False
    }
}

Function Global:Remove-Folder
{   
    [CmdletBinding()]
    param
    (  
        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )
    If( (Test-Path -Path $Path) ) {
        Remove-Item -Path $Path -Force -Recurse -ErrorAction SilentlyContinue 
        If( (Test-Path -Path $Path) ) {
            $Dirs = ((Get-ChildItem -Path $Path | Where-Object {$_.Attributes -match'Directory'}).Name)
            ForEach( $Dir In $Dirs ) {
                Remove-Folder -Path $Path
            }
        }
    } 
    If( (Test-Path -Path $Path) ) {
        Return $False
    } Else {
        Return $True 
    }
}

Function Global:Set-Folder
{   
    [CmdletBinding()]
    param
    (  
        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )

    $Parts = $Path.Split("\")
    $Path = ""
    ForEach( $Part In $Parts ) {
        $Path = $Path + $Part
        If( (Test-Path -Path $Path) -eq $False ) {
            New-Item -Path $Path -ItemType Directory 
        }
        $Path = $Path +"\"
    }
     
    If( (Test-Path -Path $Path) ) {
        Return $True
    } Else {
        Return $False 
    }
}