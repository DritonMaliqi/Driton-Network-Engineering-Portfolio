$Project = "C:\Users\Acer\Documents\GitHub\Driton-Network-Engineering-Portfolio\16-NETOPS-Network-Configuration-Generator"
$Backend = Join-Path $Project "web-ui\backend"

Start-Process powershell.exe -ArgumentList "-NoExit","-ExecutionPolicy","Bypass","-Command","cd '$Backend'; python -m uvicorn api:app --host 127.0.0.1 --port 8000"
Start-Sleep -Seconds 3
Start-Process powershell.exe -ArgumentList "-NoExit","-Command","ngrok http 8000"
Start-Sleep -Seconds 5

try {
    $Url = (Invoke-RestMethod http://127.0.0.1:4040/api/tunnels).tunnels[0].public_url
    Start-Process $Url
} catch {
    Start-Process "http://127.0.0.1:8000"
}
