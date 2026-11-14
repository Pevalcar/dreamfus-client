Add-Type -AssemblyName System.Net.WebSockets
$ws = New-Object System.Net.WebSockets.ClientWebSocket
$uri = New-Object System.Uri('ws://127.0.0.1:5557')
$task = $ws.ConnectAsync($uri, [Threading.CancellationToken]::None)
while (-not $task.IsCompleted) { Start-Sleep -Milliseconds 100 }
Write-Host "WebSocket connected: $($ws.State)"