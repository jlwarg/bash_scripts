#/bin/bash
echo "Arch Linux post installation script"

add_user() {
    echo -n "User to add: "
    read USERNAME
    useradd -m -G wheel $USERNAME
}

additional_packages() {
    # contents of packages file should be the result of
    # comm -23 <(pacman -Qqen | sort) <(pacman -Qqg base base-devel | sort) > packages_file.txt
    # on the "source" system
    echo -n "package list file: "
    read PACKAGES_FILE
    if [[ ! -f $PACKAGES_FILE ]]; then
        echo "file $PACKAGES_FILE doesn't exist."
        exit 1
    else
        echo "installing packages"
        CONTENTS=$(cat $PACKAGES_FILE)
        sudo pacman -S --needed $CONTENTS
    fi
}

aur_packages() {
    # aur package file should be the result of
    # pacman -Qqm
    # on the "source" system
    echo -n "directory for aur package files: "
    read AUR_DIR
    if [[ ! -d $AUR_DIR ]]; then
        echo "$AUR_DIR does not exist, creating..."
        mkdir -p $AUR_DIR
    fi
    cd $AUR_DIR
    echo -n "aur package list file: "
    read AUR_FILE
    if [[ ! -f $AUR_FILE ]]; then
        echo "file $AUR_file doesn't exist."
        exit 1
    else
        # Download tarballs
        for package in $(cat $AUR_FILE); do
            curl -L 0O https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz
        done
        # extract packages
        for tgz in $(echo *.tar.gz); do
            tar -xvf $tgz
        done
        # Build packages
        echo "building packages..."
        for dir in $AUR_DIR/*; do
            echo -n "building $dir..."
            cd "$dir" && makepkg -sr && cd ..
            echo "done"
        done
        echo "installing packages..."
        find . -name "*.pkg.tar.xz" -exec pacman -U {} +;
    fi 
}

enable_services() {
    # enable all services present on the source system
    # TODO: get a list of all enabled services on a fully installed system
    # services_file will probably contain something like:
    # systemctl --list-unit-files | grep enabled | awk '{ print $1 }'

    echo -n "service list file: "
    read SERVICES_FILE
    if [[ ! -f $SERVICES_FILE ]]; then
        echo "file $SERVICES_FILE doesn't exist."
        exit 1
    else
        echo "enabling services"
        SERVICES=$(cat $SERVICES_FILE)
        for s in $SERVICES; do
            systemctl enable s
        done
    fi
}

install_dotfiles() {
    echo "Making sure git and stow are present"
    pacman -S --needed git stow
    echo -n "Github username: "
    read GITHUBNAME
    echo -n "dotfile repository: "
    read DOTFILES
    su $USERNAME
    cd /home/$USERNAME
    git clone http://github.com/$GITHUBNAME/$DOTFILES
    cd $DOTFILES
    STOWLIST=$(ls)
    for DOTDIR in $STOWLIST; do
        stow $DOTDIR
    done
}

add_user && additional_packages && enable_services && install_dotfiles
