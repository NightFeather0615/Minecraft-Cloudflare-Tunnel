function Get-CfdExe {
  return Get-ChildItem -Filter "*.exe" | Where-Object Name -EQ "cloudflared.exe" | Select-Object -First 1
}

function Install-CfdExe {
  Invoke-WebRequest -OutFile "cloudflared.exe" -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
  return Get-CfdExe
}

function Get-Config {
  return Get-ChildItem -Filter "*.json" | Where-Object Name -EQ "config.json" | Select-Object -First 1
}

function Initialize-Config {
  $config = @{
    Hostname = "";
    Listener = "127.0.0.1:25565"
  }

  $config.Hostname = Read-Host -Prompt "Hostname"
  $listener = Read-Host -Prompt "Listener (127.0.0.1 by Default)"

  if ($listener.Length -ne 0) {
    $config.Listener = $listener
  }

  $config | ConvertTo-Json | Out-File -FilePath "./config.json"

  return Get-Config
}

$cfdExe = Get-CfdExe

if ($null -EQ $cfdExe) {
  $cfdExe = Install-CfdExe
}

$config = Get-Config

if ($null -EQ $config) {
  $config = Initialize-Config
}

$config = $config.OpenText().ReadToEnd() | ConvertFrom-Json

do {
  & "./cloudflared.exe" access tcp --hostname $config.Hostname --listener $config.Listener
  Start-Sleep 1
  Write-Host "Restarting... (Press Ctrl + C to Exit)"
} until ($false)
