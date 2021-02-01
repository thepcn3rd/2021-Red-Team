# Tactics: Defense Evasion
# Technique: Timestomp https://attack.mitre.org/wiki/Technique/T1099
# Source: https://gist.github.com/obscuresec/7b0cf71d7a8dd5e7b54c

$test = "Atomic Test File"
set-content -path test.txt -value $test
$file=(gi test.txt);$date='7/16/1945 5:29 am';$file.LastWriteTime=$date;$file.LastAccessTime=$date;$file.CreationTime=$date
