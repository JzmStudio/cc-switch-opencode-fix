# CC Switch (OpenCode Fix Fork) - 发版清单

每次发布新版本时，按照以下清单逐步执行。

---

## 1. 升级版本号

同时更新以下 **两个** 文件中的版本号（必须保持一致）：

- [ ] `package.json` → `"version": "x.y.z"`
- [ ] `src-tauri/tauri.conf.json` → `"version": "x.y.z"`

提交版本号变更：
```bash
git add package.json src-tauri/tauri.conf.json
git commit -m "release: vX.Y.Z"
git push
```

## 2. 编译 & 签名

运行编译脚本（确保 `.tauri/cc-switch.key` 私钥文件存在）：

```bash
build.bat
```

编译产物位于：
```
src-tauri/target/release/bundle/
├── msi/
│   ├── CC Switch_x.y.z_x64_en-US.msi
│   └── CC Switch_x.y.z_x64_en-US.msi.sig    ← 签名文件
└── nsis/
    ├── CC Switch_x.y.z_x64-setup.exe
    └── CC Switch_x.y.z_x64-setup.exe.sig     ← 签名文件
```

## 3. 创建 `latest.json`

读取 `.msi.sig` 文件的内容，填入下方模板。

> **提示：** 执行 `type "src-tauri\target\release\bundle\msi\CC Switch_x.y.z_x64_en-US.msi.sig"` 可以获取签名内容。

```json
{
  "version": "x.y.z",
  "notes": "在这里填写更新说明",
  "pub_date": "2026-01-01T00:00:00Z",
  "platforms": {
    "windows-x86_64": {
      "signature": "将 .msi.sig 文件的内容粘贴到这里",
      "url": "https://github.com/JzmStudio/cc-switch-opencode-fix/releases/download/vx.y.z/CC.Switch_x.y.z_x64_en-US.msi"
    }
  }
}
```

**注意事项：**
- `version` 必须与 `tauri.conf.json` 中的版本号一致（不带 `v` 前缀）
- `pub_date` 必须是合法的 ISO 8601 时间戳
- `url` 必须与上传到 GitHub Releases 的文件名完全匹配（文件名中的空格在 GitHub 下载链接中会变成 `.`）
- `signature` 是 `.msi.sig` 文件的完整内容

## 4. 创建 GitHub Release

1. 打开 https://github.com/JzmStudio/cc-switch-opencode-fix/releases/new
2. 创建新标签：`vx.y.z`
3. 设置 Release 标题：`vx.y.z`
4. 填写更新日志（本次变更内容）
5. 上传以下文件作为 Release 附件：
   - [ ] `CC Switch_x.y.z_x64_en-US.msi`（安装包）
   - [ ] `CC Switch_x.y.z_x64_en-US.msi.sig`（签名文件）
   - [ ] `latest.json`（更新清单）
6. 点击发布

## 5. 验证

发布后，访问以下链接验证更新端点是否正常工作：

```
https://github.com/JzmStudio/cc-switch-opencode-fix/releases/latest/download/latest.json
```

该链接应返回你上传的 `latest.json` 内容。
