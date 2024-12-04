# BIH-CUBI HPC Guide

The Romagnani lab uses the [Berlin Institute of Health-Core Bioinformatics Unit (BIH-CUBI) High Performance Computing (HPC) cluster](https://www.hpc.bihealth.org/) for computational work.

For RStudio and JupterLab access, go to the >> **[BIH Dashboard](https://hpc-portal.cubi.bihealth.org/pun/sys/dashboard/)** <<

If you run into trouble using any part of the HPC, heres an order of where to look for guidance:  
1. The BIH-CUBI HPC [documents](https://bihealth.github.io/bih-cluster/)
2. The BIH-CUBI HPC [question board](https://hpc-talk.cubi.bihealth.org/) for posting and helping with issues  
3. Ollie (oliver.knight@charite.de)  
4. The HPC helpdesk (hpc-helpdesk@bih-charite.de), explaining your problem according to [these guidelines](https://bihealth.github.io/bih-cluster/help/good-tickets/)  

# Contents

**[VPN access and requesting an account](https://github.com/ollieeknight/bih-cubi/tree/main?tab=readme-ov-file#vpn-access-and-requesting-an-account)**  
**[Connecting to the cluster](https://github.com/ollieeknight/bih-cubi/tree/main?tab=readme-ov-file#vpn-access-and-requesting-an-account)**  
**[Setting up your work environment](https://github.com/ollieeknight/bih-cubi/tree/main?tab=readme-ov-file#vpn-access-and-requesting-an-account)**  
**[Setting up an RStudio session](https://github.com/ollieeknight/bih-cubi/tree/main?tab=readme-ov-file#vpn-access-and-requesting-an-account)**  


# VPN access and requesting an account

1. **Fill in both VPN forms, [`vpn_antrag.pdf`](https://github.com/romagnanilab/bih-cubi/blob/main/files/01_VPN_antrag.pdf), and [`vpn_zusatzantrag_b.pdf`](https://github.com/romagnanilab/bih-cubi/blob/main/files/02_VPN_zusatzantrag_B.pdf)**  
Print and sign both, then scan and send both files to to *vpn@charite.de*, cc'ing Chiara (*chiara.romagnani@charite.de*).

2. **For personal computer access, install OpenVPN and configure your connection**  
Refer to either installation on macOS ([`vpn_macOS_installation.pdf`](https://github.com/romagnanilab/bih-cubi/blob/main/files/install_VPN_macOS.pdf)) or Windows ([`vpn_Windows_installation.pdf`](https://github.com/romagnanilab/bih-cubi/blob/main/files/install_VPN_windows.pdf)) if you run into trouble.

If you have any issues, feel free to ask Ollie (*oliver.knight@charite.de*) for help. You can also check out the BIH-CUBI cluster guide [here](https://bihealth.github.io/bih-cluster/).

3. **Applying for an HPC user account**  

Please fill in the form below and forwarded to Ollie, who is the named delegate for AG Romagnani with the cluster.

```
- cluster: HPC 4 Research
- first name:
- last name:
- affiliation: Charite, Institute of Medical Immunology
- institute email: # charite e-mail
- institute phone:
- user has account with
    - [ ] BIH
    - [x] Charite
    - [ ] MDC
- BIH/Charite/MDC user name:
- duration of cluster access (max 1 year): 1 year
- AG: ag-romagnani
```

Ollie will then forward this to the CUBI team who will set up your account.

# Connecting to the cluster

**1. Login to the CUBI dashboard through your browser**   

Go [here](https://hpc-portal.cubi.bihealth.org/pun/sys/dashboard/) here to log in to access the Dashboard.  
***a. DRFZ computer Windows login***  
Login with your username in this format: `username@CHARITE`  

***b. Work Mac or personal computer/laptop***  
Login with your Charite credentials, i.e. `username`

<details>
  <summary>Optional - terminal connection</summary>
    
**2. Creating a secure shell (ssh) key**  

a. In terminal, type `ssh-keygen -t rsa -C "your_email@charite.de"` # leaving the quotation marks, enter your e-mail.  

c. Use the default location for storing your ssh key (press enter), and type a secure password in to store it.  

d. Locate the `.ssh/id_rsa.pub` file in your file explorer and open with notepad/textedit. You may need to enable the 'show hidden files and folders' setting in your control panel.  

e. Copy the contents; it should look something like  
```
ssh-rsa AAAAAB3NzaC1yc2EAAAADAQABAAABAQC/Rdd5rf4BT38jsBrXpiZZlEmkB6809QK7hV6RCG13VcyPTIHSQePycfcUv5q1Jdy28MpacL/nv1UR/o35xPBn2HkgB4OqnKtt86soCGMd9/YzQP5lY7V60kPBJbrXDApeqf+H1GALsFNQM6MCwicdE6zTqE1mzWVdhGymZR28hGJbVsnMDDc0tW4i3FHGrDdmb7wHM9THMx6OcCrnNyA9Sh2OyBH4MwItKfuqEg2rc56D7WAQ2JcmPQZTlBAYeFL/dYYKcXmbffEpXTbYh+7O0o9RAJ7T3uOUj/2IbSnsgg6fyw0Kotcg8iHAPvb61bZGPOEWZb your_email@charite.de
```

f. Go to https://zugang.charite.de/ and log in as normal. Click on the blue button `SSHKeys...`, paste the key from your `.ssh/id_rsa.pub` file, and click append.  

**4. Connect to the cluster**  
a. Type `ssh-add`  

b. Go to the `$HOME/.ssh/` folder and create a new text file. paste the below in, adding your username and leaving the '_c', and save, *without* a file extension.  
```bash
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

c. Then, you can simply type `ssh bihcluster``  
Enter the password you set during **step 2** and connect into the login node. Proceed directly to the instructions in [Setting up your work environment](https://github.com/romagnanilab/bih-cubi/tree/main#setting-up-your-work-environment)

</details>

# Setting up your work environment

Upon connecting using the `ssh bihcluster` command, or through `Clusters -> _cubi Shell Access` on the Dashboard, you'll find yourself in a login node.   
**Do not** run anything here as there is limited RAM and CPU for anything, it is only intended for running `tmux` sessions.  

**1. Creating an interactive session** 

`tmux` is essentially a new window for your command line. You can attach and detach these and they will run in the background even when you close your terminal window.  

To begin:
```bash
tmux new -s cubi # create a new tmux session with the name 'cubi'
```

You can detach this at any time by pressing CTRL+b, letting go, and pressing the d key. You can reattach at any time in 'base' command windows by typing `tmux a -t cubi`, or simply `tmux a` to attach your last accessed session. `tmux ls` lists your sessions.  

Next, we will ask the workload managing system `slurm` to allocate us some cores and RAM.

```bash
srun --time 48:00:00 --ntasks 16 --mem 32G --immediate=10000 --pty bash -i
```  

This creates a session which will last 48h, allow you to use 16 CPU cores, and 32Gb RAM. From here, we can install software, packages, extract files and run programs.

**2. Setting up a workspace environment**

To set up your workspace on the BIH-CUBI cluster, follow the structure outlined below. The arrangement is designed for optimal organisation of your files and efficient use of available resources:

## Home Directory
Your home directory is located at `/data/cephfs-1/home/users/$USER`. This space is limited to 1 GB and should only contain *links* to other folders. You can check your current location with the command `pwd`.

## Scratch Folder
The scratch directory is at `/data/cephfs-1/home/users/$USER/scratch`, with a quota of 200 TB. Note that files are automatically deleted after 2 weeks from their creation date. This is where you should run large data sets, such as sequencing runs and processing pipelines.

## Work Folder
Your work directory can be found at `/data/cephfs-1/home/users/$USER/work`, with a hard quota of 1 TB. This space is designated for non-group personal use.

## Group Folder
Communal programs, scripts, and reference genomes/files are stored in `/data/cephfs-1/home/groups/ag_romagnani/`.

## Setting up miniforge and RStudio environments - important!

Below is a set of instructions to install miniforge3, which is required to install Seurat and other R packages. However, you can skip this and hopefully run a command with this to get everything looking nice:

```bash
bash /data/cephfs-2/unmirrored/groups/romagnani/work/bin/first_time_setup.sh
```

Alternatively, you can do things step by step:  

```bash
bin_folder=/data/cephfs-1/work/groups/romagnani/users/${USER}/bin
mkdir $bin_folder && cd $bin_folder

# download, install, and update miniforge 
cd ${bin_folder}
curl -L https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -o Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh -b -p ${bin_folder}/miniforge3/
rm Miniforge3-Linux-x86_64.sh

# modify conda repositories  
nano ${HOME}/.condarc

# copy and paste this into nano (CTRL+C here, right click to paste)
channels:
  - https://prefix.dev/conda-forge
  - https://prefix.dev/pytorch
  - https://prefix.dev/bioconda
show_channel_urls: true
changeps1: true
channel_priority: strict

# close by CTRL+X and y and enter

conda upgrade --all -y
echo "" >> ${HOME}/.bashrc
echo "source ${bin_folder}/miniforge3/etc/profile.d/conda.sh" >> ${HOME}/.bashrc

# If you'd like to make a conda env now for single cell analysis in R, run these steps:  
conda create -y -n R_4.3.3 r-base r-tidyverse r-biocmanager r-hdf5r r-devtools r-r.utils r-seurat r-signac r-leiden r-matrix r-pals r-ggsci r-ggthemes r-showtext r-ggpubr r-ggridges r-ggtext r-ggh4x bioconductor-motifmatchr bioconductor-tfbstools bioconductor-chromvar bioconductor-bsgenome.hsapiens.ucsc.hg38 bioconductor-ensdb.hsapiens.v86 bioconductor-deseq2 bioconductor-limma r-harmony bioconductor-biocfilecache

conda create -y -n r-reticulate -c vtraag python-igraph pandas umap-learn scanpy macs2
```

An important part is to perform a simple fix, which might save you some headaches in the future:  

```bash
mkdir -p ${bin_folder}/ondemand/dev
cd ${bin_folder}/ondemand/dev
git clone https://github.com/ollieeknight/ood-bih-rstudio-server

sed -i "s/\${USER}/$USER/g" "ood-bih-rstudio-server/template/script.sh.erb"
```

In the above script, we make a folder called `bin` in your work directory, and then download and install miniforge. We then use it to create our R environment named `R_4.3.3`, but you can name this whatever you want.

If at any point you come into errors installing packages through RStudio directly, try using this format while in the `R_4.3.3` conda environment: `conda install r-package`, replacing the word 'package' with what you want to install. The 'r-' prefix indicates it's an `R` package, and not a `python` one.

# Setting up an RStudio session

**1. Navigate to [this page](https://hpc-portal.cubi.bihealth.org/pun/sys/dashboard/).** You must be connected to the Charite VPN to access this page

**2. In the top bar, go to `Interactive Apps` then the red `RStudio Server (Sandbox)`** button. It's important you choose the *Sandbox* RStudio server due to some ongoing package loading issues with the OnDemand platform

From here, you can customise the session you want:

```bash
**R source:** change to miniforge  
**miniforge path:** ~/work/bin/miniforge3/bin:R_4.3.3 # or whatever you named the environment to be
**Apptainer image:** *leave as is*  
**Number of cores:** Maximum 32
**Memory [GiB]:** Maximum 128  
**Running time [days]:** Maximum 14, recommended 1  
**Partition to run in:** medium
```

When you launch this, it will queue the request as it goes through the `slurm` workload manager. It will then automatically update when it is running, and you can launch the session. If it is taking too long, reduce the cores, memory, and running time. 16 cores, 64 Gb RAM, and 1 day often works well.

**5.** Finalising our R environment, we move back to ondemand, launch a session once more, and perform these steps:

At the beginning of your script, you must let R know where your python environment is to use reticulate:

```R
Sys.setenv(PATH = paste('~/work/bin/miniforge3/envs/r-reticulate/lib/python3.10/site-packages/', Sys.getenv()['PATH'], sep = ':'))
library(reticulate)
assignInNamespace('is_conda_python', function(x){ return(FALSE) }, ns = 'reticulate')
use_condaenv('~/work/bin/miniforge3/envs/r-reticulate/', required = T)
```

Then install some extra packages...

```R
remotes::install_github(c('satijalab/azimuth', 'satijalab/seurat-data', 'chris-mcginnis-ucsf/DoubletFinder', 'carmonalab/UCell', 'satijalab/seurat-wrappers', 'mojaveazure/seurat-disk'), force = T)
```
