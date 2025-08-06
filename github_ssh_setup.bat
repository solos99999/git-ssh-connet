@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo    GitHub SSH 连接配置工具
echo ========================================
echo.

:ask_new_connection
echo 是否需要新建 GitHub SSH 连接？
echo [Y] 是 - 创建新的 SSH 连接
echo [N] 否 - 跳过 SSH 配置，直接克隆仓库
echo [Q] 退出程序
echo.
set /p choice="请选择 (Y/N/Q): "

if /i "%choice%"=="Q" (
    echo 程序已退出。
    pause
    exit /b 0
)

if /i "%choice%"=="N" (
    goto clone_repo
)

if /i "%choice%"=="Y" (
    goto setup_ssh
)

echo 无效选择，请重新输入。
echo.
goto ask_new_connection

:setup_ssh
echo.
echo ========================================
echo    开始配置 SSH 密钥
echo ========================================

:: 检查 SSH 目录是否存在
if not exist "%USERPROFILE%\.ssh" (
    echo 创建 .ssh 目录...
    mkdir "%USERPROFILE%\.ssh"
)

:: 获取用户邮箱
echo.
set /p email="请输入您的 GitHub 邮箱地址: "
if "%email%"=="" (
    echo 邮箱地址不能为空！
    goto setup_ssh
)

:: 生成 SSH 密钥
echo.
echo 正在生成 SSH 密钥...
echo 密钥将保存在: %USERPROFILE%\.ssh\id_rsa
echo.

:: 检查是否已存在密钥
if exist "%USERPROFILE%\.ssh\id_rsa" (
    echo 检测到已存在 SSH 密钥。
    echo [Y] 覆盖现有密钥
    echo [N] 使用现有密钥
    set /p overwrite="请选择 (Y/N): "
    
    if /i "!overwrite!"=="N" (
        goto display_public_key
    )
)

:: 生成新密钥
ssh-keygen -t rsa -b 4096 -C "%email%" -f "%USERPROFILE%\.ssh\id_rsa" -N ""

if errorlevel 1 (
    echo 错误：SSH 密钥生成失败！
    echo 请确保已安装 Git 或 OpenSSH。
    pause
    exit /b 1
)

echo SSH 密钥生成成功！

:display_public_key
echo.
echo ========================================
echo    SSH 公钥内容
echo ========================================
echo.
echo 以下是您的 SSH 公钥内容，请复制并添加到 GitHub：
echo.
echo ----------------------------------------
type "%USERPROFILE%\.ssh\id_rsa.pub"
echo ----------------------------------------
echo.

:github_instructions
echo ========================================
echo    GitHub 网站操作指南
echo ========================================
echo.
echo 请按照以下步骤在 GitHub 网站上添加 SSH 密钥：
echo.
echo 1. 打开浏览器，访问 https://github.com
echo 2. 登录您的 GitHub 账户
echo 3. 点击右上角头像，选择 "Settings"
echo 4. 在左侧菜单中选择 "SSH and GPG keys"
echo 5. 点击 "New SSH key" 按钮
echo 6. 在 "Title" 中输入一个描述性名称（如：我的电脑）
echo 7. 将上面显示的公钥内容完整复制到 "Key" 文本框中
echo 8. 点击 "Add SSH key" 按钮完成添加
echo.

echo 正在启动浏览器打开 GitHub SSH 设置页面...
start https://github.com/settings/ssh/new

echo.
echo 完成上述操作后，按任意键继续...
pause >nul

:test_connection
echo.
echo ========================================
echo    测试 SSH 连接
echo ========================================
echo.
echo 正在测试与 GitHub 的 SSH 连接...

:: 启动 ssh-agent
echo 启动 SSH agent...
start /b ssh-agent

:: 添加密钥到 ssh-agent
ssh-add "%USERPROFILE%\.ssh\id_rsa"

:: 测试连接
echo 测试连接到 GitHub...
ssh -T git@github.com

if errorlevel 1 (
    echo.
    echo 警告：SSH 连接测试可能失败。
    echo 这可能是因为：
    echo 1. SSH 密钥尚未添加到 GitHub
    echo 2. 网络连接问题
    echo 3. SSH 配置问题
    echo.
    echo 是否继续进行仓库克隆？
    echo [Y] 是 - 继续
    echo [N] 否 - 退出程序
    set /p continue_choice="请选择 (Y/N): "
    
    if /i "!continue_choice!"=="N" (
        echo 程序已退出。
        pause
        exit /b 0
    )
) else (
    echo SSH 连接测试成功！
)

:clone_repo
echo.
echo ========================================
echo    克隆 GitHub 仓库
echo ========================================
echo.

set /p repo_url="请输入要克隆的 GitHub 仓库 SSH URL (例: git@github.com:username/repository.git): "

if "%repo_url%"=="" (
    echo 仓库 URL 不能为空！
    goto clone_repo
)

:: 验证 URL 格式
echo %repo_url% | findstr /r "^git@github\.com:" >nul
if errorlevel 1 (
    echo 警告：输入的 URL 格式可能不正确。
    echo 正确格式应为: git@github.com:username/repository.git
    echo.
    echo 是否继续？
    echo [Y] 是 - 继续克隆
    echo [N] 否 - 重新输入
    set /p format_choice="请选择 (Y/N): "
    
    if /i "!format_choice!"=="N" (
        goto clone_repo
    )
)

:: 询问克隆目录
echo.
set /p clone_dir="请输入克隆到的本地目录路径 (留空则克隆到当前目录): "

if "%clone_dir%"=="" (
    set clone_dir=%cd%
)

:: 检查目录是否存在
if not exist "%clone_dir%" (
    echo 目录不存在，正在创建: %clone_dir%
    mkdir "%clone_dir%" 2>nul
    if errorlevel 1 (
        echo 错误：无法创建目录 %clone_dir%
        pause
        exit /b 1
    )
)

echo.
echo 正在克隆仓库...
echo 源: %repo_url%
echo 目标: %clone_dir%
echo.

cd /d "%clone_dir%"
git clone "%repo_url%"

if errorlevel 1 (
    echo.
    echo 错误：仓库克隆失败！
    echo 可能的原因：
    echo 1. SSH 密钥配置不正确
    echo 2. 仓库 URL 错误
    echo 3. 网络连接问题
    echo 4. 没有访问该仓库的权限
    echo.
    pause
    exit /b 1
) else (
    echo.
    echo ========================================
    echo    操作完成！
    echo ========================================
    echo.
    echo 仓库已成功克隆到: %clone_dir%
    echo.
    
    :: 显示克隆的目录内容
    echo 克隆的内容：
    dir /b "%clone_dir%"
    echo.
)

:end
echo 所有操作已完成！
echo.
echo 如果您遇到任何问题，请检查：
echo 1. Git 是否正确安装
echo 2. SSH 密钥是否正确添加到 GitHub
echo 3. 网络连接是否正常
echo 4. 仓库 URL 是否正确
echo.
pause
exit /b 0