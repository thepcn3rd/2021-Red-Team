    Dim shl  
    Set shl = CreateObject("Wscript.Shell")  
    Call shl.Run("""calc.exe""")  
    Set shl = Nothing  
    WScript.Quit 