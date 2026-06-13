# FestiveKart Web Build and Firebase Deployer
# Builds the Flutter Web app and deploys to Firebase Hosting

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   FestiveKart Web Builder & Deployer" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Resolve Flutter executable path
$flutterPath = "flutter"
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    # Check common local installation path found earlier
    $localFlutter = "C:\Users\ADMIN\AppData\Local\flutter\bin\flutter.bat"
    if (Test-Path $localFlutter) {
        $flutterPath = $localFlutter
        Write-Host "Found Flutter locally at: $flutterPath" -ForegroundColor Green
    } else {
        Write-Error "Flutter SDK is not found. Please ensure Flutter is installed and added to PATH."
        Exit 1
    }
}

# 2. Check if Firebase CLI is installed
$firebasePath = "firebase"
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Host "Firebase CLI is not in PATH. Checking if npm is available to check local tools..." -ForegroundColor Yellow
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        # Check if user has firebase-tools installed globally or locally
        Write-Host "To install Firebase CLI, run: npm install -g firebase-tools" -ForegroundColor Cyan
    }
    Write-Error "Firebase CLI is not installed. Please install firebase-tools globally via npm."
    Exit 1
}

# 3. Handle Firebase Project Config
$projectID = ""
$rcPath = ".firebaserc"
if (Test-Path $rcPath) {
    $rc = Get-Content $rcPath -Raw | ConvertFrom-Json
    if ($rc.projects -and $rc.projects.default) {
        $projectID = $rc.projects.default.ToLower().Trim()
        Write-Host "Using configured Firebase Project: $projectID" -ForegroundColor Green
    }
}

if (-not $projectID) {
    Write-Host "No Firebase Project configured in .firebaserc." -ForegroundColor Yellow
    $userInput = Read-Host "Please enter your Firebase Project ID"
    if (-not $userInput) {
        Write-Error "Firebase Project ID is required."
        Exit 1
    }
    $projectID = $userInput.ToLower().Trim()
    # Create .firebaserc structure
    $rcData = @{
        projects = @{
            default = $projectID
        }
    }
    $rcData | ConvertTo-Json | Out-File -FilePath $rcPath -Encoding utf8
    Write-Host "Created .firebaserc configuration file." -ForegroundColor Green
}

# 4. Build Flutter Web application
Write-Host "`nStep 1: Building Flutter Web App (Release mode)..." -ForegroundColor Cyan
& $flutterPath build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter Web build failed."
    Exit 1
}
Write-Host "Flutter Web build completed successfully!" -ForegroundColor Green

# 5. Deploy to Firebase Hosting
Write-Host "`nStep 2: Deploying to Firebase Hosting..." -ForegroundColor Cyan

# Check firebase login status / project activation
& $firebasePath use $projectID

& $firebasePath deploy --only hosting

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n=========================================" -ForegroundColor Green
    Write-Host "   Deployment successfully completed!" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
} else {
    Write-Error "Firebase deployment failed. If you aren't logged in, run: firebase login"
}
