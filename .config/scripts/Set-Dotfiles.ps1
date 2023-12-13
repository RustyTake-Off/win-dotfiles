# ╒══════╗        ╒═══════╗
# │ ╓──┐ ║════════╗  ╓─┐  ║
# │ ╚══╛ ║──┐  ╓──╜  ║ │  ║  RustyTake-Off
# │ ╓─┐ ╔╝  │  ║  │  ║ │  ║  https://github.com/RustyTake-Off
# │ ║ │ ╚╗  │  ║  │  ╚═╛  ║
# └─╜ └──╜  └──╜  └───────╜
# Script for setting up Windows dotfiles.

#Requires -RunAsAdministrator

<#
.SYNOPSIS
Script for setting up Windows dotfiles.

.DESCRIPTION
This script makes it easier to set up dotfiles on a Windows system. It creates symbolic links and copies necessary configuration files to configure PowerShell profiles, scripts, Windows Terminal, Winget, and WSL config.

.NOTES
You might want to not change the Execution Policy permanently so to change it only for the current process
run the bellow command and then run the script.
PS> Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

To change Execution Policy permanently run bellow command which only allows trusted publishers.
PS> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

This script also needs to be run from elevated terminal as admin.

.LINK
Repository      -   "https://github.com/RustyTake-Off/win-dotfiles",
Script file     -   "https://github.com/RustyTake-Off/win-dotfiles/blob/main/.config/scripts/Set-Dotfiles.ps1"
#>

[CmdletBinding(SupportsShouldProcess)]

# ================================================================================
# Main variables

$ConfigPowerShellProfilePath = "$env:USERPROFILE\.config\powershell_profile"
$ConfigScriptsPath = "$env:USERPROFILE\.config\scripts"
$ConfigWindowsTerminalPath = "$env:USERPROFILE\.config\windows_terminal"
$ConfigWingetPath = "$env:USERPROFILE\.config\winget"
$ConfigWSLPath = "$env:USERPROFILE\.config\wsl"

# ================================================================================
# Helper functions

function New-SymLink {
    param(
        [String] $SourceToLink,

        [String] $TargetToLink
    )

    try {
        New-Item -ItemType SymbolicLink -Target $SourceToLink -Path $TargetToLink
        Write-Output "Creating SymLink: $($(Split-Path -Path $SourceToLink) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $SourceToLink).Name) -> $($(Split-Path -Path $TargetToLink) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $TargetToLink).Name)"
    } catch {
        Write-Error "Error creating new SymbolicLink: $_"
        Write-Error "Line: $($_.ScriptStackTrace)"
    }
}

function New-HashThenSymLink {
    param(
        [String] $SourceToLink,

        [String] $TargetToLink
    )

    try {
        $HashOne = Get-FileHash -Path $SourceToLink -Algorithm SHA256
        $HashTwo = Get-FileHash -Path $TargetToLink -Algorithm SHA256
    } catch {
        Write-Error "Error calculating file hashes: $_"
        Write-Error "Line: $($_.ScriptStackTrace)"
    }

    try {
        if ($HashOne.Hash -ne $HashTwo.Hash) {
            Remove-Item -Path $TargetToLink -Force
            Write-Output "Removing $($(Split-Path -Path $TargetToLink) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $TargetToLink).Name)"
            New-SymLink -SourceToLink $SourceToLink -TargetToLink $TargetToLink
        } else {
            Write-Output "SymLink already set: $($(Split-Path -Path $SourceToLink) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $SourceToLink).Name) -> $($(Split-Path -Path $TargetToLink) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $TargetToLink).Name)"
        }
    } catch {
        Write-Error "Error creating new SymbolicLink: $_"
        Write-Error "Line: $($_.ScriptStackTrace)"
    }
}

function Invoke-SetSymLinks {
    param(
        [String] $SourceToLink,

        [String] $TargetToLink
    )

    try {
        if ((Test-Path -Path $SourceToLink -PathType Leaf) -and (-not (Test-Path -Path $TargetToLink -PathType Leaf))) {
            New-SymLink -SourceToLink $SourceToLink -TargetToLink $TargetToLink
        } elseif ((Test-Path -Path $SourceToLink -PathType Leaf) -and (Test-Path -Path $TargetToLink -PathType Leaf)) {
            New-HashThenSymLink -SourceToLink $SourceToLink -TargetToLink $TargetToLink
        } elseif ((-not (Test-Path -Path $SourceToLink -PathType Leaf)) -and (Test-Path -Path $TargetToLink -PathType Leaf)) {
            Write-Error "Cannot create SymLink, SourceToLink doesn't exist in dotfiles"
        }
    } catch {
        Write-Error "Error creating new SymbolicLink: $_"
        Write-Error "Line: $($_.ScriptStackTrace)"
    }
}

# ================================================================================
# Main code

