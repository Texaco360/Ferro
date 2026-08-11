# Install HashLoad Boss on macOS

This guide installs the HashLoad Boss CLI for the current user (no sudo required).

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
