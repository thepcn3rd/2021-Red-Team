# Created to encypt powershell scripts prior to being downloaded from an SSL Server
# Created during the Pentester Academy Attacking and Defending Active Directory
#
# Reference: https://gist.github.com/ctigeek/2a56648b923d198a6e60
#
# Future ideas - Pull the key from the webserver so it is not present in the powershell logs

function Create-AesManagedObject($key, $IV) {
    $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize = 256
    if ($IV) {
        if ($IV.getType().Name -eq "String") {
            $aesManaged.IV = [System.Convert]::FromBase64String($IV)
        }
        else {
            $aesManaged.IV = $IV
        }
    }
    if ($key) {
        if ($key.getType().Name -eq "String") {
            $aesManaged.Key = [System.Convert]::FromBase64String($key)
        }
        else {
            $aesManaged.Key = $key
        }
    }
    $aesManaged
}

function Create-AesKey() {
    $aesManaged = Create-AesManagedObject
    $aesManaged.GenerateKey()
    [System.Convert]::ToBase64String($aesManaged.Key)
}

function Encrypt-String($key, $unencryptedString) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($unencryptedString)
    $aesManaged = Create-AesManagedObject $key
    $encryptor = $aesManaged.CreateEncryptor()
    $encryptedData = $encryptor.TransformFinalBlock($bytes, 0, $bytes.Length);
    [byte[]] $fullData = $aesManaged.IV + $encryptedData
    $aesManaged.Dispose()
    [System.Convert]::ToBase64String($fullData)
}

function Decrypt-String($key, $encryptedStringWithIV) {
    $bytes = [System.Convert]::FromBase64String($encryptedStringWithIV)
    $IV = $bytes[0..15]
    $aesManaged = Create-AesManagedObject $key $IV
    $decryptor = $aesManaged.CreateDecryptor();
    $unencryptedData = $decryptor.TransformFinalBlock($bytes, 16, $bytes.Length - 16);
    $aesManaged.Dispose()
    [System.Text.Encoding]::UTF8.GetString($unencryptedData).Trim([char]0)
}

$baseDir = "/home/kali/PentesterAcademy/AD/output/"
$outputDir = "/home/kali/PentesterAcademy/AD/outputEncrypted/"
# File that you encrypting from the base directory above...
$fileName = "Invoke-Mimikatz"
$origFile = $baseDir + $fileName + ".ps1"
$encFile = $outputDir + $fileName + ".enc"
$keyFile = $outputDir + $fileName + ".key"
$logFile = "/home/kali/PentesterAcademy/AD/encFiles.txt"

$key = Create-AesKey
$key | Out-File -FilePath $keyFile
"OrigFile: $($origFile)   EncFile: $($encFile)   Key: $($key)" | Add-Content $logFile
#$unencryptedString = "blahblahblah"
$unencryptedString = Get-Content -Path $origFile -Raw
$encryptedString = Encrypt-String $key $unencryptedString
$encryptedString | Out-File -FilePath $encFile
#$backToPlainText = Decrypt-String $key $encryptedString
#$backToPlainText | out-file -FilePath "test.ps1"