# Set dotfiles
try {
    if (-not (Test-Path -Path "$env:USERPROFILE\.dotfiles" -PathType Container)) {
        if (Get-Command git) {
            git clone --bare 'https://github.com/RustyTake-Off/win-dotfiles.git' "$env:USERPROFILE\.dotfiles"
            git --git-dir="$env:USERPROFILE\.dotfiles" --work-tree=$env:USERPROFILE checkout
            git --git-dir="$env:USERPROFILE\.dotfiles" --work-tree=$env:USERPROFILE config status.showUntrackedFiles no
        } else {
            Write-Error 'Git is not installed'
            Exit
        }
    } else {
        Write-Output 'Dotfiles are set. Checking for updates'
        git --git-dir="$env:USERPROFILE\.dotfiles" --work-tree=$env:USERPROFILE reset --hard
        git --git-dir="$env:USERPROFILE\.dotfiles" --work-tree=$env:USERPROFILE pull
    }
} catch {
    Write-Error "Error setting up dotfiles: $_"
    Write-Error "Line: $($_.ScriptStackTrace)"
    Exit
}

# Set PowerShell profiles
$PowerShellProfilePath = "$env:USERPROFILE\Documents\PowerShell"
if ($ConfigPowerShellProfileFiles = Get-ChildItem -Path $ConfigPowerShellProfilePath -File -Recurse) {
    if (-not (Test-Path -Path $PowerShellProfilePath -PathType Container)) {
        New-Item -Path $PowerShellProfilePath -ItemType Directory

        foreach ($File in $ConfigPowerShellProfileFiles) {
            Invoke-SetSymLinks -SourceToLink "$ConfigPowerShellProfilePath\$($File.Name)" -TargetToLink "$PowerShellProfilePath\$($File.Name)"
        }
    } else {
        foreach ($File in $ConfigPowerShellProfileFiles) {
            Invoke-SetSymLinks -SourceToLink "$ConfigPowerShellProfilePath\$($File.Name)" -TargetToLink "$PowerShellProfilePath\$($File.Name)"
        }
    }
} else {
    Write-Output 'PowerShell profile config is missing from dotfiles'
}

# Set PowerShell scripts
$PowerShellScriptsPath = "$env:USERPROFILE\Documents\PowerShell\Scripts"
if ($ConfigScriptFiles = Get-ChildItem -Path $ConfigScriptsPath -File -Recurse) {
    if (-not (Test-Path -Path $PowerShellScriptsPath -PathType Container)) {
        New-Item -Path $PowerShellScriptsPath -ItemType Directory

        foreach ($File in $ConfigScriptFiles) {
            Invoke-SetSymLinks -SourceToLink "$ConfigScriptsPath\$($File.Name)" -TargetToLink "$PowerShellScriptsPath\$($File.Name)"
        }
    } else {
        foreach ($File in $ConfigScriptFiles) {
            Invoke-SetSymLinks -SourceToLink "$ConfigScriptsPath\$($File.Name)" -TargetToLink "$PowerShellScriptsPath\$($File.Name)"
        }
    }
} else {
    Write-Output 'PowerShell scripts are missing from dotfiles'
}

