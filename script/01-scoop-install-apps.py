import os

import tomllib


def main():
    scoop_apps_file = os.path.join(
        os.path.dirname(__file__), os.pardir, "config/scoop/scoop-apps.toml"
    )

    with open(scoop_apps_file, "rb") as f:
        data: dict[str, list[str]] = tomllib.load(f)
    apps = " ".join(data["basic"])

    cmd = f"scoop install {apps}"
    print("Execute:", cmd)
    os.system(cmd)

    hold_apps = " ".join(data["hold"])
    cmd = f"scoop hold {hold_apps}"
    print("Execute:", cmd)
    os.system(cmd)


if __name__ == "__main__":
    main()
