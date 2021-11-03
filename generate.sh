#!/bin/bash

ask() {
    local prompt default reply

    if [[ ${2:-} = 'Y' ]]; then
        prompt='Y/n'
        default='Y'
    elif [[ ${2:-} = 'N' ]]; then
        prompt='y/N'
        default='N'
    else
        prompt='y/n'
        default=''
    fi

    while true; do

        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo -n "$1 [$prompt] "

        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read -r reply </dev/tty

        # Default?
        if [[ -z $reply ]]; then
            reply=$default
        fi

        # Check if the reply is valid
        case "$reply" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}

echo ""
echo "This script per default builds a customized Void Linux ISO preset with my (Lolzen's) configurations. You can change some aspects of it, if you edit the package list(s) and/or provide your own dotfiles."
echo "This script utilizes void-mklive, which is the official tool the Void Linux Team provides ISOs"
if ask "Do you want to continue?"; then
    echo "continuing."
else
    exit
fi

#setting up void-mklive and make sure it's up-to-date
echo ""
echo "Setting up void-mklive"
if [[ -d void-mklive ]]
then
    echo "void-mklive found. attempting 'git pull'"
    cd void-mklive
    git pull
    #issue make if git pull was triggered
    cd ..
else
    echo "void-mklive not found. Pulling source."
    git clone https://github.com/void-linux/void-mklive
    cd void-mklive
    make
    cd ..
fi

#clear packages-include list
echo ""
echo "clearing package list (to be installed packages)"
> packages-include

#ask for customization and build our command

CMD=""

#Architecture
echo ""
echo "It is adviced by the Void Linux team to not set this unless you know what this means."
if ask "Build an x86_64 live image? default: Yes" Y; then
    CMD="${CMD} -a x86_64"
else
    echo "No architecture will be specified. Using the default."
fi

#Dotfiles
echo ""
echo "Dotfiles have to be included in a structure where the respective files go to. See the dotfiles folder as example."
echo "This essentially preconfigures Void Linux with personal settings"
if ask "Include dotfiles? default: Yes" Y; then
    CMD="${CMD} -I ../dotfiles"
else
    echo "No additional dotfiles will be placed. Using the default."
fi

#keymap
echo ""
echo "A keymap can be specified. This is set to 'de', which is using the german QWERTZ layout."
if ask "Use de keymap? default: Yes" Y; then
    CMD="${CMD} -k de"
else
    echo "Default keymap is being used. (en)"
fi

#set an variable for 32bit
#32bit=false

#repositories
echo ""
echo "Additional (official) repositories are available."
echo "nonfree: nonfree packages"
echo "multilib: provides 32bit packages for x86_64 systems"
echo "multilib-nonfree: 32bit nonfree packages"
if ask "Enable additional repositories? default: Yes" Y; then
    CMD="${CMD} -r https://repo-us.voidlinux.org/current/nonfree -r https://repo-us.voidlinux.org/current/multilib -r https://repo-us.voidlinux.org/current/multilib/nonfree"
    multilib_var=true
else
    echo "No additional repositories will be enabled."
fi

#forming package list

echo ""
if ask "Install additional packages? (packages-custom list) default: Yes" Y; then
    cat packages-custom >> packages-include
else
    echo "No additional packages from the list 'packages-custom' will be included."
fi


if [ "$multilib_var" = true ];
then
    echo ""
    if ask "Install additional packages? (packages-custom-32bit list) default: Yes" Y; then
        cat packages-custom-32bit >> packages-include
    else
        echo "No additional packages from the list 'packages-custom-32bit' will be included."
    fi
fi

echo ""
if ask "Install nonfree packages? (packages-nonfree list) default: Yes" Y; then
    cat packages-nonfree >> packages-include
else
    echo "No additional packages from the list 'packages-nonfree' will be included."
fi

echo ""
if ask "Install nvidia package? (packages-nvidia list) default: Yes" Y; then
    cat packages-nvidia >> packages-include
else
    echo "No additional packages from the list 'packages-nvidia' will be included."
fi

if [ "$multilib_var" = true ];
then
    echo ""
    if ask "Install additional 32bit proprietary nvidia driver packages? (packages-nvidia-32bit list) default: Yes" Y; then
        cat packages-nvidia-32bit >> packages-include
    else
        echo "No additional packages from the list 'packages-nvidia-32bit' will be included."
    fi
fi

package_list_final=$(<packages-include)
CMD="sudo ./mklive.sh ${CMD} -p '${package_list_final}'"

echo ""
echo "this is the final command:"
echo "${CMD}"
if ask "Are you sure everything is correct?"; then
    echo "building the live image"
    cd void-mklive
    eval $CMD
else
    echo "Aborted"
fi
