param(
  [string]$Version,
  [string]$BinaryPath,
  [string]$DownloadBaseUrl,
  [string]$OutputPath
)

# SHA256 계산
$hash = Get-FileHash -Path $BinaryPath -Algorithm SHA256
$sha256 = $hash.Hash.ToLower()

# JSON 생성
$metadata = @{
  version     = $Version
  downloadUrl = "$DownloadBaseUrl/myhome.apk"
  sha256      = $sha256
} | ConvertTo-Json -Depth 3

# 출력
$metadata | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "Metadata written to $OutputPath"
Write-Host $metadata