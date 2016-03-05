#/bin/bash
echo "Arch Linux post installation script"

add_user() {
    echo -n "User to add: "
    read USERNAME
    useradd -m -G wheel $USERNAME
}

additional_packages() {
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

enable_services() {
    # enable all services
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
