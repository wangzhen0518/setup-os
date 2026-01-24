import os

pwd = os.path.dirname(__file__)
with open(os.path.join(pwd, "scoop-list.txt"), "r", encoding="utf8") as f:
    apps = " ".join([line.strip() for line in f.readlines()])
print("Apps:", apps)

# cmd = f"scoop install {apps}"
# print("Execute:", cmd)
# os.system(cmd)
