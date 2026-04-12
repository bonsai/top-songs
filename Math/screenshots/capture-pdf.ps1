# PDF Screenshot Capture Script
# Captures golden-ratio-paper.pdf displayed in browser

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$browser = Get-Process msedge -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $browser) {
    Write-Host "Edge not found, opening PDF..."
    Start-Process msedge "C:\Users\dance\Documents\MEGA\MCP\clips\Math\golden-ratio-paper.pdf"
    Start-Sleep -Seconds 4
}

# Wait a bit more
Start-Sleep -Seconds 2

# Get screen bounds
$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
$gfx = [System.Drawing.Graphics]::FromImage($bmp)
$gfx.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)

# Save screenshot
$outDir = "C:\Users\dance\Documents\MEGA\MCP\clips\Math\screenshots"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$bmp.Save("$outDir\pdf-browser-1.png")
Write-Host "Captured: pdf-browser-1.png"

$bmp.Dispose()
$gfx.Dispose()
