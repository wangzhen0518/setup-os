Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

Copy-Item $PSScriptRoot/../config/git/.gitconfig ~/.gitconfig

scoop install git 7zip dark innounp
scoop update
scoop bucket add extras nerd-fonts java

conda activate base
python .\script\01-scoop-install-apps.py
