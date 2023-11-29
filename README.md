# win-dotfiles

🐮📄 Dotfiles and configs for different things Windows. 🔢🛠️

## How to install ⏺️ dotfiles?

> Note: Set-Dotfiles script requires to be run as admin

### Automatic setup

Open terminal as admin and first run this 🗽 command to be temporarily bypassed `ExecutionPolicy`

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

Use the command bellow to 🚀 quickly setup 🔵 dotfiles:

```powershell
Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/RustyTake-Off/win-dotfiles/main/.config/scripts/Set-Dotfiles.ps1' -UseBasicParsing).Content | Invoke-Expression
```

Invoking ☀️ this script will:

* Create `pr` and `wk` folders in user directory
* Clone this repository and save it in the user directory (if the repo is present it will be updated)
* Create `SymbolicLinks` for:
  * PowerShell profiles
  * PowerShell scripts
  * Winget config
  * WSL config
* Copy Windows Terminal config (for some reason using `SymbolicLinks` breaks Windows Terminal updates)

---

### (Optionally) Manual setup

For more ✋ hands on approach here are the 🐾 steps to set it up.

Clone repo in 🐻 `bare` mode into `.dotfiles` directory.

```powershell
git clone --bare 'https://github.com/RustyTake-Off/win-dotfiles.git' "$env:USERPROFILE\.dotfiles"
```

Checkout repo into 🏠 home directory.

```powershell
git --git-dir="$env:USERPROFILE\.dotfiles" --work-tree=$env:USERPROFILE checkout
```

Set git to not show untracked files.

```powershell
git --git-dir="$env:USERPROFILE\.dotfiles" --work-tree=$env:USERPROFILE config status.showUntrackedFiles no
```

Lastly run this script.

```powershell
pwsh "$env:USERPROFILE\.config\scripts\Set-Dotfiles.ps1"
```

Everything should be in place 🙂

### Updating

Updating 🔵 dotfiles is done by using a `dot function` which is already in the 🚰 PowerShell profile. Normally it would be an alias but for some reason the `Set-Alias` with this command doesn't work so it's easier to put it into a `function`.

```powershell
function dot {
    git --git-dir="$env:USERPROFILE\.dotfiles" --work-tree=$env:USERPROFILE $Args
}
```

To update dotfiles run:

```powershell
dot pull
```

Another way is to use the `Set-Dotfiles` script in admin terminal. In 🚰 PowerShell profile there is an `admin function` which auto opens admin terminal and runs passed command there.

```powershell
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
```

To use it, run this command:

```powershell
admin Set-Dotfiles.ps1
```
