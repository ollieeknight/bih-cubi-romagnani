#!/bin/bash

# Change to the user's home directory
cd "$HOME"

# Ensure TMPDIR is defined, defaulting to /tmp if not set
TMPDIR=${TMPDIR:-/tmp}

# Define the bin folder path and create it if it doesn't exist
bin_folder="${HOME}/work/bin"
mkdir -p "${bin_folder}"

# Function to prompt the user for a yes/no input
prompt_user() {
    local prompt_message="$1"
    local user_choice
    echo -ne "\033[0;33mINPUT REQUIRED:\033[0m ${prompt_message} (y/n): " > /dev/tty
    read -rn 1 user_choice < /dev/tty  # -n 1 reads only one character without a newline
    while [[ ! $user_choice =~ ^[YyNn]$ ]]; do
        echo -e "\n\033[0;31mERROR:\033[0m Invalid input; please enter y or n" > /dev/tty
        echo -ne "\033[0;33mINPUT REQUIRED:\033[0m ${prompt_message} (y/n): " > /dev/tty
        read -rn 1 user_choice < /dev/tty
    done
    printf '%s' "$user_choice"
}

# Function to manage symlinks for specified directories
manage_symlink() {
    local link_name="$1"
    local home_link="$HOME/$link_name"
    local bin_link="$bin_folder/$link_name"

    mkdir -p "$bin_folder/${link_name}"

    if [ -L "$home_link" ]; then
        [ "$(readlink "$home_link")" != "$bin_link" ] && rm "$home_link" && ln -s "$bin_link" "$home_link"
    elif [ -d "$home_link" ]; then
        [ "$home_link" != "$bin_link" ] && mv "$home_link" "$bin_folder" && ln -s "$bin_link" "$home_link"
    elif [ ! -e "$home_link" ]; then
        mkdir -p "$bin_link" && ln -s "$bin_link" "$home_link"
    else
        echo -e "\033[0;31mERROR:\033[0m $home_link is a file or another type. Skipping." > /dev/tty && exit 1
    fi
}

# Function to create symlinks for a list of directories
create_symlinks() {
    local links=(".config" ".celltypist" ".gsutil" ".ipython" ".java" ".jupyter" ".keras" ".local" ".ncbi" ".nv" ".nextflow" "ondemand" ".parallel")
    for link in "${links[@]}"; do
        manage_symlink "$link"
    done

    ln -sf /data/cephfs-2/unmirrored/projects/romagnani-share share
    ln -sf /data/cephfs-2/unmirrored/groups/romagnani group
    echo "" >> "${HOME}/.bashrc"
    echo "mkdir -p ~/scratch/tmp/.cache" >> "${HOME}/.bashrc"
}

# Function to install Miniforge3
install_miniforge() {
    [ -d "${bin_folder}/miniforge3/" ] && rm -rf "${bin_folder}/miniforge3/"
    [ -d "${HOME}/.conda" ] || [ -L "${HOME}/.conda" ] && rm -rf "${HOME}/.conda"

    cd ${bin_folder}
    curl -L https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -o Miniforge3-Linux-x86_64.sh > /dev/null 2>&1
    bash Miniforge3-Linux-x86_64.sh -b -p ${bin_folder}/miniforge3/ > /dev/null
    rm Miniforge3-Linux-x86_64.sh

    cat <<EOF > ${HOME}/.condarc
channels:
  - https://prefix.dev/conda-forge
  - https://prefix.dev/pytorch
  - https://prefix.dev/bioconda
show_channel_urls: true
changeps1: true
channel_priority: strict
EOF

    source ${bin_folder}/miniforge3/etc/profile.d/conda.sh
    echo "" >> "${HOME}/.bashrc"
    sed -i '/conda activate/d; /conda source/d; /source .*\.conda\.sh/d' "${HOME}/.bashrc"
    echo "source ${bin_folder}/miniforge3/etc/profile.d/conda.sh" >> "${HOME}/.bashrc"

    [ ! -f "${HOME}/.Rprofile" ] || ! grep -q "options(download.file.method = 'wget')" "${HOME}/.Rprofile" && echo "options(download.file.method = 'wget')" >> "${HOME}/.Rprofile"

    conda upgrade --all -y > /dev/null

    mv "${HOME}/.conda" "${bin_folder}" && ln -sf "${bin_folder}/.conda" "${HOME}/.conda"

    [ -d ".cache" ] && mv .cache ~/scratch/tmp/ && ln -sf ~/scratch/tmp/.cache ~/.cache
    [ -L ".cache" ] && rm .cache && ln -sf ~/scratch/tmp/.cache ~/.cache
}

