@echo off
chcp 65001 >nul 2>&1

echo ============================================
echo   CC Switch Build Script
echo ============================================
echo.

:: ---- 项目根目录 ----
cd /d "%~dp0"

:: ---- 检查 Rust ----
echo [1/4] 检查 Rust 工具链...
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
echo [2/4] 检查 Node.js 和 pnpm...
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
echo [3/4] 设置更新签名密钥...
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

:: ---- 安装依赖 ----
echo [4/4] 开始编译...
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

echo.
echo ============================================
echo   编译成功!
echo ============================================
echo.
echo 编译产物位置:
echo   EXE:    %~dp0src-tauri\target\release\cc-switch.exe
echo   安装包: %~dp0src-tauri\target\release\bundle\
echo.
goto :done

:fail
echo.
echo ============================================
echo   编译失败，请检查上方错误信息
echo ============================================

:done
echo.
echo 窗口保持打开，可查看上方日志。按任意键关闭...
pause >nul
