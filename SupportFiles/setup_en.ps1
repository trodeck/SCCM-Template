<<<<<<< HEAD
Function IsAppRunning() {
	param($AppName)
	if(get-process | where {$_.mainWindowTitle} | format-table id, name, mainwindowtitle -AutoSize | Select-String -Pattern $AppName) {
		Return $False;
	} else {
		return $True;
	}
}

add-type -AssemblyName Microsoft.VisualBasic
add-type -AssemblyName System.Windows.Forms

#.\certifio-suite-en.exe /L*V .\log-file.log /quiet FORCE_INSTALLATION=true

$AppName = 'certifio-suite-en'

While (IsAppRunning($AppName) ) {
	start-sleep -Milliseconds 250
}
Write-Host 'Out of Loop'

[Microsoft.VisualBasic.Interaction]::AppActivate("CertifiO Suite Setup")
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")



=======
Function IsAppRunning() {
	param($AppName)
	if(get-process | where {$_.mainWindowTitle} | format-table id, name, mainwindowtitle -AutoSize | Select-String -Pattern $AppName) {
		Return $False;
	} else {
		return $True;
	}
}

add-type -AssemblyName Microsoft.VisualBasic
add-type -AssemblyName System.Windows.Forms

#.\certifio-suite-en.exe /L*V .\log-file.log /quiet FORCE_INSTALLATION=true

$AppName = 'certifio-suite-en'

While (IsAppRunning($AppName) ) {
	start-sleep -Milliseconds 250
}
Write-Host 'Out of Loop'

[Microsoft.VisualBasic.Interaction]::AppActivate("CertifiO Suite Setup")
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")



>>>>>>> 334d15f542a70aeade487f0bb8c175b268202912
