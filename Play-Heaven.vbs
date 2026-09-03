Option Explicit

Dim shell, scriptPath
Set shell = CreateObject("WScript.Shell")
scriptPath = Replace(WScript.ScriptFullName, "Play-Heaven.vbs", "Play-Heaven.ps1")
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptPath & """", 0, False