# Function to create an RStudio environment
create_rstudio_env() {
    local env_file="$HOME/group/work/bin/source/R_4.3.3.yml"
    local env_name="R_4.3.3"

    if [[ $1 == "newname" ]]; then
        echo "Enter the name for the new environment:" > /dev/tty && read -r env_name < /dev/tty
        cp "$env_file" "${TMPDIR}/${env_name}.yml"
        sed -i "1s/.*/name: ${env_name}/" "${TMPDIR}/${env_name}.yml"
        env_file="${TMPDIR}/${env_name}.yml"
    fi

    conda env create -f "$env_file" > /dev/null
    ln -s ${bin_folder}/miniforge3/envs/${env_name}/lib/R/library/ R
}

# Function to create a reticulate environment for R
create_reticulate_env() {
    conda env create -f $HOME/group/work/bin/source/r-reticulate.yml > /dev/null
}

# Function to clone the repository and replace ${USER} in template/script.sh.erb
clone_and_replace_user() {
    local repo_url="https://github.com/ollieeknight/ood-bih-rstudio-server"
    local target_dir="$bin_folder/ondemand/dev"
    local template_file="$target_dir/ood-bih-rstudio-server/template/script.sh.erb"
    
    # Clone the repository
    echo "Cloning repository..." > /dev/tty
    git clone "$repo_url" "$target_dir"
    
    # Check if the template file exists
    if [[ -f "$template_file" ]]; then
        # Replace ${USER} with the actual user name
        sed -i "s/\${USER}/$USER/g" "$template_file"
        echo "Replaced \${USER} with $USER in $template_file" > /dev/tty
    else
        echo -e "\033[0;31mERROR:\033[0m Template file $template_file not found." > /dev/tty
        exit 1
    fi
}

# Prompt the user to create symlinks and call the create_symlinks function if the user agrees
choice=$(prompt_user "Do you want to create easy access shortcuts for folders?")
if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "Creating symlinks..." > /dev/tty
    create_symlinks
fi

# Prompt the user to install Miniforge3 and call the install_miniforge function if the user agrees
choice=$(prompt_user "Do you want to install Miniforge3?")
if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "Installing Miniforge3..." > /dev/tty
    install_miniforge
fi

# Prompt the user to create an RStudio environment and call the create_rstudio_env function if the user agrees
choice=$(prompt_user "Do you want to create RStudio environment R_4.3.3? (y/newname/n)")
if [[ "$choice" =~ ^[Yy]$ || "$choice" == "newname" ]]; then
    echo "Creating RStudio environment..." > /dev/tty
    create_rstudio_env "$choice"
fi

# Prompt the user to create a reticulate environment and call the create_reticulate_env function if the user agrees
choice=$(prompt_user "Do you want to create a reticulate environment for R?")
if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "Creating reticulate environment..." > /dev/tty
    if command -v conda &> /dev/null; then
        conda activate
    else
        echo -e "\033[0;31mERROR:\033[0m conda command not found. Please ensure Miniforge3 is installed correctly." > /dev/tty
        exit 1
    fi
fi


# Prompt the user to clone the repository and replace ${USER} in template/script.sh.erb
choice=$(prompt_user "Do you want to clone the RStudio fix? (recommended)")
if [[ "$choice" =~ ^[Yy]$ ]]; then
    clone_and_replace_user
fi

# Activate conda and clean up conda and pip caches
conda activate
conda clean --all -y
pip cache purge
