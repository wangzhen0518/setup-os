# set shell := ['./bin/nu/nu.exe', '-m', 'light', '-c']

set shell := ['./bin/nu/nu.exe', '-c']
set dotenv-required := true
set dotenv-load := true

python := "./.venv/Scripts/python.exe"
pwsh := "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -c"

default: portable v2rayN windows ssh git scoop vscode visual-studio wget go nodejs python rust nushell

# ------------------------ portable ------------------------
portable:
    mkdir C:/Software
    cp -r ./Portable C:/Software

# ------------------------ v2rayN ------------------------
v2rayN: portable
    C:/Software/Portable/v2rayN-windows-64/v2rayN.exe

# ------------------------ windows ------------------------
activate-windows: v2rayN
    pwsh "irm https://get.activated.win | iex"

windows-env:
    let env_vars = open ./config/windows/env.json; \
    $env_vars | items {|key, value| \
        let cmd = $"[Environment]::SetEnvironmentVariable\(\"($key)\", \"($value)\", "User"\)"; \
        print cmd; \
         pwsh cmd \
    }

    let env_vars = open ./config/windows/secret-env.json; \
    $env_vars | items {|key, value| \
        let cmd = $"[Environment]::SetEnvironmentVariable\(\"($key)\", \"($value)\", "User"\)"; \
        print cmd; \
         pwsh cmd \
    }

windows-path: nushell
    pwsh '[Environment]::SetEnvironmentVariable("PATH", ([Environment]::GetEnvironmentVariable("PATH", "User") + ";$HOME/.local/bin"), "User")'

windows-right-click:
    pwsh 'reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve'

windows-change-directory-path:
    ["Desktop", "Downloads", "Documents", "Pictures", "Music", "Videos"] | each { |folder| \
        let cmd = $'reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v ($folder) /t REG_EXPAND_SZ /d "D:\($folder)" /f'; \
        pwsh $cmd; \
    }

windows: activate-windows windows-env windows-path windows-right-click windows-change-directory-path powershell terminal

# ------------------------ powershell ------------------------
powershell: install-scoop
    winget install --id Microsoft.PowerShell --source winget
    scoop install oh-my-posh
    cp ./config/powershell/my-theme.omp.json $env.POSH_THEMES_PATH
    cp ./config/powershell/Microsoft.PowerShell_profile.ps1 D:/Documents/PowerShell/Microsoft.PowerShell_profile.ps1

# ------------------------ terminal ------------------------
terminal:
    let terminal_dir = ( pwsh "Get-AppxPackage Microsoft.WindowsTerminal | Select-Object -ExpandProperty InstallLocation" | lines | get 0); \
    let cfg_file = $terminal_dir | path join LocalState settings.json; \
    cp ./config/windows/windows-terminal-settings.json $cfg_file

