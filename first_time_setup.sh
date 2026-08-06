#!/bin/bash
#
# Usage: first_time_setup.sh [--include-jupyter]
#
# --include-jupyter also offers the Jupyter single-cell pixi environment.
# Off by default: it's a large environment and takes a while to install.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

include_jupyter=false
[[ "$1" == "--include-jupyter" ]] && include_jupyter=true

cd "$HOME"

bin_folder="${HOME}/work/bin"
mkdir -p "${bin_folder}"

# ── Helpers ────────────────────────────────────────────────────────────────────

prompt_user() {
    local prompt_message="$1"
    local user_choice
    echo -ne "\033[0;33mINPUT REQUIRED:\033[0m ${prompt_message} (y/n): " > /dev/tty
    read -rn 1 user_choice < /dev/tty
    while [[ ! $user_choice =~ ^[YyNn]$ ]]; do
        echo -e "\n\033[0;31mERROR:\033[0m Invalid input; please enter y or n" > /dev/tty
        echo -ne "\033[0;33mINPUT REQUIRED:\033[0m ${prompt_message} (y/n): " > /dev/tty
        read -rn 1 user_choice < /dev/tty
    done
    echo "" > /dev/tty
    printf '%s' "$user_choice"
}

# ── Symlinks ───────────────────────────────────────────────────────────────────

manage_symlink() {
    local link_name="$1"
    local home_link="${HOME}/${link_name}"
    local bin_link="${bin_folder}/${link_name}"

    mkdir -p "${bin_link}"

    if [ -L "${home_link}" ]; then
        [ "$(readlink "${home_link}")" != "${bin_link}" ] && rm "${home_link}" && ln -s "${bin_link}" "${home_link}"
    elif [ -d "${home_link}" ]; then
        mv "${home_link}" "${bin_folder}" && ln -s "${bin_link}" "${home_link}"
    elif [ ! -e "${home_link}" ]; then
        ln -s "${bin_link}" "${home_link}"
    else
        echo -e "\033[0;31mERROR:\033[0m ${home_link} is a file, not a directory. Skipping." > /dev/tty
    fi
}

link_if_accessible() {
    local target="$1"
    local link_name="$2"
    if [ -d "${target}" ]; then
        ln -sf "${target}" "${HOME}/${link_name}"
    else
        echo -e "\033[0;33mWARNING:\033[0m ${target} isn't accessible yet — skipping ~/${link_name}. Ask Ollie if you need access." > /dev/tty
    fi
}

create_symlinks() {
    # pixi and pip both cache packages in ~/.cache by default — .cache goes
    # through the same work/bin symlink handling as everything else, keeping
    # it off the 1 GB home quota.
    local links=(".config" ".ipython" ".jupyter" ".local" ".ncbi" ".nv" ".nextflow" "ondemand" ".parallel" ".cache")
    for link in "${links[@]}"; do
        manage_symlink "$link"
    done

    link_if_accessible "/data/cephfs-2/unmirrored/projects/romagnani-share" "share"
    link_if_accessible "/data/cephfs-2/unmirrored/groups/romagnani" "group"

    # Cluster best practice: point TMPDIR at scratch, not node-local /tmp
    if ! grep -q "^export TMPDIR=" "${HOME}/.bashrc"; then
        echo "" >> "${HOME}/.bashrc"
        echo 'export TMPDIR=$HOME/scratch/tmp/$(hostname)' >> "${HOME}/.bashrc"
        echo 'mkdir -p "$TMPDIR"' >> "${HOME}/.bashrc"
    fi
}

# ── Pixi ───────────────────────────────────────────────────────────────────────

require_pixi() {
    command -v pixi &> /dev/null && return 0
    echo -e "\033[0;31mERROR:\033[0m pixi not found. Install pixi first." > /dev/tty
    return 1
}

