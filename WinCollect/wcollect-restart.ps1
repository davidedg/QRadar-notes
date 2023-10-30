##
if ((Get-Service WinCollect).Status -eq 'StopPending') {
 Start-Sleep 5
 Stop-Process -Force -EA SilentlyContinue -Name WinCollect
 Stop-Process -Force -EA SilentlyContinue -Name WinCollectSvc
 Start-Sleep 5
}
Restart-Service -Force -EA SilentlyContinue WinCollect


## oneliner:
powershell.exe -ep bypass "if ((Get-Service WinCollect).Status -eq 'StopPending') { Start-Sleep 5 ;  Stop-Process -Force -EA SilentlyContinue -Name WinCollect ;  Stop-Process -Force -EA SilentlyContinue -Name WinCollectSvc ;  Start-Sleep 5 } ; Restart-Service -Force WinCollect"
