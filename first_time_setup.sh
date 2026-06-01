#!/bin/bash

cd "$HOME"

TMPDIR=${TMPDIR:-/tmp}
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

create_symlinks() {
    local links=(".config" ".celltypist" ".gsutil" ".ipython" ".java" ".jupyter" ".keras" ".local" ".ncbi" ".nv" ".nextflow" "ondemand" ".parallel")
    for link in "${links[@]}"; do
        manage_symlink "$link"
    done

    ln -sf /data/cephfs-2/unmirrored/projects/romagnani-share "${HOME}/share"
    ln -sf /data/cephfs-2/unmirrored/groups/romagnani "${HOME}/group"

    # Keep temp cache on scratch to avoid filling home quota
    echo "" >> "${HOME}/.bashrc"
    echo "mkdir -p ~/scratch/tmp/.cache" >> "${HOME}/.bashrc"
}

# ── Miniforge ──────────────────────────────────────────────────────────────────

install_miniforge() {
    [ -d "${bin_folder}/miniforge3/" ] && rm -rf "${bin_folder}/miniforge3/"
    { [ -d "${HOME}/.conda" ] || [ -L "${HOME}/.conda" ]; } && rm -rf "${HOME}/.conda"

    cd "${bin_folder}" || exit 1
    curl -fsSL https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
        -o Miniforge3-Linux-x86_64.sh > /dev/null 2>&1
    bash Miniforge3-Linux-x86_64.sh -b -p "${bin_folder}/miniforge3/" > /dev/null
    rm Miniforge3-Linux-x86_64.sh

    cat <<EOF > "${HOME}/.condarc"
channels:
  - https://prefix.dev/conda-forge
  - https://prefix.dev/pytorch
  - https://prefix.dev/bioconda
show_channel_urls: true
changeps1: true
channel_priority: strict
EOF

    source "${bin_folder}/miniforge3/etc/profile.d/conda.sh"

    # Remove any stale conda init lines, add clean one
    sed -i '/conda activate/d; /conda source/d; /source .*\.conda\.sh/d' "${HOME}/.bashrc"
    echo "" >> "${HOME}/.bashrc"
    echo "source ${bin_folder}/miniforge3/etc/profile.d/conda.sh" >> "${HOME}/.bashrc"

    if [ ! -f "${HOME}/.Rprofile" ] || ! grep -q "options(download.file.method = 'wget')" "${HOME}/.Rprofile"; then
        echo "options(download.file.method = 'wget')" >> "${HOME}/.Rprofile"
    fi

    conda upgrade --all -y > /dev/null

    mv "${HOME}/.conda" "${bin_folder}" && ln -sf "${bin_folder}/.conda" "${HOME}/.conda"

    # Move cache off home quota
    if [ -d "${HOME}/.cache" ] && [ ! -L "${HOME}/.cache" ]; then
        mv "${HOME}/.cache" ~/scratch/tmp/ && ln -sf ~/scratch/tmp/.cache "${HOME}/.cache"
    elif [ -L "${HOME}/.cache" ]; then
        rm "${HOME}/.cache" && ln -sf ~/scratch/tmp/.cache "${HOME}/.cache"
    fi

    conda clean --all -y > /dev/null
    pip cache purge > /dev/null 2>&1 || true

    cd "$HOME"
}

# ── Pixi ───────────────────────────────────────────────────────────────────────

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

# ── R 4.5.0 pixi environment ───────────────────────────────────────────────────

