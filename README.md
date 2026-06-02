# Romagnani Lab: HPC Cluster Guide

The Romagnani lab uses the **BIH HPC cluster** for large analyses that would be too slow or impossible on a laptop. RStudio and JupyterLab run directly in your browser through a web portal.

**Portal:** [hpc-portal.cubi.bihealth.org](https://hpc-portal.cubi.bihealth.org)

If you run into problems:

1. [BIH HPC documentation](https://hpc-docs.cubi.bihealth.org/)
2. [Community forum](https://hpc-talk.cubi.bihealth.org/)
3. Ollie — [oliver.knight@charite.de](mailto:oliver.knight@charite.de)
4. HPC helpdesk — [hpc-helpdesk@bih-charite.de](mailto:hpc-helpdesk@bih-charite.de)

---

## Contents

1. [Before you start](#1-before-you-start)
2. [Get VPN access](#2-get-vpn-access)
3. [Request an HPC account](#3-request-an-hpc-account)
4. [Log in to the portal](#4-log-in-to-the-portal)
5. [One-time setup](#5-one-time-setup-run-this-once)
6. [Using RStudio Server](#6-using-rstudio-server)
7. [Using JupyterLab](#7-using-jupyterlab)
8. [Your file storage](#8-your-file-storage)
9. [Running longer analyses](#9-running-longer-analyses)
10. [Connecting via terminal (optional)](#10-connecting-via-terminal-optional)
11. [Getting help](#11-getting-help)

---

## 1. Before you start

You need:

- A **Charité computer account** (your normal Charité login)
- **VPN access** if connecting from home or a personal computer — see step 2

---

## 2. Get VPN access

### Step 1: Fill in and sign both forms

- [`01_VPN_antrag.pdf`](files/01_VPN_antrag.pdf) — the standard VPN application
- [`02_VPN_zusatzantrag_B.pdf`](files/02_VPN_zusatzantrag_B.pdf) — the supplementary form required for HPC access

Print both, sign them, scan them, and email the scans to **vpn@charite.de**, cc'ing Chiara ([chiara.romagnani@charite.de](mailto:chiara.romagnani@charite.de)).

### Step 2: Install OpenVPN

After VPN approval, install the client and configure your connection:

- macOS: [`install_VPN_macOS.pdf`](files/install_VPN_macOS.pdf)
- Windows: [`install_VPN_windows.pdf`](files/install_VPN_windows.pdf)

> VPN approval can take a few days. Submit the forms as early as possible.

---

## 3. Request an HPC account

Send Ollie ([oliver.knight@charite.de](mailto:oliver.knight@charite.de)) a message with the following details. He will submit it to the CUBI team who will create your account.

```text
- cluster: HPC 4 Research
- first name:
- last name:
- affiliation: Charite, Institute of Medical Immunology
- institute email:
- institute phone:
- user has account with: Charite
- Charite username:
- duration of cluster access (max 1 year): 1 year
- AG: ag-romagnani
```

Your username on the cluster will be your Charité username followed by `_c` — for example, `doej_c`.

---

## 4. Log in to the portal

Go to **[hpc-portal.cubi.bihealth.org](https://hpc-portal.cubi.bihealth.org)** in your browser.

> Requires Charité VPN.

**Mac or personal computer:** Log in with your Charité username.

Once logged in you'll see the dashboard. From here you can launch RStudio, JupyterLab, open a terminal, manage files, and monitor running jobs.

---

## 5. One-time setup (run this once!)

This script:

- Creates folder shortcuts to prevent overfilling your 1 GB home directory
- Installs Miniforge3 (for conda-based environments)
- Installs pixi (environment manager used for RStudio and Jupyter)
- Sets up an R 4.5.0 environment for RStudio
- Sets up a Python/reticulate environment for R
- Installs the RStudio and Jupyter portal apps into your account

Steps:

**1.** Log in to the portal and open a terminal: click **Clusters** in the top bar, then **\_cubi Shell Access**.

**2.** Start an interactive compute session:

```sh
srun --time 4:00:00 --mem 8G --pty bash -i
```

Your prompt changes when ready.

**3.** Run the setup script:

```sh
bash /data/cephfs-2/unmirrored/groups/romagnani/work/bin/bih-cubi-romagnani/first_time_setup.sh
```

**4.** Answer the prompts. For a new account, say **y** to everything. The R 4.5.0 pixi environment step will take 10–20 minutes.

**5.** When it finishes, close the terminal tab and open a new one to apply the changes.

---

## 6. Using RStudio Server

**1.** Go to the portal and click **Interactive Apps** in the top bar, then **RStudio Server (Sandbox)**.

**2.** Fill in the form:

| Setting | What to enter |
| --- | --- |
| R environment source | **Pixi environment** (recommended) |
| Path to pixi project directory | `~/work/bin/pixi/R_4.5.0` |
| Apptainer image | leave as-is |
| Number of CPU cores | 8–16 (max 32) |
| Memory (GB) | 32–64 (max 128) |
| Running time | `1d` for most sessions, `3d` for longer analyses |
| Partition | **medium** |

**3.** Click **Launch**. The job will show as *Queued*, then *Starting*, then *Running*. Click **Connect to RStudio Server** when it's ready.

> Smaller requests queue faster.

### Installing R packages

For packages available through pixi, use the terminal inside RStudio (Tools → Terminal → New Terminal):

```sh
pixi add r-packagename   # e.g. pixi add r-ggplot2
```

For packages from GitHub or Bioconductor, use R directly:

```r
remotes::install_github("author/package")
BiocManager::install("PackageName")
```

### Using Python from R (reticulate)

Add this at the top of your script:

```r
Sys.setenv(PATH = paste('~/work/bin/miniforge3/envs/r-reticulate/lib/python3.10/site-packages/', Sys.getenv()['PATH'], sep = ':'))
library(reticulate)
assignInNamespace('is_conda_python', function(x){ return(FALSE) }, ns = 'reticulate')
use_condaenv('~/work/bin/miniforge3/envs/r-reticulate/', required = TRUE)
```

---

## 7. Using JupyterLab

**1.** Go to the portal and click **Interactive Apps**, then **Jupyter**.

**2.** Fill in the form:

| Setting | What to enter |
| --- | --- |
| Python environment source | **Pixi environment** (if you have a pixi Jupyter env) or **Conda environment** |
| Path to pixi project directory | `~/work/bin/pixi/jupyter` |
| Jupyter Lab/Notebook | **Jupyter Lab** (recommended) |
| Working directory | leave blank to start in your home folder |
| Number of CPU cores | 4–8 |
| Memory (GB) | 16–32 |
| Running time | `1d` |
| Partition | **medium** |

**3.** Click **Launch**, wait for status *Running*, then click **Connect to Jupyter**.

---

## 8. Your file storage

**Your home directory has only 1 GB.** The setup script moves large cache folders elsewhere.

| Location | Shortcut | Full path | What to put there | Size limit | Auto-deleted? |
| --- | --- | --- | --- | --- | --- |
| Home | `~/` | `/data/cephfs-1/home/users/<user>` | Symlinks only, config files | **1 GB** | No |
| Work | `~/work/` | `/data/cephfs-1/work/groups/romagnani/users/<user>/work` | Software, personal data, scripts | 1 TB | No |
| Scratch | `~/scratch/` | `/data/cephfs-1/scratch/groups/romagnani` | Temporary files, pipeline runs | 10 TB | **Yes — 14 days** |
| Group | `~/group/` | `/data/cephfs-2/unmirrored/groups/romagnani` | Shared tools, reference genomes | 10 TB | No |
| Share | `~/share/` | `/data/cephfs-2/unmirrored/projects/share` | Cross-project shared data | 1 TB | No |

Rules of thumb:

- Never save large files directly to `~/` — it will cause failures
- Run pipelines and large datasets in `~/scratch/`, but files delete after 14 days
- Finished results go in `~/work/`
- Reference genomes and shared tools live in `~/group/`

---

## 9. Running longer analyses

Use **tmux** for analyses longer than a few minutes; sessions survive browser closure.

Start a tmux session:

```sh
tmux new -s work
```

Then start a compute session inside tmux:

```sh
srun --time 48:00:00 --ntasks 16 --mem 64G --pty bash -i
```

This requests 48 hours, 16 CPU cores, and 64 GB RAM. Adjust as needed.

**Detach** (session keeps running): `Ctrl+b`, then `d`  
**Re-attach:** `tmux a -t work`  
**List sessions:** `tmux ls`

For analyses running overnight or for days, use batch jobs with `sbatch`. See the [SLURM documentation](https://hpc-docs.cubi.bihealth.org/slurm/overview/) or ask Ollie.

---

## 10. Connecting via terminal (optional)

Useful for file transfers and running pipelines directly.

<details>
<summary>Show terminal connection instructions</summary>

### Step 1: Generate an SSH key

Open a terminal on your computer and run:

```sh
ssh-keygen -t ed25519
```

Accept the default file location (press Enter). Set a strong passphrase.

### Step 2: Register your key with Charité

1. Find your public key file: `~/.ssh/id_ed25519.pub`
2. Open it with a text editor and copy the contents
3. Go to [zugang.charite.de](https://zugang.charite.de) and log in
4. Click **SSH Keys**, paste your key, and click **Append**

### Step 3: Create an SSH config shortcut

Create (or edit) `~/.ssh/config` and add:

```text
Host cubi
    ForwardAgent yes
    ForwardX11 yes
    HostName hpc-login-1.cubi.bihealth.org
    User username_c
    RequestTTY yes

Host cubi2
    ForwardAgent yes
    ForwardX11 yes
    HostName hpc-login-2.cubi.bihealth.org
    User username_c
    RequestTTY yes
```

Replace `username_c` with your Charité username followed by `_c`.

### Step 4: Connect

```sh
ssh-add
ssh cubi
```

> You land on a **login node** — do not run analyses here. Start a compute session with `srun` first.

### Transferring files

Use the transfer nodes (not the login nodes) for large file transfers:

```sh
scp localfile.txt username_c@hpc-transfer-1.cubi.bihealth.org:/data/cephfs-1/work/...
```

</details>

---

## 11. Getting help

1. **BIH HPC documentation:** [hpc-docs.cubi.bihealth.org](https://hpc-docs.cubi.bihealth.org/)
2. **Community forum:** [hpc-talk.cubi.bihealth.org](https://hpc-talk.cubi.bihealth.org/) — post questions, search past issues
3. **Ollie:** [oliver.knight@charite.de](mailto:oliver.knight@charite.de)
4. **HPC helpdesk:** [hpc-helpdesk@bih-charite.de](mailto:hpc-helpdesk@bih-charite.de) — for account issues, access problems, hardware faults
