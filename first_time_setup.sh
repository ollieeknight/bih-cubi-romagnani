#!/bin/bash
#
# Usage: first_time_setup.sh [--include-jupyter]
#
# --include-jupyter also offers the Jupyter single-cell pixi environment.
# Off by default: it's a large environment and takes a while to install.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

include_jupyter=false
for arg in "$@"; do
    case "$arg" in
        --include-jupyter) include_jupyter=true ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

cd "$HOME"

bin_folder="${HOME}/work/bin"
mkdir -p "${bin_folder}"

# ── Helpers ────────────────────────────────────────────────────────────────────

# /dev/tty can exist and still fail to open when there's no controlling
# terminal (cron, sbatch), so probe by opening it rather than testing the node.
if (: < /dev/tty) 2>/dev/null; then
    have_tty=true
else
    have_tty=false
fi

# All user-facing output goes through here, falling back to stderr when there's
# no terminal so the script still works under sbatch/cron.
if [ "$have_tty" = true ]; then
    msg() { echo -e "$@" > /dev/tty; }
else
    msg() { echo -e "$@" >&2; }
fi

err()  { msg "\033[0;31mERROR:\033[0m $*"; }
warn() { msg "\033[0;33mWARNING:\033[0m $*"; }

prompt_user() {
    local prompt_message="$1"
    local user_choice=""
    # Non-interactive run: nothing can answer, so decline rather than hang.
    if [ "$have_tty" != true ]; then
        printf 'n'
        return
    fi
    while true; do
        echo -ne "\033[0;33mINPUT REQUIRED:\033[0m ${prompt_message} (y/n): " > /dev/tty
        read -rn 1 user_choice < /dev/tty
        echo "" > /dev/tty
        [[ $user_choice =~ ^[YyNn]$ ]] && break
        err "Invalid input; please enter y or n"
    done
    printf '%s' "$user_choice"
}

confirmed() { [[ "$1" =~ ^[Yy]$ ]]; }

# ── Symlinks ───────────────────────────────────────────────────────────────────

manage_symlink() {
    local link_name="$1"
    local home_link="${HOME}/${link_name}"
    local bin_link="${bin_folder}/${link_name}"

    mkdir -p "${bin_link}"

    if [ -L "${home_link}" ]; then
        if [ "$(readlink "${home_link}")" != "${bin_link}" ]; then
            rm "${home_link}"
            ln -s "${bin_link}" "${home_link}"
        fi
    elif [ -d "${home_link}" ]; then
        # Copy-verify-remove rather than mv: home and work are separate mounts,
        # so a mv interrupted by a full quota can lose the directory outright.
        if cp -a "${home_link}/." "${bin_link}/"; then
            rm -rf "${home_link}"
            ln -s "${bin_link}" "${home_link}"
        else
            err "Failed to copy ${home_link} to ${bin_link}; leaving it in place."
        fi
    elif [ ! -e "${home_link}" ]; then
        ln -s "${bin_link}" "${home_link}"
    else
        err "${home_link} is a file, not a directory. Skipping."
    fi
}

link_if_accessible() {
    local target="$1"
    local link_name="$2"
    if [ -d "${target}" ]; then
        # -n so an existing symlink is replaced rather than followed into.
        ln -sfn "${target}" "${HOME}/${link_name}"
    else
        warn "${target} isn't accessible yet — skipping ~/${link_name}. Ask Ollie if you need access."
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
        # Deliberately unexpanded: $(hostname) must evaluate at login, per node.
        # shellcheck disable=SC2016
        {
            echo ""
            echo 'export TMPDIR=$HOME/scratch/tmp/$(hostname)'
            echo 'mkdir -p "$TMPDIR"'
        } >> "${HOME}/.bashrc"
    fi
}

# ── Pixi ───────────────────────────────────────────────────────────────────────

require_pixi() {
    command -v pixi &> /dev/null && return 0
    err "pixi not found. Install pixi first."
    return 1
}

install_pixi() {
    local pixi_home="${bin_folder}/pixi_bin"
    mkdir -p "${pixi_home}"

    # PIXI_NO_PATH_UPDATE stops the installer editing .bashrc; we write the PATH
    # line ourselves below so it points at pixi_home, not ~/.pixi.
    if ! curl -fsSL https://pixi.sh/install.sh \
        | PIXI_HOME="${pixi_home}" PIXI_NO_PATH_UPDATE=1 bash > /dev/null; then
        err "pixi installation failed. Check your network connection and re-run."
        return 1
    fi

    if [ ! -x "${pixi_home}/bin/pixi" ]; then
        err "pixi binary not found at ${pixi_home}/bin/pixi after install."
        return 1
    fi

    if ! grep -q "pixi_bin/bin" "${HOME}/.bashrc"; then
        {
            echo ""
            echo "export PATH=\"${pixi_home}/bin:\$PATH\""
        } >> "${HOME}/.bashrc"
    fi

    export PATH="${pixi_home}/bin:$PATH"
    msg "pixi $("${pixi_home}/bin/pixi" --version) installed"
}

