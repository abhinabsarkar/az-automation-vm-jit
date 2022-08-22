Dim hostname
hostname = "<Public IP Address of VM>"
' Create an instance of Windows shell (cli) using VB script processor WScript.exe (Windows)
Set WshShell = WScript.CreateObject("WScript.Shell")
Ping = WshShell.Run("ping -n 1 " & hostname, 0, True)
Select Case Ping
Case 0 
   'WScript.Echo "The machine '" & hostname & "' is Online"

   ' Open RDP if VM is running
   WshShell.Run "mstsc.exe vm-abhi-dev.rdp"
Case 1 
   ' WScript.Echo "The machine '" & hostname & "' is Offline"

   ' Start VM if it is stopped. Open an instance of cmd prompt. 
   ' Initiate wsl & run the bash script "StartMyVM.sh"
   ' The bash script have to be in the same location as the vbscript
   WshShell.Run "cmd.exe /k wsl ./StartMyVM.sh"
End Select