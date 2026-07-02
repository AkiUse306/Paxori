# Paxori Release Notes

## 1.0.0

This release introduces the first packaged distribution of Paxori with platform-specific installer assets:

- `paxori-1.0.0-windows.msi`
  - Windows MSI installer for standard setup flow
  - Supports installation into `C:\Program Files\Paxori`
  - Includes uninstall metadata

- `paxori-1.0.0-macos.dmg`
  - macOS disk image package for drag-and-drop installation
  - Recommended install experience for macOS users

- `paxori-1.0.0-linux.tar.gz`
  - Linux tarball archive for manual extraction
  - Ideal for Linux distributions without native package support

- `paxori-1.0.0-x86_64.AppImage`
  - Portable Linux AppImage
  - Run directly after setting executable permissions

## Usage

### Windows
- Open the downloaded MSI and follow the installer prompts
- Or use the PowerShell installer for a more automated flow:
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/AkiUse306/Paxori/main/install.ps1 | iex"
  ```

### macOS
- Open the `.dmg` and drag Paxori into the Applications folder
- If a shell installer is available, use `bash install.sh`

### Linux
- Extract the `.tar.gz` and run the app from the extracted folder
- Or use the AppImage directly:
  ```bash
  chmod +x paxori-1.0.0-x86_64.AppImage
  ./paxori-1.0.0-x86_64.AppImage
  ```

## Release management

- This release was published with GitHub CLI using `gh release create` and is now live as tag `1.0.0`.
- To update the release notes, edit this file and then run:
  ```bash
  gh release edit 1.0.0 --notes-file RELEASE_NOTES.md
  ```
- To add or replace assets:
  ```bash
  gh release upload 1.0.0 <asset-file> --clobber
  ```

## Notes for editing

- If you change the packaging or add new installers, update these release notes and create a new release tag.
- Keep the release asset names consistent with the version and platform.
- When updating the GitHub Pages site, make sure the release notes reflect the latest published installer assets.
