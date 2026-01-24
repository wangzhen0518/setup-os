import winreg
import ctypes
import os
import sys
import argparse
import json
from typing import Optional, List

def get_user_env(name: str) -> Optional[str]:
    """
    获取用户环境变量
    返回: 环境变量值，如果不存在则返回 None
    """
    try:
        reg_key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            'Environment',  # 注意：这是用户环境变量
            0, 
            winreg.KEY_READ
        )
        value, _ = winreg.QueryValueEx(reg_key, name)
        winreg.CloseKey(reg_key)
        return value
    except FileNotFoundError:
        return None
    except Exception as e:
        print(f"读取环境变量时出错: {e}")
        return None

def set_user_env(name: str, value: str) -> bool:
    """
    设置用户环境变量
    注意：新值会立即在注册表中更新，但已运行的程序需要重启才能看到
    """
    try:
        reg_key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            'Environment',  # 注意：这是用户环境变量
            0, 
            winreg.KEY_SET_VALUE | winreg.KEY_QUERY_VALUE
        )
        
        # 使用 REG_EXPAND_SZ 以支持 %VARIABLE% 扩展
        winreg.SetValueEx(reg_key, name, 0, winreg.REG_EXPAND_SZ, value)
        winreg.CloseKey(reg_key)
        
        # 通知系统环境变量已更改
        _notify_environment_changed()
        
        print(f"✅ 已成功设置用户环境变量: {name}={value}")
        return True
        
    except Exception as e:
        print(f"❌ 设置环境变量时出错: {e}")
        return False

def _notify_environment_changed():
    """
    向系统发送环境变量已更改的消息
    这会使新环境变量在已运行的程序中部分可见
    """
    try:
        # 向系统发送环境变量已更改的消息
        HWND_BROADCAST = 0xFFFF
        WM_SETTINGCHANGE = 0x001A
        SMTO_ABORTIFHUNG = 0x0002
        
        ctypes.windll.user32.SendMessageTimeoutW(
            HWND_BROADCAST, 
            WM_SETTINGCHANGE, 
            0,  # 无wParam
            'Environment',  # 系统应重新加载环境
            SMTO_ABORTIFHUNG, 
            100,  # 超时100ms
            None
        )
    except Exception as e:
        # 这个错误不关键，可以继续
        pass

def get_user_path() -> str:
    """
    获取用户PATH环境变量
    如果不存在，则返回空字符串
    """
    return get_user_env("Path") or ""

def append_to_user_path(new_path: str) -> bool:
    """
    向用户PATH环境变量添加新路径
    会检查是否已存在，避免重复
    """
    # 确保路径以反斜杠结束
    if not new_path.endswith("\\") and not new_path.endswith("/"):
        new_path = new_path + "\\"
    
    # 获取当前PATH
    current_path = get_user_path()
    
    if not current_path:
        # 如果PATH为空，直接设置
        return set_user_env("Path", new_path)
    
    # 分割并清理现有路径
    existing_paths = [p.strip() for p in current_path.split(';') if p.strip()]
    
    # 检查是否已存在
    for path in existing_paths:
        # 标准化路径比较
        if path.rstrip('\\/').lower() == new_path.rstrip('\\/').lower():
            print(f"⚠️ 路径已存在于用户PATH中: {new_path}")
            return True
    
    # 添加新路径
    updated_path = f"{current_path};{new_path}"
    return set_user_env("Path", updated_path)

def remove_from_user_path(path_to_remove: str) -> bool:
    """
    从用户PATH环境变量中移除路径
    """
    current_path = get_user_path()
    if not current_path:
        print("❌ 用户PATH为空")
        return False
    
    # 标准化要移除的路径
    path_to_remove = path_to_remove.rstrip('\\/')
    
    # 分割并过滤
    paths = [p.strip() for p in current_path.split(';') if p.strip()]
    filtered_paths = []
    
    removed = False
    for path in paths:
        if path.rstrip('\\/').lower() != path_to_remove.lower():
            filtered_paths.append(path)
        else:
            removed = True
    
    if not removed:
        print(f"⚠️ 路径不在用户PATH中: {path_to_remove}")
        return False
    
    # 重新组合
    updated_path = ';'.join(filtered_paths)
    return set_user_env("Path", updated_path)

def list_user_env_variables() -> dict:
    """
    列出所有用户环境变量
    """
    env_vars = {}
    try:
        reg_key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            'Environment',
            0, 
            winreg.KEY_READ
        )
        
        i = 0
        while True:
            try:
                name, value, _ = winreg.EnumValue(reg_key, i)
                env_vars[name] = value
                i += 1
            except OSError:
                # 已枚举完所有值
                break
        
        winreg.CloseKey(reg_key)
    except Exception as e:
        print(f"❌ 读取环境变量时出错: {e}")
    
    return env_vars

def delete_user_env(name: str) -> bool:
    """
    删除用户环境变量
    """
    try:
        reg_key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            'Environment',
            0, 
            winreg.KEY_SET_VALUE
        )
        
        winreg.DeleteValue(reg_key, name)
        winreg.CloseKey(reg_key)
        
        _notify_environment_changed()
        print(f"✅ 已删除用户环境变量: {name}")
        return True
        
    except FileNotFoundError:
        print(f"⚠️ 环境变量不存在: {name}")
        return False
    except Exception as e:
        print(f"❌ 删除环境变量时出错: {e}")
        return False

# 使用示例
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--file')
    args = parser.parse_args()
    
    filename = args.file
    with open(filename, 'r', encoding='utf8') as f:
        env_dict = json.load(f)
    for (env_key, env_value) in env_dict.items():
        set_user_env(str(env_key), str(env_value))