# ── Pixi environments (defined in envs/pixi/<name>/, copied in and installed) ───

install_pixi_env() {
    local env_name="$1"
    local pixi_source_dir="${SCRIPT_DIR}/envs/pixi/${env_name}"
    local pixi_dest_dir="${bin_folder}/pixi/${env_name}"

    if [ ! -f "${pixi_source_dir}/pixi.toml" ]; then
        err "${pixi_source_dir}/pixi.toml not found. Skipping ${env_name}."
        return 1
    fi

    mkdir -p "${pixi_dest_dir}"
    cp "${pixi_source_dir}/pixi.toml" "${pixi_dest_dir}/"
    if [ -f "${pixi_source_dir}/pixi.lock" ]; then
        cp "${pixi_source_dir}/pixi.lock" "${pixi_dest_dir}/"
    fi

    msg "Installing pixi environment '${env_name}' — this may take a while..."
    # --locked aborts if pixi.lock is stale relative to pixi.toml; that's
    # deliberate, so everyone gets the same resolved environment.
    if pixi install --locked --manifest-path "${pixi_dest_dir}/pixi.toml" > /dev/null; then
        msg "${env_name} environment ready at ${pixi_dest_dir}"
    else
        err "pixi install failed for '${env_name}'. Re-run the script to retry."
        return 1
    fi
}

# ── OOD apps ───────────────────────────────────────────────────────────────────

clone_ood_apps() {
    local dev_dir="${bin_folder}/ondemand/dev"
    mkdir -p "${dev_dir}"

    for repo in "ood-bih-rstudio-server" "ood-bih-jupyter"; do
        if [ -d "${dev_dir}/${repo}/.git" ]; then
            msg "Updating ${repo}..."
            git -C "${dev_dir}/${repo}" pull --quiet \
                || err "Could not update ${repo}; leaving the existing copy alone."
        else
            msg "Cloning ${repo}..."
            git -C "${dev_dir}" clone --quiet "https://github.com/Romagnani-Lab/${repo}" \
                || err "Could not clone ${repo}."
        fi
        # New dirs inherit the setgid bit from the parent. When OnDemand stages a
        # session it rsyncs template/ and tries to reproduce that bit, which
        # CephFS refuses — the launch then fails with EPERM. Strip it each time.
        if [ -d "${dev_dir}/${repo}" ]; then
            chmod -R g-s "${dev_dir}/${repo}"
        fi
    done
}

# ── Main ───────────────────────────────────────────────────────────────────────

# Each step is optional and independent, so a failure in one is reported but
# doesn't abort the rest of the setup.
run_step() { "$@" || err "Step '$1' did not complete."; }

if confirmed "$(prompt_user "Create easy-access shortcuts for folders (recommended)?")"; then
    msg "Creating shortcuts..."
    run_step create_symlinks
fi

if confirmed "$(prompt_user "Install pixi (recommended for RStudio and Jupyter on the portal)?")"; then
    msg "Installing pixi..."
    run_step install_pixi
fi

if confirmed "$(prompt_user "Set up R 4.5.0 environment via pixi (recommended for RStudio)?")" && require_pixi; then
    run_step install_pixi_env "R_4.5.0"
fi

if confirmed "$(prompt_user "Set up reticulate Python environment via pixi (for R-Python interop)?")" && require_pixi; then
    run_step install_pixi_env "r-reticulate"
fi

if [[ "$include_jupyter" == true ]]; then
    if confirmed "$(prompt_user "Set up Jupyter single-cell environment via pixi (large, GPU/torch)?")" && require_pixi; then
        run_step install_pixi_env "jupyter"
    fi
fi

if confirmed "$(prompt_user "Clone/update RStudio and Jupyter portal apps (recommended)?")"; then
    run_step clone_ood_apps
fi

msg ""
msg "\033[0;32mSetup complete!\033[0m Re-open your terminal (or run: source ~/.bashrc) to apply PATH changes."
if [[ "$include_jupyter" == false ]]; then
    msg "Skipped the Jupyter single-cell environment. Re-run with --include-jupyter to add it."
fi
