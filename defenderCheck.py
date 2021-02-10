#!/usr/bin/python3

# defenderCheck.py
#
# Dependency on WinRM to a Winders box, Linux with pwsh installed
#
# This breaks up a powershell script and runs it against mpCmdRun through a WinRM session.  If it detects a signature
# the file comes back as not being copied and a signature detected.  If the copy was successful and a threat found it will show 
# the output of the threat on the screen.  
#
# In the main function you specify the file you want to analyze, winrm creds (warning plaintext), and the lines at a time you want analyzed.
# Check the output.log to determine which segment was detected and the next with the clean detection.
# 
#


import os
import random
import time


def submitDefender(fA, u, p, b, l):
    initialRandom = random.randint(0,100000)
    secondRandom = random.randint(5,200000)
    # fA - File being Analyzed
    # u - Useraccount being accessed
    # p - Password being passed (plain text)
    # b - Computer name of box
    # l - Lines to Analyze
    # Location where the temporary powershell script is created
    print("\n")
    print("Working with file: " + fA)
    scriptPath = "/home/kali/defenderCheck/sd.ps1"
    # Introduced a delay so the powershell script would terminate, this decreases false positives
    time.sleep(3)
    f = open(scriptPath, "w")
    log = open("output.log", "a")
    f.write("#!/usr/bin/pwsh\n")
    f.write("$pw = Convertto-Securestring -AsPlainText -Force -String \"" + p + "\"\n")
    f.write("$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist \"" + u + "\",$pw" + "\n")
    f.write("$s = New-PSSession -Computername " + b + " -Authentication Negotiate -Credential $cred\n")
    #f.write("Invoke-Command -Session $s { Remove-Item \"c:\\users\\thepcn3rd\\sigtest\\sample.file*\" }\n")
    # Does not allow the copy of the file if a virus signature is detected...
    f.write("Invoke-Expression 'Copy-Item -ToSession $s -Path \"" + str(fA) + "\" -Destination \"C:\\Users\\" + u + "\\sigTest\\sample.file_" + str(initialRandom) + "_" + str(secondRandom) + ".ps1\"' -ErrorVariable errVar\n")
    f.write("$errVar | Out-File error.txt\n\n")
    f.write("Invoke-Command -Session $s { Invoke-Expression 'cd \"C:\\ProgramData\\Microsoft\\Windows Defender\\Platform\\4.18.2011.6-0\\\"; .\\MpCmdRun.exe -Scan -ScanType 3 -File \"C:\\users\\thepcn3rd\\sigtest\\sample.file_" + str(initialRandom) + "_" + str(secondRandom) + ".ps1\" -DisableRemediation -Trace -Level 0x10' | Out-File c:\\users\\thepcn3rd\\sigtest\\defender.txt }\n")
    f.write("Invoke-Expression 'Copy-Item -FromSession $s -Path \"C:\\users\\thepcn3rd\\sigtest\\defender.txt\" -Destination \"/home/kali/defenderCheck/files/defender.txt\"'") 
    f.close()
    os.system("chmod 700 " + scriptPath)
    os.system(scriptPath)
    # Evaluate the error that is returned if the upload of the file failed
    if os.path.exists("/home/kali/defenderCheck/error.txt"):
        result = checkError()
        os.system("rm -f /home/kali/defenderCheck/error.txt")
    else:
        result = "Clean"
    
    # Evaluate the defender.txt file which is the output of the windows defender to see if a threat exists
    defenderLog = "/home/kali/defenderCheck/files/defender.txt"
    threatExists = "No"
    if os.path.exists(defenderLog):
        os.system("dos2unix " + defenderLog)
        fDefender = open(defenderLog, "r", encoding="ascii", errors='ignore')
        for lineD in fDefender:
            lineD = lineD.strip()
            if "Threat" in lineD:
                print(lineD)
                threatExists = "Yes"
    # Download Complete - No Threat
    if result == "Clean" and threatExists == "No":
        print("File: " + str(fA) + " Result: Upload Complete - No Threat Exists")
        log.write("File: " + str(fA) + " Result: Upload Complete - No Threat Exists\n")
    # Download Failed - No Threat - Segment not in Name
    elif result == "Detected" and threatExists == "No" and "segment" not in str(fA):
        print("File: " + str(fA) + " Result: Upload Failed - Signature Detected - Threat not Evaluated")
        log.write("File: " + str(fA) + " Result: Upload Failed - Signature Detected - Threat not Evaluated\n")
        #createSegments(fA, l) # Analyzes blocks of code splitup
        analyzeSegments(fA, l) # Analyzes (Size of file minus 1000 lines to see if it triggers)
    # Download Failed - No Threat - Segment in Name
    elif result == "Detected" and threatExists == "No" and "segment" in str(fA):
        print("File: " + str(fA) + " Result: Upload Failed - Signature Detected - Threat not Evaluated")
        log.write("File: " + str(fA) + " Result: Upload Failed - Signature Detected - Threat not Evaluated\n")
    # Download Complete - Threat Exists - Segment in Name
    elif result == "Clean" and threatExists == "Yes" and "segment" in str(fA):
        print("File: " + str(fA) + " Result: Upload Complete - Threat Exists")
        log.write("File: " + str(fA) + " Result: Upload Complete - Threat Exists\n")
    # Download Complete - Threat Exists - Segment not in Name
    elif result == "Clean" and threatExists == "Yes" and "segment" not in str(fA):
        print("File: " + str(fA) + " Result: Upload Complete - Threat Exists")
        log.write("File: " + str(fA) + " Result: Upload Complete - Threat Exists\n")
        analyzeSegments(fA, l) 
    else:
        print("File: " + str(fA) + " Result: Incomplete Analysis")
        log.write("File: " + str(fA) + " Result: Incomplete Analysis\n")
    log.close()



