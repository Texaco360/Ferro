# Install HashLoad Boss on macOS

This guide installs the HashLoad Boss CLI for the current user (no sudo required).

---

# Install HashLoad Boss on Windows

This guide installs the HashLoad Boss CLI for the current user (no admin required).

## 1. Pick the correct binary

- Most PCs (Intel/AMD 64-bit): `boss_Windows_x86_64.zip`
- ARM-based Windows: `boss_Windows_arm64.zip`
- Older 32-bit systems: `boss_Windows_i386.zip`

## 2. Download and extract (PowerShell)

Set `$arch` to one of `x86_64`, `arm64`, or `i386`.

```powershell
$arch = "x86_64"
$zip = "boss_Windows_$arch.zip"
$url = "https://github.com/HashLoad/boss/releases/latest/download/$zip"

$temp = Join-Path $env:TEMP "boss-install"
$extract = Join-Path $temp "extract"
New-Item -ItemType Directory -Force -Path $extract | Out-Null

Invoke-WebRequest -Uri $url -OutFile (Join-Path $temp $zip)
Expand-Archive -Path (Join-Path $temp $zip) -DestinationPath $extract -Force
```

## 3. Install into your user bin

```powershell
$binDir = Join-Path $HOME ".local\bin"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null
Copy-Item (Join-Path $extract "boss.exe") (Join-Path $binDir "boss.exe") -Force
Unblock-File (Join-Path $binDir "boss.exe")
```

## 4. Add Boss to PATH (one time)

```powershell
$binDir = Join-Path $HOME ".local\bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")

if (($userPath -split ";") -notcontains $binDir) {
	[Environment]::SetEnvironmentVariable("Path", "$userPath;$binDir", "User")
}

# Refresh PATH for the current shell session
$env:Path = [Environment]::GetEnvironmentVariable("Path", "User") + ";" + [Environment]::GetEnvironmentVariable("Path", "Machine")
```

If `boss` is still not found after this step, close and reopen PowerShell.

## 5. Verify installation

```powershell
Get-Command boss
boss --version
```

Expected output includes a Boss CLI version line.

## Upgrade later

Run the same download + extract + install steps again to replace the existing binary.

---

## 1. Pick the correct binary

- Apple Silicon (M1/M2/M3): `boss_Darwin_arm64.tar.gz`
- Intel Mac: `boss_Darwin_x86_64.tar.gz`

## 2. Download and extract

### Apple Silicon

```bash
curl -fL -o boss_Darwin_arm64.tar.gz https://github.com/HashLoad/boss/releases/latest/download/boss_Darwin_arm64.tar.gz
mkdir -p boss-install-tmp
tar -xzf boss_Darwin_arm64.tar.gz -C boss-install-tmp
```

### Intel

```bash
curl -fL -o boss_Darwin_x86_64.tar.gz https://github.com/HashLoad/boss/releases/latest/download/boss_Darwin_x86_64.tar.gz
mkdir -p boss-install-tmp
tar -xzf boss_Darwin_x86_64.tar.gz -C boss-install-tmp
```

## 3. Install into your user bin

```bash
mkdir -p "$HOME/.local/bin"
install -m 0755 boss-install-tmp/boss "$HOME/.local/bin/boss"
```

## 4. Add Boss to PATH (zsh)

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
source "$HOME/.zshrc"
```

If you already have that line in your `~/.zshrc`, do not add it again.

## 5. Verify installation

```bash
command -v boss
boss --version
```

Expected output includes a Boss CLI version line.

## Upgrade later

Run the same download + extract + install steps again to replace the existing binary.
