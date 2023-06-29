set wshShell = WScript.CreateObject ("WScript.Shell")
wshShell.CurrentDirectory = WScript.Arguments.Item(0)
wshShell.Run """C:\Program Files\Alacritty\alacritty.exe""", 0, False