def checkError():
    if (os.path.exists("/home/kali/defenderCheck/error.txt")):
        f = open("/home/kali/defenderCheck/error.txt", "r")
        for line in f:
            if "MI_RESULT_FAILED" in line or "Failed to copy file":
                return "Detected"
    else:
        return "Clean"
    return "Clean"


def createSegments(fA, lines):
    #global winrmusername
    #global winrmpassword
    #global box
    # fA - File being analyzed
    # lines - Number of lines per file segment
    lineCount = 0
    segmentCount = 0
    # Open file to be analyzed
    f = open(fA, "r")
    for line in f:
        if lineCount == 0:
            # Open Segment File
            fileSegmentName = "/home/kali/defenderCheck/segments/segment" + str(segmentCount) + ".segment"
            fileSegment = open(fileSegmentName, "w")
            fileSegment.write(line.strip() + "\n")
            lineCount += 1
        elif lineCount == lines:
            fileSegment.write(line.strip() + "\n")
            fileSegment.close()
            submitDefender(fileSegmentName, winrmusername, winrmpassword, box, linesToAnalyze)
            lineCount = 0
            segmentCount += 1
        else:
            fileSegment.write(line.strip() + "\n")
            lineCount += 1
    if lineCount > 0:
        fileSegment.write(line.strip() + "\n")
        fileSegment.close()
        submitDefender(fileSegmentName, winrmusername, winrmpassword, box)
    f.close()
        
def analyzeSegments(fA, lines):
    # Looking at ThreatCheck done by RastaMouse he analyzes the file and increases the size of it until it is triggered.
    # References: https://github.com/rasta-mouse/ThreatCheck/blob/master/ThreatCheck/ThreatCheck/Defender/Defender.cs
    #global winrmusername
    #global winrmpassword
    #global box
    # fA - File being analyzed
    # lines - Number of lines per file segment
    totalLineCount = 0
    placeholderLineCount = 0
    segmentCount = 0
    # Open file to be analyzed
    f = open(fA, "r")
    for line in f:
        totalLineCount += 1
    placeholderLineCount = totalLineCount - lines
    f.close()
    while placeholderLineCount > 0:
        lineCount = 0
        f = open(fA, "r")
        # Open Segment File for Progressive Growth
        fileSegmentName = "/home/kali/defenderCheck/segments/segmentP" + str(placeholderLineCount) + ".segment"
        fileSegment = open(fileSegmentName, "w")
        for line in f:
            fileSegment.write(line.strip() + "\n")
            if lineCount > placeholderLineCount:
                break
            lineCount += 1
        f.close()
        fileSegment.close()
        submitDefender(fileSegmentName, winrmusername, winrmpassword, box, linesToAnalyze)
        placeholderLineCount -= lines

        


def main():
    #fileToAnalyze = "/home/kali/defenderCheck/files/powerView.ps1"
    #fileToAnalyze = "/home/kali/defenderCheck/files/basePowerView.ps1"
    #fileToAnalyze = "/home/kali/defenderCheck/files/P10945.ps1"
    #fileToAnalyze = "/home/kali/defenderCheck/files/P10347.ps1"
    #fileToAnalyze = "/home/kali/defenderCheck/files/P10319.ps1"
    fileToAnalyze = "/home/kali/defenderCheck/files/baseInvokeMini.ps1"
    #fileToAnalyze = "/home/kali/defenderCheck/files/modInvokeMini.ps1"
    #fileToAnalyze = "/home/kali/defenderCheck/files/P506.ps1"
    #fileToAnalyze = "/home/kali/defenderCheck/files/P984.ps1"
    #fileToAnalyze = "/home/kali/defenderCheck/files/P951.ps1"
    global winrmusername
    winrmusername = "username"
    global winrmpassword
    winrmpassword = "badpassword"
    global box
    box = "Win10"
    global linesToAnalyze
    linesToAnalyze = 100
    submitDefender(fileToAnalyze, winrmusername, winrmpassword, box, linesToAnalyze)





if __name__ == "__main__":
    main()
