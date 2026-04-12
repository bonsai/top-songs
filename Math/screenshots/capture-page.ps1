Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$OutputDir = "C:\Users\dance\Documents\MEGA\MCP\clips\Math\screenshots"
$HtmlFile = "C:\Users\dance\Documents\MEGA\MCP\clips\Math\prime-fibonacci-discovery.html"
$Url = "file:///" + $HtmlFile.Replace("\", "/")

# Kill any existing Edge instances
Get-Process -Name "msedge" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Open Edge with the HTML file
Start-Process "msedge.exe" -ArgumentList @("--app=$Url", "--window-size=1920,1080", "--force-device-scale-factor=1")
Start-Sleep -Seconds 5

# Function to capture screenshot
function Capture-Screenshot {
    param(
        [string]$Filename
    )
    
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap($screen.Width, $screen.Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($screen.Location, [System.Drawing.Point]::Empty, $screen.Size)
    $g.Dispose()
    
    $path = Join-Path $OutputDir $Filename
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    
    Write-Host "Saved: $path"
}

# Capture initial view
Write-Host "=== Capturing screenshots ==="
Write-Host "Section 1: Title and Abstract"
Capture-Screenshot -Filename "01-title-abstract.png"
Start-Sleep -Milliseconds 500

# Send Page Down key to scroll
[System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
Start-Sleep -Milliseconds 800

Write-Host "Section 2: Fibonacci Definition and Table"
Capture-Screenshot -Filename "02-fibonacci-definition.png"
Start-Sleep -Milliseconds 500

[System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
Start-Sleep -Milliseconds 800

Write-Host "Section 3: Theorem 1"
Capture-Screenshot -Filename "03-theorem-1.png"
Start-Sleep -Milliseconds 500

[System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
Start-Sleep -Milliseconds 800

Write-Host "Section 4: F(p) Verification Table"
Capture-Screenshot -Filename "04-fp-verification.png"
Start-Sleep -Milliseconds 500

[System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
Start-Sleep -Milliseconds 800

Write-Host "Section 5: Known Fibonacci Primes"
Capture-Screenshot -Filename "05-fibonacci-primes.png"
Start-Sleep -Milliseconds 500

[System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
Start-Sleep -Milliseconds 800

Write-Host "Section 6: New Theorem Proposal"
Capture-Screenshot -Filename "06-new-theorem.png"
Start-Sleep -Milliseconds 500

[System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
Start-Sleep -Milliseconds 800

Write-Host "Section 7: Computation Results"
Capture-Screenshot -Filename "07-computation-results.png"
Start-Sleep -Milliseconds 500

[System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
Start-Sleep -Milliseconds 800

Write-Host "Section 8: Golden Ratio Table"
Capture-Screenshot -Filename "08-golden-ratio.png"
Start-Sleep -Milliseconds 500

[System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
Start-Sleep -Milliseconds 800

Write-Host "Section 9: Unsolved Problems"
Capture-Screenshot -Filename "09-unsolved-problems.png"
Start-Sleep -Milliseconds 500

[System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
Start-Sleep -Milliseconds 800

Write-Host "Section 10: Conclusion"
Capture-Screenshot -Filename "10-conclusion.png"
Start-Sleep -Milliseconds 500

[System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
Start-Sleep -Milliseconds 800

Write-Host "Section 11: Footer"
Capture-Screenshot -Filename "11-footer.png"
Start-Sleep -Milliseconds 500

Write-Host ""
Write-Host "=== All screenshots captured! ==="
Write-Host "Output directory: $OutputDir"
Write-Host ""
Write-Host "Cleaning up..."

# Close Edge
Get-Process -Name "msedge" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "Done!"
