$body = '{"usuario":"testuser123","clave":"testpass","apodo":"test"}';
$bytes = [System.Text.Encoding]::UTF8.GetBytes($body);
$req = [System.Net.HttpWebRequest]::Create('http://127.0.0.1:8888/api/crear-cuenta');
$req.Method = 'POST';
$req.ContentType = 'application/json';
$req.ContentLength = $bytes.Length;
$stream = $req.GetRequestStream();
$stream.Write($bytes, 0, $bytes.Length);
$stream.Close();
$resp = $req.GetResponse();
$reader = New-Object System.IO.StreamReader($resp.GetResponseStream());
$result = $reader.ReadToEnd();
$reader.Close();
$resp.Close();
Write-Output $result