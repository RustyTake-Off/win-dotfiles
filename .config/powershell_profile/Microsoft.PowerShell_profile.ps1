# ╒══════╗        ╒═══════╗
# │ ╓──┐ ║════════╗  ╓─┐  ║
# │ ╚══╛ ║──┐  ╓──╜  ║ │  ║  RustyTake-Off
# │ ╓─┐ ╔╝  │  ║  │  ║ │  ║  https://github.com/RustyTake-Off
# │ ║ │ ╚╗  │  ║  │  ╚═╛  ║
# └─╜ └──╜  └──╜  └───────╜
# PowerShell profile config.

# Manage PowerShell profile
function Edit-Profile {
    code (Join-Path -Path $env:USERPROFILE -ChildPath '\Documents\PowerShell\Microsoft.PowerShell_profile.ps1')
}
function Reset-Profile {
    Invoke-Expression (Join-Path -Path $env:USERPROFILE -ChildPath '\Documents\PowerShell\Microsoft.PowerShell_profile.ps1')
}
function Reset-VSCProfile {
    Invoke-Expression (Join-Path -Path $env:USERPROFILE -ChildPath '\Documents\PowerShell\Microsoft.VSCode_profile.ps1')
}

# Init Starship
Invoke-Expression (&starship init powershell)

# Init Zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Setup posh-git for tab completion
if (-not (Get-Module -Name posh-git)) {
    Import-Module -Name posh-git
    $GitPromptSettings.EnablePromptStatus = $false
    $GitPromptSettings.EnableFileStatus = $false
}

# Aliases
Set-Alias -Name 'g' -Value 'git'
Set-Alias -Name 'sudo' -Value 'admin'

# Functions
function hm { Set-Location $env:USERPROFILE }
function hpr { Set-Location "$env:USERPROFILE/pr" }
function hwk { Set-Location "$env:USERPROFILE/wk" }
function desk { Set-Location "$env:USERPROFILE/Desktop" }
function doc { Set-Location "$env:USERPROFILE/Documents" }
function dl { Set-Location "$env:USERPROFILE/Downloads" }
function cd. { Set-Location .. }
function cd.. { Set-Location ..\.. }
function cd... { Set-Location ..\..\.. }
function cd.... { Set-Location ..\..\..\.. }
function cd..... { Set-Location ..\..\..\..\.. }
function cd...... { Set-Location ..\..\..\..\..\.. }
function ll { Get-ChildItem }
function la { Get-ChildItem }
function cls { Clear-Host }

# Dotfiles
function dot {
    git --git-dir="$env:USERPROFILE\.dotfiles" --work-tree=$env:USERPROFILE $Args
}
function wup {
    Invoke-Expression "$env:USERPROFILE\.config\scripts\Use-WinUp.ps1 $Args"
}

# Check file hashes
function md5 { Get-FileHash -Algorithm MD5 $Args }
function sha1 { Get-FileHash -Algorithm SHA1 $Args }
function sha256 { Get-FileHash -Algorithm SHA256 $Args }

# Linux like functions
function admin {
    if (-not $Args) {
        Start-Process wt -Verb RunAs -ArgumentList "pwsh -NoExit -ExecutionPolicy Bypass -Command `
        cd $(Get-Location)"
    } else {
        Start-Process wt -Verb RunAs -ArgumentList "pwsh -NoExit -ExecutionPolicy Bypass -Command `
        cd $(Get-Location) `
        $Args"
    }
}
function touch ([String] $FileName) {
    Write-Output '' | Out-File -FilePath $File -Encoding ASCII
}
function which {
    Get-Command -Name $Args | Select-Object -ExpandProperty Path
}

# Get public IP
function pubip4 { (Invoke-WebRequest -Uri 'https://api.ipify.org/').Content }
function pubip6 { (Invoke-WebRequest -Uri 'https://ifconfig.me/ip').Content }

# PSReadLine
$PSMinimumVersion = [Version]'7.1.999'

# Set prediction
if (($Host.Name -eq 'ConsoleHost') -and ($PSVersionTable.PSVersion -ge $psMinimumVersion)) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
} else {
    Set-PSReadLineOption -PredictionSource History
}
Set-PSReadLineOption -HistoryNoDuplicates:$true
Set-PSReadLineOption -HistorySearchCursorMovesToEnd:$true
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -Colors @{ InlinePrediction = 'Blue' }
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-PSReadLineKeyHandler -Key Alt+w `
    -BriefDescription SaveInHistory `
    -LongDescription 'Save current line in history but do not execute' `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
}

Set-PSReadLineKeyHandler -Key Ctrl+v `
    -BriefDescription PasteAsHereString `
    -LongDescription 'Paste the clipboard text as a here string' `
    -ScriptBlock {
    param($key, $arg)

    Add-Type -Assembly PresentationCore
    if ([System.Windows.Clipboard]::ContainsText()) {
        # Get clipboard text - remove trailing spaces, convert \r\n to \n, and remove the final \n.
        $text = ([System.Windows.Clipboard]::GetText() -replace "\p{ Zs }*`r?`n", "`n").TrimEnd()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("@'`n$text`n'@")
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
    }
}

# Tab completion for winget - https://learn.microsoft.com/en-us/windows/package-manager/winget/tab-completion#enable-tab-completion
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
    $Local:word = $wordToComplete.Replace('"', '""')
    $Local:ast = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# Tab completion for azure-cli - https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest&tabs=winget#enable-tab-completion-in-powershell
Register-ArgumentCompleter -Native -CommandName az -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    $completion_file = New-TemporaryFile
    $env:ARGCOMPLETE_USE_TEMPFILES = 1
    $env:_ARGCOMPLETE_STDOUT_FILENAME = $completion_file
    $env:COMP_LINE = $wordToComplete
    $env:COMP_POINT = $cursorPosition
    $env:_ARGCOMPLETE = 1
    $env:_ARGCOMPLETE_SUPPRESS_SPACE = 0
    $env:_ARGCOMPLETE_IFS = "`n"
    $env:_ARGCOMPLETE_SHELL = 'powershell'
    az 2>&1 | Out-Null
    Get-Content $completion_file | Sort-Object | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
    Remove-Item $completion_file, Env:\_ARGCOMPLETE_STDOUT_FILENAME, Env:\ARGCOMPLETE_USE_TEMPFILES, Env:\COMP_LINE, Env:\COMP_POINT, Env:\_ARGCOMPLETE, Env:\_ARGCOMPLETE_SUPPRESS_SPACE, Env:\_ARGCOMPLETE_IFS, Env:\_ARGCOMPLETE_SHELL
}