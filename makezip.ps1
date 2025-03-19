param([string]$zipFileName = "keymod.zip")
$itemsToArchive = @("lua", "keymod.exe", "LICENSE.txt", "README.md")
if (Test-Path $zipFileName) {
  Remove-Item $zipFileName
}
foreach ($item in $itemsToArchive) {
  if (Test-Path $item) {
    Compress-Archive -Path $item -Update -DestinationPath $zipFileName
  } else {
    Write-Host "Warning: $item does not exist and will not be included in the archive."
  }
}
Write-Host "Files and directories have been archived into $zipFileName"
