#!/bin/zsh

# Attempts to configure Docker by enabling Rosetta and increasing swap

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
validate_macos

function cannot_setup_docker {
    f_echo "Unfortunately, the script could not configure Docker automatically."
    f_echo "This means that you have to change the settings in the Docker Dashboard yourself:"
    f_echo "Enable the Virtualization Framework, Rosetta emulation and set Swap to at least 8 GiB."
    f_echo "Restart Docker after applying the changes and then continue with the installation."
    wait_for_user_input
    exit 1
}

docker_settings_file="$HOME/Library/Group Containers/group.com.docker/settings-store.json"
if ! [ -f "$docker_settings_file" ]; then
    docker_settings_file="$HOME/Library/Group Containers/group.com.docker/settings.json"
fi

stop_docker

# check if the settings file is in the expected place
if ! [ -f "$docker_settings_file" ]
then
    cannot_setup_docker
fi

# set swap to minimum 8 GiB
minSwap=8192
if grep "\"SwapMiB\":" "$docker_settings_file" > /dev/null; then
    # newer settings-store.json format
    swapMiB=$(grep "\"SwapMiB\"" "$docker_settings_file" | sed "s/[^0-9]//g")
    if [ "$swapMiB" -lt "$minSwap" ]; then
        sed -i "" "s/\"SwapMiB\": [0-9]*/\"SwapMiB\": $minSwap/" "$docker_settings_file"
    fi
elif grep "\"swapMiB\":" "$docker_settings_file" > /dev/null \
  && grep "\"useVirtualizationFramework\":" "$docker_settings_file" > /dev/null \
  && grep "\"useVirtualizationFrameworkRosetta\":" "$docker_settings_file" > /dev/null; then
    # legacy settings.json format
    sed -i "" "s/\"useVirtualizationFramework\": false/\"useVirtualizationFramework\": true/" "$docker_settings_file"
    sed -i "" "s/\"useVirtualizationFrameworkRosetta\": false/\"useVirtualizationFrameworkRosetta\": true/" "$docker_settings_file"
    swapMiB=$(grep "\"swapMiB\"" "$docker_settings_file" | sed "s/[^0-9]//g")
    if [ "$swapMiB" -lt "$minSwap" ]; then
        sed -i "" "s/\"swapMiB\": [0-9]*/\"swapMiB\": $minSwap/" "$docker_settings_file"
    fi
else
    cannot_setup_docker
fi

f_echo "Configured Docker successfully"