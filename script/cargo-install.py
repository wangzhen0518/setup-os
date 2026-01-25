import os

os.system('cargo install cargo-binstall')

apps:list[str] = []
pwd = os.path.dirname(__file__)
with open(os.path.join(pwd, "cargo-list.txt"), "r", encoding="utf8") as f:
    for line in f.readlines():
        app = line.strip()
        if app!='cargo-binstall':
            apps.append(app)
apps_text  = ' '.join(apps)
print("Apps:", apps_text)

cmd = f"cargo binstall -y {apps_text}"
print("Execute:", cmd)
os.system(cmd)
