param(
  [string]$BinaryPath,
  [string]$DownloadBaseUrl,
  [string]$OutputPath
)

# SHA256 계산
$hash = Get-FileHash -Path $BinaryPath -Algorithm SHA256
$pubspec = Join-Path $PSScriptRoot "..\pubspec.yaml"

$version = (
    Select-String '^version:' $pubspec
).Line.Split(':')[1].Trim().Split('+')[0]

# JSON 생성
$metadata = @{
  version     = $version
  downloadUrl = "$DownloadBaseUrl/myhome/myhome.apk"
  sha256      = $hash.Hash.ToLower()
} | ConvertTo-Json -Depth 3

# 출력
$metadata | Out-File $OutputPath -Encoding utf8