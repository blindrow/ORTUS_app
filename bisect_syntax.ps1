Param(
  [string]$File = "lib\schedule_page.dart"
)

if (-not (Test-Path $File)) { Write-Error "File not found: $File"; exit 1 }
Copy-Item $File "$File.bak" -Force
Write-Host "Backup saved to $File.bak"

$lines = Get-Content $File
$lo = 1
$hi = $lines.Count

Write-Host "Total lines: $hi"
Write-Host "Starting binary search..."

while (($hi - $lo) -gt 10) {
  $mid = [int](($lo + $hi) / 2)
  Write-Host "`nTesting keep $lo..$mid ; comment $($mid+1)..$hi"
  
  $top = $lines[0..($mid-1)]
  $bottom = $lines[$mid..($hi-1)]
  $work = @()
  $work += $top
  $work += "/*==COMMENTED BY BISECT==*/"
  $work += $bottom
  $work += "/*==END COMMENT==*/"
  $work | Set-Content $File
  
  $analyze = & flutter analyze 2>&1 | Out-String
  if ($LASTEXITCODE -eq 0) {
    Write-Host "analyze OK => issue in commented (bottom) half"
    $lo = $mid + 1
  } else {
    Write-Host "analyze FAIL => issue in kept (top) half"
    $hi = $mid
  }
  
  # restore original before next iteration
  Copy-Item "$File.bak" $File -Force
}

Write-Host ""
Write-Host "=== NARROWED RANGE: $lo - $hi ==="
Write-Host "Showing lines from $lo to $hi"
$n = $lo
$lines[($lo-1)..($hi-1)] | ForEach-Object { Write-Host "$n`t$_"; $n++ }
Write-Host "`nOriginal file backed up to $File.bak"