# ------------------------ ssh ------------------------
config-ssh:
    mkdir ~/.ssh
    cp ./config/.ssh/* ~/.ssh/
    ssh-keygen.exe -t rsa

upload-ssh-pubkey-github: config-ssh v2rayN
    let key_content = (open ~/.ssh/id_rsa.pub | str trim); \
    http post "https://api.github.com/user/keys" \
        -H {Authorization: $"Bearer ($env.UPLOAD_SSHKEY_TOKEN)"} \
        --content-type application/json \
        { title: $env.TITLE, key: $key_content }

upload-ssh-pubkey: config-ssh config-nushell
    ssh-copy-id mira
    ssh-copy-id 03G
    ssh-copy-id 07G

ssh: config-ssh upload-ssh-pubkey-github upload-ssh-pubkey

# ------------------------ git ------------------------
install-git: install-scoop

config-git:
    cp ./git/.gitconfig ~/.gitconfig

git: install-git config-git

# ------------------------ scoop ------------------------
install-scoop: windows-env v2rayN
    pwsh "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
    pwsh "Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression"
    scoop install git 7zip dark innounp

scoop-install-apps: install-scoop git upload-ssh-pubkey-github v2rayN
    scoop update
    scoop bucket add extras nerd-fonts java
    let data = open ./config/scoop/scoop-apps.toml; \
    scoop install ...($data.basic); \
    scoop hold ...($data.hold)

scoop: install-scoop scoop-install-apps

# ------------------------ vscode ------------------------
vscode: scoop
    code

# ------------------------ visual studio ------------------------
visual-studio:
    wget https://c2rsetup.officeapps.live.com/c2r/downloadVS.aspx?sku=community&channel=stable&version=VS18&source=VSLandingPage&cid=2500:f4ff660300234088b3a3ae98f4df2704 -O $env.TMP/VisualStudioSetup.exe
    $env.TMP/VisualStudioSetup.exe

# ------------------------ wget ------------------------
wget: scoop

# ------------------------ go ------------------------
install-go: scoop

config-go: install-go
    go env -w GO111MODULE=on
    go env -w GOPROXY=https://mirrors.aliyun.com/goproxy/,direct

go: install-go config-go

# ------------------------ nodejs ------------------------
install-nodejs: scoop

config-nodejs: install-nodejs
    nvm install lts
    nvm use lts
    corepack enable pnpm
    npm config -g set registry https://mirrors.cloud.tencent.com/npm/
    pnpm config -g set registry https://mirrors.cloud.tencent.com/npm/
    mkdir D:/Software/Developer
    pnpm config set store-dir D:/Software/Developer/nodejs/.pnpm-store

nodejs: install-nodejs config-nodejs

# ------------------------ uv ------------------------
uv: scoop windows-env
    uv tool install ruff ty

# ------------------------ conda ------------------------
install-conda: wget
    wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Windows-x86_64.exe -O $env.TMP/Miniconda3-latest-Windows-x86_64.exe
    $env.TMP/Miniconda3-latest-Windows-x86_64.exe

config-conda: install-conda nushell
    let conda_dir = (conda info --system --json | from json).conda_prefix
    cp ./config/conda/.condarc $conda_dir
    conda activate base; \
    conda update --all -y

config-pip: install-conda nushell
    conda activate base
    pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple

conda-base-env: config-pip
    conda activate base; \
    pip install jupyter notebook polars ipython pandas numpy scipy matplotlib tqdm

conda-dl-env: config-conda nushell
    conda create -n dl python=3.13
    conda activate dl; \
    uv pip install torch torchvision torchaudio --torch-backend=auto; \
    uv pip install transformers jupyter notebook polars ipython pandas numpy scipy matplotlib tqdm

conda: install-conda config-conda config-pip conda-base-env conda-dl-env

python: conda uv

# ------------------------ rust ------------------------
install-rust: wget visual-studio windows-env
    wget https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe -O $env.TMP/rustup-init.exe
    $env.TMP/rustup-init.exe

config-rust: install-rust
    cp ./config/rust/*.toml $env.CARGO_HOME

cargo-install-apps: config-rust
    cargo install cargo-binstall
    let apps = open ./config/rust/cargo-list.json; \
    cargo binstall -y ...($apps)

rustup-add-targets: config-rust
    rustup target add wasm32-unknown-unknown

rust: install-rust config-rust cargo-install-apps rustup-add-targets

# ------------------------ nushell ------------------------
install-nushell: scoop

config-nushell: install-nushell
    cp ./config/nushell/*.nu $nu.data-dir
    cp -r ./config/nushell/nu_scripts $nu.data-dir
    cp ./config/nushell/nushell.png ($nu.current-exe | path dirname)
    source $nu.env-path
    source $nu.config-path
    plugin add nu_plugin_example.exe
    plugin add nu_plugin_formats.exe
    plugin add nu_plugin_gstat.exe
    plugin add nu_plugin_inc.exe
    plugin add nu_plugin_polars.exe
    plugin add nu_plugin_query.exe
    plugin add nu_plugin_stress_internals.exe

nushell: install-nushell config-nushell
