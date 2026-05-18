# CC Switch (OpenCode Fix Fork) - Release Checklist

Every time you want to publish a new version, follow this checklist.

---

## 1. Bump Version Number

Update the version in **both** files (they must match):

- [ ] `package.json` → `"version": "x.y.z"`
- [ ] `src-tauri/tauri.conf.json` → `"version": "x.y.z"`

Commit the version bump:
```bash
git add package.json src-tauri/tauri.conf.json
git commit -m "release: vX.Y.Z"
git push
```

## 2. Build & Sign

Run the build script (ensure `.tauri/cc-switch.key` private key exists):

```bash
build.bat
```

Build artifacts will be at:
```
src-tauri/target/release/bundle/
├── msi/
│   ├── CC Switch_x.y.z_x64_en-US.msi
│   └── CC Switch_x.y.z_x64_en-US.msi.sig    ← signature file
└── nsis/
    ├── CC Switch_x.y.z_x64-setup.exe
    └── CC Switch_x.y.z_x64-setup.exe.sig     ← signature file
```

## 3. Create `latest.json`

Read the content of the `.msi.sig` file and fill in the template below.

> **Tip:** Run `type "src-tauri\target\release\bundle\msi\CC Switch_x.y.z_x64_en-US.msi.sig"` to get the signature content.

```json
{
  "version": "x.y.z",
  "notes": "Release notes here",
  "pub_date": "2026-01-01T00:00:00Z",
  "platforms": {
    "windows-x86_64": {
      "signature": "PASTE_THE_CONTENT_OF_.msi.sig_HERE",
      "url": "https://github.com/JzmStudio/cc-switch-opencode-fix/releases/download/vx.y.z/CC.Switch_x.y.z_x64_en-US.msi"
    }
  }
}
```

**Important notes:**
- `version` must match the version in `tauri.conf.json` (without the `v` prefix)
- `pub_date` must be a valid ISO 8601 timestamp
- `url` must match the exact filename uploaded to GitHub Releases (spaces in filenames become `.` in GitHub download URLs)
- `signature` is the full content of the `.msi.sig` file

## 4. Create GitHub Release

1. Go to https://github.com/JzmStudio/cc-switch-opencode-fix/releases/new
2. Create a new tag: `vx.y.z`
3. Set release title: `vx.y.z`
4. Write release notes (what changed)
5. Upload these files as release assets:
   - [ ] `CC Switch_x.y.z_x64_en-US.msi` (installer)
   - [ ] `CC Switch_x.y.z_x64_en-US.msi.sig` (signature)
   - [ ] `latest.json` (updater manifest)
6. Publish the release

## 5. Verify

After publishing, verify the updater endpoint works:

```
https://github.com/JzmStudio/cc-switch-opencode-fix/releases/latest/download/latest.json
```

This URL should return your `latest.json` content.