# Set Windows Terminal config
$WindowsTerminalPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
if ($ConfigWindowsTerminalFiles = Get-ChildItem -Path $ConfigWindowsTerminalPath -File -Recurse) {
    if (-not (Test-Path -Path $WindowsTerminalPath -PathType Container)) {
        New-Item -Path $WindowsTerminalPath -ItemType Directory

        foreach ($File in $ConfigWindowsTerminalFiles) {
            $SourceToCopy = "$ConfigWindowsTerminalPath\$($File.Name)"
            $TargetToCopy = "$WindowsTerminalPath\settings.json"

            if ((Test-Path -Path $SourceToCopy -PathType Leaf) -and (-not (Test-Path -Path $TargetToCopy -PathType Leaf))) {
                Copy-Item -Path $SourceToCopy -Destination $TargetToCopy
                Write-Output "Copying: $($(Split-Path -Path $SourceToCopy) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $SourceToCopy).Name) -> $($(Split-Path -Path $TargetToCopy) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $TargetToCopy).Name)"
            } elseif ((Test-Path -Path $SourceToCopy -PathType Leaf) -and (Test-Path -Path $TargetToCopy -PathType Leaf)) {
                $HashOne = Get-FileHash -Path $SourceToCopy -Algorithm SHA256
                $HashTwo = Get-FileHash -Path $TargetToCopy -Algorithm SHA256

                if ($HashOne.Hash -ne $HashTwo.Hash) {
                    Remove-Item -Path $TargetToCopy -Force
                    Write-Output "Removing $($(Split-Path -Path $TargetToCopy) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $TargetToCopy).Name)"
                    Copy-Item -Path $SourceToCopy -Destination $TargetToCopy
                    Write-Output "Copying: $($(Split-Path -Path $SourceToCopy) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $SourceToCopy).Name) -> $($(Split-Path -Path $TargetToCopy) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $TargetToCopy).Name)"
                } else {
                    Write-Output "Config already set: $($(Split-Path -Path $SourceToCopy) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $SourceToCopy).Name) -> $($(Split-Path -Path $TargetToCopy) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $TargetToCopy).Name)"
                }
            } elseif (-not (Test-Path -Path $SourceToCopy -PathType Leaf)) {
                Write-Error "SourceToCopy doesn't exist in dotfiles"
            }
        }
    } else {
        foreach ($File in $ConfigWindowsTerminalFiles) {
            $SourceToCopy = "$ConfigWindowsTerminalPath\$($File.Name)"
            $TargetToCopy = "$WindowsTerminalPath\settings.json"

            if ((Test-Path -Path $SourceToCopy -PathType Leaf) -and (-not (Test-Path -Path $TargetToCopy -PathType Leaf))) {
                Copy-Item -Path $SourceToCopy -Destination $TargetToCopy
                Write-Output "Copying: $($(Split-Path -Path $SourceToCopy) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $SourceToCopy).Name) -> $($(Split-Path -Path $TargetToCopy) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $TargetToCopy).Name)"
            } elseif ((Test-Path -Path $SourceToCopy -PathType Leaf) -and (Test-Path -Path $TargetToCopy -PathType Leaf)) {
                $HashOne = Get-FileHash -Path $SourceToCopy -Algorithm SHA256
                $HashTwo = Get-FileHash -Path $TargetToCopy -Algorithm SHA256

                if ($HashOne.Hash -ne $HashTwo.Hash) {
                    Remove-Item -Path $TargetToCopy -Force
                    Write-Output "Removing $($(Split-Path -Path $TargetToCopy) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $TargetToCopy).Name)"
                    Copy-Item -Path $SourceToCopy -Destination $TargetToCopy
                    Write-Output "Copying: $($(Split-Path -Path $SourceToCopy) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $SourceToCopy).Name) -> $($(Split-Path -Path $TargetToCopy) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $TargetToCopy).Name)"
                } else {
                    Write-Output "Config already set: $($(Split-Path -Path $SourceToCopy) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $SourceToCopy).Name) -> $($(Split-Path -Path $TargetToCopy) -replace [Regex]::Escape($env:USERPROFILE), '...')\$((Get-Item $TargetToCopy).Name)"
                }
            } elseif (-not (Test-Path -Path $SourceToCopy -PathType Leaf)) {
                Write-Error "SourceToCopy doesn't exist in dotfiles"
            }
        }
    }
} else {
    Write-Output 'Windows Terminal config is missing from dotfiles'
}

# Set Winget config
$WingetPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState"
if ($ConfigWingetFiles = Get-ChildItem -Path $ConfigWingetPath -File -Recurse) {
    if (-not (Test-Path -Path $WingetPath -PathType Container)) {
        New-Item -Path $WingetPath -ItemType Directory

        foreach ($File in $ConfigWingetFiles) {
            Invoke-SetSymLinks -SourceToLink "$ConfigWingetPath\$($File.Name)" -TargetToLink "$WingetPath\settings.json"
            Invoke-SetSymLinks -SourceToLink "$ConfigWingetPath\$($File.Name)" -TargetToLink "$WingetPath\settings.json.backup"
        }
    } else {
        foreach ($File in $ConfigWingetFiles) {
            Invoke-SetSymLinks -SourceToLink "$ConfigWingetPath\$($File.Name)" -TargetToLink "$WingetPath\settings.json"
            Invoke-SetSymLinks -SourceToLink "$ConfigWingetPath\$($File.Name)" -TargetToLink "$WingetPath\settings.json.backup"
        }
    }
} else {
    Write-Output 'Winget config is missing from dotfiles'
}

# Set WSL config
if ($ConfigWSLFiles = Get-ChildItem -Path $ConfigWSLPath -File -Recurse) {
    if (-not (Test-Path -Path "$env:USERPROFILE\.wslconfig" -PathType Leaf)) {
        foreach ($File in $ConfigWSLFiles) {
            Invoke-SetSymLinks -SourceToLink "$ConfigWSLPath\$($File.Name)" -TargetToLink "$env:USERPROFILE\.wslconfig"
        }
    } else {
        foreach ($File in $ConfigWSLFiles) {
            Invoke-SetSymLinks -SourceToLink "$ConfigWSLPath\$($File.Name)" -TargetToLink "$env:USERPROFILE\.wslconfig"
        }
    }
} else {
    Write-Output 'WSL config is missing from dotfiles'
}

# ================================================================================
# Miscellaneous code

if (-not (Test-Path -Path "$env:USERPROFILE\pr" -PathType Container)) {
    $null = New-Item -Path "$env:USERPROFILE\pr" -ItemType Directory
    Write-Output "Creating 'personal' folder"
}

if (-not (Test-Path -Path "$env:USERPROFILE\wk" -PathType Container)) {
    $null = New-Item -Path "$env:USERPROFILE\wk" -ItemType Directory
    Write-Output "Creating 'work' folder"
}