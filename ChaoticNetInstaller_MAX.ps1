<#
    .SYNOPSIS
    Copies V-Ray for 3ds Max folders to a user-specified path 
    and sets the required environment variables for all users.

    .DESCRIPTION
    This script will prompt for:
    1. V-Ray major version (e.g. 6 or 7)
    2. 3ds Max year version (e.g. 2024 or 2025)
    3. A base path to copy files to (e.g. "T:\MAX_PATH")

    Then it will:
    - Create the required folder structure: 
         $BasePath\Vray$version\3dsMax$year\ApplicationPlugins
    - Copy the VRay3dsMax$year folder from ProgramData\ApplicationPlugins.
    - Copy the "3ds Max $year" folder from Program Files\Chaos\V-Ray.
    - Create the environment variables for all users:
         ADSK_APPLICATION_PLUGINS,
         VRAY_FOR_3DSMAX$year_MAIN,
         VRAY_FOR_3DSMAX$year_PLUGINS,
         VRAY_MDL_PATH_3DSMAX$year.
#>

# Request user input
$version  = Read-Host "Enter the V-Ray major version (e.g. 6 or 7)"
$year     = Read-Host "Enter the 3ds Max year version (e.g. 2024 or 2025)"
$basePath = Read-Host "Enter the base path (e.g. T:\MAX_PATH)"
$copyApps = Read-Host "Copy Apps? y/n (choose no if you just want to install env variables)"

# Construct the main destination folder: $basePath\Vray$version\3dsMax$year
$destinationRoot = Join-Path $basePath "Vray$version"
$destinationRoot = Join-Path $destinationRoot "3dsMax$year"

if ($copyApps -eq "y") {
    # 1) Create the main folder if it doesn't exist
    if (-not (Test-Path -Path $destinationRoot)) {
        New-Item -Path $destinationRoot -ItemType Directory | Out-Null
        Write-Host "Created folder: $destinationRoot"
    } else {
        Write-Host "Folder already exists: $destinationRoot"
    }
}

# 2) Create the ApplicationPlugins subfolder
$autodeskAppPluginsFolder = Join-Path $destinationRoot "ApplicationPlugins"
if ($copyApps -eq "y") {
    if (-not (Test-Path -Path $autodeskAppPluginsFolder)) {
        New-Item -Path $autodeskAppPluginsFolder -ItemType Directory | Out-Null
        Write-Host "Created folder: $autodeskAppPluginsFolder"
    } else {
        Write-Host "Folder already exists: $autodeskAppPluginsFolder"
    }
}
# 3) Copy from C:\ProgramData\Autodesk\ApplicationPlugins\VRay3dsMax$year and Phoenix3dsMax$year
$sourceAppPluginsVray = "C:\ProgramData\Autodesk\ApplicationPlugins\VRay3dsMax$year"
$sourceAppPluginsPhoenix = "C:\ProgramData\Autodesk\ApplicationPlugins\Phoenix3dsMax$year"
$destAppPluginsVray   = Join-Path $autodeskAppPluginsFolder "VRay3dsMax$year"
$destAppPluginsPhoenix = Join-Path $autodeskAppPluginsFolder "Phoenix3dsMax$year"

if ($copyApps -eq "y") {
    if (Test-Path $sourceAppPluginsVray) {
        Write-Host "Copying from $sourceAppPluginsVray to $destAppPluginsVray ..."
        Copy-Item -Path $sourceAppPluginsVray -Destination $destAppPluginsVray -Recurse -Force
        Write-Host "Copy complete."
    } else {
        Write-Warning "Source folder does not exist: $sourceAppPluginsVray"
    }

    if (Test-Path $sourceAppPluginsPhoenix) {
        Write-Host "Copying from $sourceAppPluginsPhoenix to $destAppPluginsPhoenix ..."
        Copy-Item -Path $sourceAppPluginsPhoenix -Destination $destAppPluginsPhoenix -Recurse -Force
        Write-Host "Copy complete."
    } else {
        Write-Warning "Source folder does not exist: $sourceAppPluginsPhoenix"
    }
}

