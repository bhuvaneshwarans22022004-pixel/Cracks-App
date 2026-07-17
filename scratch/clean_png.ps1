# Load System.Drawing assembly to work with images
Add-Type -AssemblyName System.Drawing

$imgPath = "C:\empty\Cracks\FestiveKart\FestiveKart-App\android\app\src\main\res\drawable\launch_image.png"
$cleanPath = "C:\empty\Cracks\FestiveKart\FestiveKart-App\android\app\src\main\res\drawable\launch_image_clean.png"

Write-Host "Loading image..."
$bmp = New-Object System.Drawing.Bitmap($imgPath)

Write-Host "Saving standard clean PNG (stripping color profile metadata)..."
$bmp.Save($cleanPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Host "Replacing original image..."
Move-Item -Force $cleanPath $imgPath

Write-Host "Success! The PNG metadata has been cleaned."