create_rstudio_pixi_env() {
    local pixi_dir="${bin_folder}/pixi/R_4.5.0"
    mkdir -p "${pixi_dir}"

    cat <<'EOF' > "${pixi_dir}/pixi.toml"
[workspace]
authors = ["Oliver Knight <oliver.c.knight@gmail.com>"]
name = "R_4.5.0"
platforms = ["linux-64"]
version = "0.1.0"
channels = [
  "https://prefix.dev/conda-forge",
  "https://prefix.dev/pytorch",
  "https://prefix.dev/bioconda"
]

[dependencies]
r-base = ">=4.5,<4.6"
r-renv = "*"
gcc = "*"
gxx = "*"
gfortran = "*"
cmake = "*"
pkg-config = "*"
libabseil = ">=20230125"
openssl = ">=3"
libcurl = "*"
hdf5 = "1.12.*"
udunits2 = "*"
libgit2 = "*"
libxml2 = "*"
glib = "*"
glpk = "*"
geos = "*"
proj = "*"
libgdal-core = "*"
zlib = "*"
libblas = "*"
liblapack = "*"
boost = "*"
gsl = "*"
gmp = "*"
pandoc = "*"
cairo = ">=1.18.4,<2"
pango = "*"
fontconfig = "*"
freetype = "*"
expat = "*"
zstd = "*"
lz4-c = "*"
xorg-libx11 = "*"
xorg-libxt = "*"
libmagic = "*"
xz = ">=5.8.3,<6"
xorg-xproto = ">=7.0.31,<8"

[activation.env]
S2_FORCE_BUNDLED_ABSEIL = "true"
LD_LIBRARY_PATH = "$CONDA_PREFIX/lib"
EOF

    echo "Installing R 4.5.0 pixi environment — this may take 10-20 minutes..." > /dev/tty
    cd "${pixi_dir}" && pixi install > /dev/null
    echo "R 4.5.0 environment ready at ${pixi_dir}" > /dev/tty
    cd "$HOME"
}

# ── Conda R environment (legacy/fallback) ──────────────────────────────────────

create_rstudio_conda_env() {
    local env_file="${HOME}/group/work/bin/source/R_4.3.3.yml"
    local env_name="R_4.3.3"
    conda env create -f "${env_file}" > /dev/null
    if [ -d "${bin_folder}/miniforge3/envs/${env_name}/lib/R/library" ]; then
        ln -sf "${bin_folder}/miniforge3/envs/${env_name}/lib/R/library" "${HOME}/R"
    fi
}

create_reticulate_env() {
    conda env create -f "${HOME}/group/work/bin/source/r-reticulate.yml" > /dev/null
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

choice=$(prompt_user "Install Miniforge3 (needed for conda environments)?")
if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "Installing Miniforge3..." > /dev/tty
    install_miniforge
fi

choice=$(prompt_user "Install pixi (recommended for RStudio and Jupyter on the portal)?")
if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "Installing pixi..." > /dev/tty
    install_pixi
fi

choice=$(prompt_user "Set up R 4.5.0 environment via pixi (recommended for RStudio)?")
if [[ "$choice" =~ ^[Yy]$ ]]; then
    if command -v pixi &> /dev/null; then
        create_rstudio_pixi_env
    else
        echo -e "\033[0;31mERROR:\033[0m pixi not found. Install pixi first." > /dev/tty
    fi
fi

choice=$(prompt_user "Set up R 4.3.3 conda environment (legacy, optional)?")
if [[ "$choice" =~ ^[Yy]$ ]]; then
    if command -v conda &> /dev/null; then
        echo "Creating R 4.3.3 conda environment..." > /dev/tty
        create_rstudio_conda_env
    else
        echo -e "\033[0;31mERROR:\033[0m conda not found. Install Miniforge3 first." > /dev/tty
    fi
fi

choice=$(prompt_user "Set up reticulate Python environment (for R-Python interop)?")
if [[ "$choice" =~ ^[Yy]$ ]]; then
    if command -v conda &> /dev/null; then
        echo "Creating reticulate environment..." > /dev/tty
        create_reticulate_env
    else
        echo -e "\033[0;31mERROR:\033[0m conda not found. Install Miniforge3 first." > /dev/tty
    fi
fi

choice=$(prompt_user "Clone/update RStudio and Jupyter portal apps (recommended)?")
if [[ "$choice" =~ ^[Yy]$ ]]; then
    clone_ood_apps
fi

echo "" > /dev/tty
echo -e "\033[0;32mSetup complete!\033[0m Re-open your terminal (or run: source ~/.bashrc) to apply PATH changes." > /dev/tty
