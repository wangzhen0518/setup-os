#------------------------------- Import Modules BEGIN -------------------------------
# 引入 posh-git
Import-Module posh-git

# 引入 ps-read-line
Import-Module PSReadLine
Import-Module Dircolors

oh-my-posh init pwsh --config "${env:POSH_THEMES_PATH}/my-theme.omp.json" | Invoke-Expression

#------------------------------- Import Modules END   -------------------------------


#-------------------------------  Set Hot-keys BEGIN  -------------------------------
# 设置预测文本来源为历史记录
Set-PSReadLineOption -PredictionSource History

# 每次回溯输入历史，光标定位于输入内容末尾
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# 设置 Tab 为菜单补全和 Intellisense
Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete

# 设置 Ctrl+d 为退出 PowerShell
Set-PSReadlineKeyHandler -Key "Ctrl+d" -Function ViExit

# 设置 Ctrl+z 为撤销
Set-PSReadLineKeyHandler -Key "Ctrl+z" -Function Undo

# 设置向上键为后向搜索历史记录
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward

# 设置向下键为前向搜索历史纪录
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
#-------------------------------  Set Hot-keys END    -------------------------------


#-------------------------------   Set Alias BEGIN    -------------------------------

Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name touch -Value New-Item

#-------------------------------    Set Alias END     -------------------------------


#-------------------------------    Set Scoop BEGIN     -----------------------------
Invoke-Expression (&scoop-search --hook)
#-------------------------------    Set Scoop END     -------------------------------


#-------------------------------   Set Network BEGIN    -------------------------------
function ssh-copy-id([string]$userAtMachine, $args){   
    $publicKey = "$ENV:USERPROFILE" + "/.ssh/id_rsa.pub"
    if (!(Test-Path "$publicKey")){
        Write-Error "ERROR: failed to open ID file '$publicKey': No such file"            
    }
    else {
        & cat "$publicKey" | ssh $args $userAtMachine "umask 077; test -d .ssh || mkdir .ssh ; cat >> .ssh/authorized_keys || exit 1"      
    }
}
#-------------------------------   Set Network END  ----------------------------------

Import-Module -Name Microsoft.WinGet.CommandNotFound

#-------------------------------   Set Node Begin  ----------------------------------

#fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

#-------------------------------   Set Node End  ----------------------------------

