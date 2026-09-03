$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$buildRoot = Join-Path $projectRoot "Build\Windows"
$buildPath = Join-Path $buildRoot "Create Heaven.exe"
$logPath = Join-Path $projectRoot "Build\launcher.log"
$serverRoot = Join-Path $projectRoot "Server"

New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $logPath) | Out-Null

function Write-LauncherLog([string] $message) {
    Add-Content -LiteralPath $logPath -Value ("[{0}] {1}" -f (Get-Date -Format s), $message)
}

try {
    $serverExe = Join-Path $serverRoot "server.exe"
    $serverScript = Join-Path $serverRoot "start-server.cmd"
    if (Test-Path -LiteralPath $serverExe) {
        Start-Process -FilePath $serverExe -WorkingDirectory $serverRoot -WindowStyle Hidden
        Write-LauncherLog "Started Server\\server.exe in the background."
    } elseif (Test-Path -LiteralPath $serverScript) {
        Start-Process -FilePath $env:ComSpec -ArgumentList "/c `"$serverScript`"" -WorkingDirectory $serverRoot -WindowStyle Hidden
        Write-LauncherLog "Started Server\\start-server.cmd in the background."
    } else {
        Write-LauncherLog "No optional Server process found; launching the local game only."
    }

    if (-not (Test-Path -LiteralPath $buildPath)) {
        $unityCandidates = @(
            "$env:ProgramFiles\Unity\Hub\Editor\2021.3.21f1\Editor\Unity.exe",
            "$env:ProgramFiles\Unity\Hub\Editor\2021.3.21\Editor\Unity.exe",
            "$env:ProgramFiles(x86)\Unity\Hub\Editor\2021.3.21f1\Editor\Unity.exe"
        )
        $unity = $unityCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if (-not $unity) {
            throw "Unity 2021.3.21 was not found. Install it with Unity Hub, or build the player to '$buildPath'."
        }

        Write-LauncherLog "Building Windows player with $unity."
        $arguments = @(
            "-batchmode", "-quit", "-nographics",
            "-projectPath", $projectRoot,
            "-executeMethod", "UnityBuilderAction.BuildScript.Build",
            "-buildTarget", "StandaloneWindows64",
            "-customBuildPath", $buildPath,
            "-customBuildName", "Create Heaven",
            "-buildVersion", "1.0.0",
            "-androidVersionCode", "1"
        )
        $buildProcess = Start-Process -FilePath $unity -ArgumentList $arguments -WorkingDirectory $projectRoot -Wait -PassThru -WindowStyle Hidden
        if ($buildProcess.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $buildPath)) {
            throw "Unity build failed with exit code $($buildProcess.ExitCode). See the Unity editor log for details."
        }
        Write-LauncherLog "Windows player build succeeded."
    }

    Write-LauncherLog "Launching Create Heaven."
    Start-Process -FilePath $buildPath -WorkingDirectory (Split-Path -Parent $buildPath)
} catch {
    Write-LauncherLog "ERROR: $($_.Exception.Message)"
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($_.Exception.Message, "Create Heaven launcher") | Out-Null
    exit 1
}