install_pixi() {
    local pixi_home="${bin_folder}/pixi_bin"
    mkdir -p "${pixi_home}"
    curl -fsSL https://pixi.sh/install.sh | PIXI_HOME="${pixi_home}" bash > /dev/null 2>&1

    if ! grep -q "pixi_bin/bin" "${HOME}/.bashrc"; then
        echo "" >> "${HOME}/.bashrc"
        echo "export PATH=\"${pixi_home}/bin:\$PATH\"" >> "${HOME}/.bashrc"
    fi

    export PATH="${pixi_home}/bin:$PATH"
    echo -e "pixi $("${pixi_home}/bin/pixi" --version) installed" > /dev/tty
}

# ── Pixi environments (defined in envs/pixi/<name>/, copied in and installed) ───

install_pixi_env() {
    local env_name="$1"
    local pixi_source_dir="${SCRIPT_DIR}/envs/pixi/${env_name}"
    local pixi_dest_dir="${bin_folder}/pixi/${env_name}"

    if [ ! -f "${pixi_source_dir}/pixi.toml" ]; then
        echo -e "\033[0;31mERROR:\033[0m ${pixi_source_dir}/pixi.toml not found. Skipping ${env_name}." > /dev/tty
        return 1
    fi

    mkdir -p "${pixi_dest_dir}"
    cp "${pixi_source_dir}/pixi.toml" "${pixi_dest_dir}/"
    [ -f "${pixi_source_dir}/pixi.lock" ] && cp "${pixi_source_dir}/pixi.lock" "${pixi_dest_dir}/"

    echo "Installing pixi environment '${env_name}' — this may take a while..." > /dev/tty
    if (cd "${pixi_dest_dir}" && pixi install --locked > /dev/null); then
        echo "${env_name} environment ready at ${pixi_dest_dir}" > /dev/tty
    else
        echo -e "\033[0;31mERROR:\033[0m pixi install failed for '${env_name}'. Re-run the script to retry." > /dev/tty
    fi
    cd "$HOME"
}

# ── OOD apps ───────────────────────────────────────────────────────────────────

clone_ood_apps() {
    local dev_dir="${bin_folder}/ondemand/dev"
    mkdir -p "${dev_dir}"
    cd "${dev_dir}" || exit 1

    for repo in "ood-bih-rstudio-server" "ood-bih-jupyter"; do
        if [ -d "${dev_dir}/${repo}/.git" ]; then
            echo "Updating ${repo}..." > /dev/tty
            git -C "${dev_dir}/${repo}" pull --quiet
        else
            echo "Cloning ${repo}..." > /dev/tty
            git clone --quiet "https://github.com/ollieeknight/${repo}"
        fi
    done

    cd "$HOME"
}

# ── Main ───────────────────────────────────────────────────────────────────────

choice=$(prompt_user "Create easy-access shortcuts for folders (recommended)?")
if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "Creating shortcuts..." > /dev/tty
    create_symlinks
fi

choice=$(prompt_user "Install pixi (recommended for RStudio and Jupyter on the portal)?")
if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "Installing pixi..." > /dev/tty
    install_pixi
fi

choice=$(prompt_user "Set up R 4.5.0 environment via pixi (recommended for RStudio)?")
if [[ "$choice" =~ ^[Yy]$ ]] && require_pixi; then
    install_pixi_env "R_4.5.0"
fi

choice=$(prompt_user "Set up reticulate Python environment via pixi (for R-Python interop)?")
if [[ "$choice" =~ ^[Yy]$ ]] && require_pixi; then
    install_pixi_env "r-reticulate"
fi

if [[ "$include_jupyter" == true ]]; then
    choice=$(prompt_user "Set up Jupyter single-cell environment via pixi (large, GPU/torch)?")
    if [[ "$choice" =~ ^[Yy]$ ]] && require_pixi; then
        install_pixi_env "jupyter"
    fi
fi

choice=$(prompt_user "Clone/update RStudio and Jupyter portal apps (recommended)?")
if [[ "$choice" =~ ^[Yy]$ ]]; then
    clone_ood_apps
fi

echo "" > /dev/tty
echo -e "\033[0;32mSetup complete!\033[0m Re-open your terminal (or run: source ~/.bashrc) to apply PATH changes." > /dev/tty
if [[ "$include_jupyter" == false ]]; then
    echo "Skipped the Jupyter single-cell environment. Re-run with --include-jupyter to add it." > /dev/tty
fi
