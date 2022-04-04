import sys
from config import *
from connection import connect


def deploy():
    conn = connect()

    URL_SETTING = f"https://raw.githubusercontent.com/PnX-SI/GeoNature/{GN_VERSION}/install/install_all/install_all.ini"
    URL_SCRIPT = f"https://raw.githubusercontent.com/PnX-SI/GeoNature/{GN_VERSION}/install/install_all/install_all.sh"
    conn.run(f"wget {URL_SETTING}")
    conn.run(f"wget {URL_SCRIPT}")
    # sed the settings.ini
    conn.run(f"sed -i 's/my_url=.*$/my_url={DOMAIN}/g' install_all.ini")
    conn.run(f"sed -i 's/geonature_release=.*$/geonature_release={GN_VERSION}/g' install_all.ini")
    conn.run(f"sed -i 's/install_default_dem=.*$/install_default_dem=false/g' install_all.ini")
    conn.run(f"sed -i 's/drop_geonaturedb=.*$/drop_geonaturedb={DROP_DB}/g' install_all.ini")
    conn.run("touch install_all.log")
    conn.run("chmod +x install_all.sh")
    conn.run("./install_all.sh 2>&1 | tee install_all.log")


def clean():
    conn = connect()
    conn.run("sudo rm -r geonature taxhub usershub install_all.*")


if __name__ == "__main__":
    if len(sys.argv) == 1:
        print("Pass 'deploy' or 'clean' argument to the script")
    elif len(sys.argv) > 1:
        arg1 = sys.argv[1]
        if arg1 == "deploy":
            deploy()
        elif arg1 == "clean":
            clean()
        else:
            print("Pass 'deploy' or 'clean' argument to the script")
