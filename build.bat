@echo off
chcp 65001 >nul 2>&1

echo ============================================
echo   CC Switch Build Script
echo ============================================
echo.

:: ---- 项目根目录 ----
cd /d "%~dp0"

:: ---- 检查 Rust ----
echo [1/5] 检查 Rust 工具链...
set "PATH=%USERPROFILE%\.cargo\bin;%PATH%"
where rustc >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] 未找到 rustc，请先安装 Rust: https://rustup.rs
    goto :fail
)
for /f "delims=" %%v in ('rustc --version') do echo   %%v
for /f "delims=" %%v in ('cargo --version') do echo   %%v
echo.

:: ---- 检查 Node.js / pnpm ----
echo [2/5] 检查 Node.js 和 pnpm...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] 未找到 Node.js，请先安装: https://nodejs.org
    goto :fail
)
where pnpm >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] 未找到 pnpm，请运行: npm install -g pnpm
    goto :fail
)
for /f "delims=" %%v in ('node --version') do echo   Node.js %%v
for /f "delims=" %%v in ('pnpm --version') do echo   pnpm %%v
echo.

:: ---- 设置签名密钥 ----
echo [3/5] 设置更新签名密钥...
set "PRIVATE_KEY_FILE=%~dp0.tauri\cc-switch.key"

if not exist "%PRIVATE_KEY_FILE%" (
    echo [WARN] 未找到私钥文件: %PRIVATE_KEY_FILE%
    echo [WARN] 将跳过更新签名
    echo.
) else (
    echo   找到私钥文件: %PRIVATE_KEY_FILE%
    for /f "usebackq delims=" %%i in ("%PRIVATE_KEY_FILE%") do set "TAURI_SIGNING_PRIVATE_KEY=%%i"
    set "TAURI_SIGNING_PRIVATE_KEY_PASSWORD="
    echo   签名密钥已设置
    echo.
)

:: ---- 清理旧的 bundle 产物 ----
echo [4/5] 清理旧的构建产物...
set "BUNDLE_DIR=%~dp0src-tauri\target\release\bundle"
if exist "%BUNDLE_DIR%" (
    rmdir /s /q "%BUNDLE_DIR%"
    echo   已清理 bundle 目录
) else (
    echo   bundle 目录不存在，跳过清理
)
echo.

:: ---- 安装依赖 ----
echo [5/5] 开始编译...
echo.
echo --- 安装前端依赖 ---
call pnpm install
if %errorlevel% neq 0 (
    echo [ERROR] pnpm install 失败
    goto :fail
)
echo.

:: ---- 编译 ----
echo --- 编译 Tauri 应用（首次编译较慢，请耐心等待）---
call pnpm build
if %errorlevel% neq 0 (
    echo [ERROR] 编译失败
    goto :fail
)

:: ---- 生成 latest.json ----
echo.
echo --- 生成 latest.json ---
call :generate_latest_json
if %errorlevel% neq 0 (
    echo [WARN] latest.json 生成失败，请手动检查
)

echo.
echo ============================================
echo   编译成功!
echo ============================================
echo.
echo 编译产物位置:
echo   EXE:    %~dp0src-tauri\target\release\cc-switch.exe
echo   安装包: %~dp0src-tauri\target\release\bundle\
echo   更新文件: %~dp0src-tauri\target\release\bundle\latest.json
echo.
goto :done

:: ============================================
:: 子程序：生成 latest.json
:: ============================================
:generate_latest_json
setlocal enabledelayedexpansion

:: 从 tauri.conf.json 中读取版本号
set "TAURI_CONF=%~dp0src-tauri\tauri.conf.json"
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "(Get-Content '%TAURI_CONF%' | ConvertFrom-Json).version"`) do set "APP_VERSION=%%a"

if "%APP_VERSION%"=="" (
    echo [ERROR] 无法从 tauri.conf.json 读取版本号
    exit /b 1
)
echo   版本号: %APP_VERSION%

:: 获取 git 最近一次 commit 的信息作为 notes
for /f "usebackq delims=" %%a in (`git log -1 --pretty^=format:%%s 2^>nul`) do set "GIT_NOTES=%%a"
if "%GIT_NOTES%"=="" set "GIT_NOTES=v%APP_VERSION%"
echo   Release notes: %GIT_NOTES%

:: 获取当前 UTC 时间
for /f "usebackq delims=" %%a in (`powershell -NoProfile -Command "(Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')"`) do set "PUB_DATE=%%a"

:: 查找 MSI 签名文件
set "MSI_SIG_FILE=%BUNDLE_DIR%\msi\CC Switch_%APP_VERSION%_x64_en-US.msi.sig"
if not exist "%MSI_SIG_FILE%" (
    echo [ERROR] 未找到 MSI 签名文件: %MSI_SIG_FILE%
    echo [WARN] 将使用 Tauri 自动生成的 latest.json
    exit /b 1
)

:: 读取签名内容
for /f "usebackq delims=" %%s in ("%MSI_SIG_FILE%") do set "MSI_SIGNATURE=%%s"
echo   MSI 签名已读取

:: GitHub Release 下载 URL
set "REPO_URL=https://github.com/JzmStudio/cc-switch-opencode-fix/releases/download/v%APP_VERSION%"
set "MSI_URL=%REPO_URL%/CC.Switch_%APP_VERSION%_x64_en-US.msi"

:: 用 PowerShell 生成 JSON（避免 bat 中处理特殊字符的问题）
set "LATEST_JSON=%BUNDLE_DIR%\latest.json"
powershell -NoProfile -Command ^
    "$json = @{" ^
    "    version = '%APP_VERSION%';" ^
    "    notes = '%GIT_NOTES%';" ^
    "    pub_date = '%PUB_DATE%';" ^
    "    platforms = @{" ^
    "        'windows-x86_64' = @{" ^
    "            signature = '%MSI_SIGNATURE%';" ^
    "            url = '%MSI_URL%'" ^
    "        }" ^
    "    }" ^
    "};" ^
    "$text = $json | ConvertTo-Json -Depth 4;" ^
    "$utf8 = New-Object System.Text.UTF8Encoding($false);" ^
    "[System.IO.File]::WriteAllText('%LATEST_JSON%', $text, $utf8)"

if %errorlevel% neq 0 (
    echo [ERROR] latest.json 写入失败
    exit /b 1
)

echo   latest.json 已生成: %LATEST_JSON%

:: 验证生成的签名是否与当前版本匹配
powershell -NoProfile -Command ^
    "$sig = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('%MSI_SIGNATURE%'));" ^
    "if ($sig -match 'file:CC Switch_%APP_VERSION%') { Write-Host '  签名验证通过: 文件名与版本号匹配' }" ^
    "else { Write-Host '[WARN] 签名中的文件名与当前版本不匹配，请检查！' -ForegroundColor Yellow }"

endlocal
exit /b 0

:fail
echo.
echo ============================================
echo   编译失败，请检查上方错误信息
echo ============================================

:done
echo.
echo 窗口保持打开，可查看上方日志。按任意键关闭...
pause >nul
