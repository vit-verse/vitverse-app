# .\scripts\build.ps1
# or .\scripts\build.ps1 -EnvFile ".env.production"

param(
    [string]$EnvFile = ".env"
)

$ErrorActionPreference = "Stop"

function Show-Menu {
    Write-Host ""
    Write-Host "VIT Connect Build System" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select build type:"
    Write-Host "  1. Debug APK"
    Write-Host "  2. Release APK (Split ABIs)"
    Write-Host "  3. Release APK (Universal)"
    Write-Host "  4. App Bundle (AAB)"
    Write-Host "  5. Profile APK"
    Write-Host "  6. Complete Build (All Variants)"
    Write-Host "  7. Clean Build Directory"
    Write-Host "  0. Exit"
    Write-Host ""
}

function Load-EnvironmentVariables {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "ERROR: Environment file not found: $FilePath" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Loading environment variables from $FilePath..." -ForegroundColor Yellow
    
    $envVars = @{}
    Get-Content $FilePath | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#")) {
            if ($line -match "^([^=]+)=(.*)$") {
                $envVars[$matches[1].Trim()] = $matches[2].Trim()
            }
        }
    }
    
    Write-Host "Loaded $($envVars.Count) environment variables" -ForegroundColor Green
    return $envVars
}

function Build-DartDefines {
    param([hashtable]$Variables)
    
    $defines = @()
    foreach ($key in $Variables.Keys) {
        $value = $Variables[$key] -replace '"', '\"'
        $defines += "--dart-define=$key=$value"
    }
    return $defines
}

function Build-Debug {
    param([array]$DartDefines)
    
    Write-Host ""
    Write-Host "Building Debug APK..." -ForegroundColor Cyan
    
    $args = @("build", "apk", "--debug") + $DartDefines
    & flutter @args
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Build completed successfully" -ForegroundColor Green
        Write-Host "Output: build/app/outputs/flutter-apk/app-debug.apk" -ForegroundColor Yellow
    } else {
        Write-Host "Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
    }
}

function Build-ReleaseSplit {
    param([array]$DartDefines)
    
    Write-Host ""
    Write-Host "Building Release APK (Split ABIs)..." -ForegroundColor Cyan
    
    $args = @(
        "build", "apk",
        "--release",
        "--split-per-abi",
        "--obfuscate",
        "--split-debug-info=./build/debug-info"
    ) + $DartDefines
    
    & flutter @args
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Build completed successfully" -ForegroundColor Green
        Write-Host "Output:" -ForegroundColor Yellow
        Write-Host "  - build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" -ForegroundColor Yellow
        Write-Host "  - build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" -ForegroundColor Yellow
        Write-Host "  - build/app/outputs/flutter-apk/app-x86_64-release.apk" -ForegroundColor Yellow
    } else {
        Write-Host "Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
    }
}

function Build-ReleaseUniversal {
    param([array]$DartDefines)
    
    Write-Host ""
    Write-Host "Building Release APK (Universal)..." -ForegroundColor Cyan
    
    $args = @(
        "build", "apk",
        "--release",
        "--obfuscate",
        "--split-debug-info=./build/debug-info"
    ) + $DartDefines
    
    & flutter @args
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Build completed successfully" -ForegroundColor Green
        Write-Host "Output: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Yellow
    } else {
        Write-Host "Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
    }
}

function Build-AppBundle {
    param([array]$DartDefines)
    
    Write-Host ""
    Write-Host "Building App Bundle (AAB)..." -ForegroundColor Cyan
    
    $args = @(
        "build", "appbundle",
        "--release",
        "--obfuscate",
        "--split-debug-info=./build/debug-info"
    ) + $DartDefines
    
    & flutter @args
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Build completed successfully" -ForegroundColor Green
        Write-Host "Output: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor Yellow
    } else {
        Write-Host "Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
    }
}

function Build-Profile {
    param([array]$DartDefines)
    
    Write-Host ""
    Write-Host "Building Profile APK..." -ForegroundColor Cyan
    
    $args = @("build", "apk", "--profile") + $DartDefines
    & flutter @args
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Build completed successfully" -ForegroundColor Green
        Write-Host "Output: build/app/outputs/flutter-apk/app-profile.apk" -ForegroundColor Yellow
    } else {
        Write-Host "Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
    }
}

function Build-All {
    param([array]$DartDefines)
    
    Write-Host ""
    Write-Host "Building All Variants..." -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "[1/7] Cleaning previous builds..." -ForegroundColor Yellow
    flutter clean
    Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "[2/7] Getting dependencies..." -ForegroundColor Yellow
    flutter pub get
    
    Write-Host "[3/7] Running code analysis..." -ForegroundColor Yellow
    flutter analyze
    
    Write-Host "[4/7] Building Release APK (Universal)..." -ForegroundColor Yellow
    Build-ReleaseUniversal -DartDefines $DartDefines
    
    Write-Host "[5/7] Building Release APK (Split ABIs)..." -ForegroundColor Yellow
    Build-ReleaseSplit -DartDefines $DartDefines
    
    Write-Host "[6/7] Building App Bundle (AAB)..." -ForegroundColor Yellow
    Build-AppBundle -DartDefines $DartDefines
    
    Write-Host "[7/7] Building Profile APK..." -ForegroundColor Yellow
    Build-Profile -DartDefines $DartDefines
    
    Write-Host ""
    Write-Host "All builds completed" -ForegroundColor Green
}

function Clean-BuildDirectory {
    Write-Host ""
    Write-Host "Cleaning build directory..." -ForegroundColor Cyan
    
    flutter clean
    Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "Build directory cleaned" -ForegroundColor Green
}

$envVars = Load-EnvironmentVariables -FilePath $EnvFile
$dartDefines = Build-DartDefines -Variables $envVars

while ($true) {
    Show-Menu
    $choice = Read-Host "Enter your choice"
    
    switch ($choice) {
        "1" { Build-Debug -DartDefines $dartDefines }
        "2" { Build-ReleaseSplit -DartDefines $dartDefines }
        "3" { Build-ReleaseUniversal -DartDefines $dartDefines }
        "4" { Build-AppBundle -DartDefines $dartDefines }
        "5" { Build-Profile -DartDefines $dartDefines }
        "6" { Build-All -DartDefines $dartDefines }
        "7" { Clean-BuildDirectory }
        "0" { 
            Write-Host ""
            Write-Host "Exiting..." -ForegroundColor Yellow
            exit 0
        }
        default { 
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
