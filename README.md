# FerroServer

## Setup

- Boss install guide: [INSTALL_BOSS.md](INSTALL_BOSS.md)

## Windows Usage

After installing Boss and Free Pascal, run:

```powershell
boss install
scripts\windows.bat build
scripts\windows.bat run
```

Windows runtime note:

- This app requires sqlite3.dll on Windows.
- Place sqlite3.dll in the repository root, or set SQLITE3_DLL to its absolute path.
- The script copies it into build output folders automatically.
- To auto-download the required Win32 DLL, run `scripts\windows.bat fetch-sqlite`.

Other common commands:

```powershell
scripts\windows.bat test
scripts\windows.bat migrate --status
scripts\windows.bat clean
```

Show all supported commands:

```powershell
scripts\windows.bat help
```

## Documentation

- Architecture guide: [ARCHITECTURE.md](ARCHITECTURE.md)