# 4) Copy from C:\Program Files\Chaos\V-Ray\3ds Max $year\
if ($year -gt 2024) {
    $sourceChaosVray =          "C:\Program Files\Chaos\V-Ray\3ds Max $year"
    $sourceChaosPhoenix =   "C:\Program Files\Chaos\Phoenix FD\3ds Max $year for x64"
} else {
    $sourceChaosVray =          "C:\Program Files\Chaos Group\V-Ray\3ds Max $year"
    $sourceChaosPhoenix =   "C:\Program Files\Chaos Group\Phoenix FD\3ds Max $year for x64"
}
$destChaosVray   = Join-Path $destinationRoot "3ds Max $year"
$destChaosPhoenix   = Join-Path $destinationRoot "Phoenix 3ds Max $year"

if ($copyApps -eq "y") {
    if (Test-Path $sourceChaosVray) {
        Write-Host "Copying from $sourceChaosVray to $destChaosVray ..."
        Copy-Item -Path $sourceChaosVray -Destination $destChaosVray -Recurse -Force
        Write-Host "Copy complete."
    } else {
        Write-Warning "Source folder does not exist: $sourceChaosVray"
    }

    if (Test-Path $sourceChaosPhoenix) {
        Write-Host "Copying from $sourceChaosPhoenix to $destChaosPhoenix ..."
        Copy-Item -Path $sourceChaosPhoenix -Destination $destChaosPhoenix -Recurse -Force
        Write-Host "Copy complete."
    } else {
        Write-Warning "Source folder does not exist: $sourceChaosPhoenix"
    }
}

# 5) Create (or overwrite) environment variables for all users (Machine scope).
#    Requires an elevated session (Run as Administrator).

Write-Host "Setting environment variables for all users..."

# ADSK_APPLICATION_PLUGINS
[System.Environment]::SetEnvironmentVariable(
    "ADSK_APPLICATION_PLUGINS", 
    $autodeskAppPluginsFolder, 
    [System.EnvironmentVariableTarget]::Machine
)

# VRAY_FOR_3DSMAX$year_MAIN
[System.Environment]::SetEnvironmentVariable(
    ("VRAY_FOR_3DSMAX$($year)_MAIN"), 
    (Join-Path $destAppPlugins "bin"), 
    [System.EnvironmentVariableTarget]::Machine
)

# PHX_FOR_3DSMAX20xx_BIN
[System.Environment]::SetEnvironmentVariable(
    ("PHX_FOR_3DSMAX$($year)_BIN"), 
    (Join-Path $destAppPluginsPhoenix "bin"), 
    [System.EnvironmentVariableTarget]::Machine
)

# VRAY_FOR_3DSMAX$year_PLUGINS
[System.Environment]::SetEnvironmentVariable(
    "VRAY_FOR_3DSMAX$($year)_PLUGINS", 
    (Join-Path (Join-Path $destAppPlugins "bin") "plugins"), 
    [System.EnvironmentVariableTarget]::Machine
)

# 	PHX_FOR_3DSMAX$year_STNDPLUGS
[System.Environment]::SetEnvironmentVariable(
    "PHX_FOR_3DSMAX$($year)_STNDPLUGS", 
    (Join-Path (Join-Path $destAppPluginsPhoenix "bin") "plugins"), 
    [System.EnvironmentVariableTarget]::Machine
)

# VRAY_MDL_PATH_3DSMAX$year
[System.Environment]::SetEnvironmentVariable(
    "VRAY_MDL_PATH_3DSMAX$($year)", 
    (Join-Path $destChaos "mdl"), 
    [System.EnvironmentVariableTarget]::Machine
)

Write-Host "`nAll done!"
Write-Host "Note: Newly set machine-level environment variables may require a logoff/restart to take effect in all applications."
