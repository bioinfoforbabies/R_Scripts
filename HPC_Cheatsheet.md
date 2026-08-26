# HPC Cheat Sheet for Bioinformatics Beginners

**The commands and concepts you will use most often on a SLURM-based computing cluster.**

> Cluster configurations differ. Partition names, module names, memory limits, and time limits below are examples. Check your institution's HPC documentation for local settings.

---

## 1. Connect to the cluster

```bash
ssh username@cluster-address
```

You are now working on the **remote cluster**, not your laptop.

Check where you are:

```bash
hostname
pwd
whoami
```

End the SSH session:

```bash
exit
```

### Mental model

**Laptop → SSH → Login node → SLURM → Compute node**

The login node is where you prepare and submit work.
The compute node is where heavy analysis should run.

---

## 2. Move files

### Laptop → cluster

Run from **your laptop**:

```bash
scp reads.fastq.gz username@cluster-address:/path/to/project/
```

Copy a directory:

```bash
scp -r my_project/ username@cluster-address:/path/to/project/
```

For larger datasets, `rsync` is usually more useful:

```bash
rsync -avhP data/ username@cluster-address:/path/to/project/
```

### Cluster → laptop

```bash
scp username@cluster-address:/path/to/results.tsv .
```

**Important:** SSH itself does not transfer your files. `scp`, `rsync`, SFTP, or another transfer service does.

---

## 3. Find installed software

Clusters commonly manage software with **environment modules**.

See available software:

```bash
module avail
```

Search for something:

```bash
module spider R
```

Load a version:

```bash
module load R/4.4.1
```

Check what you loaded:

```bash
module list
```

Remove one module:

```bash
module unload R
```

Clear everything:

```bash
module purge
```

### Important

Put required `module load` commands **inside your job script**.

Your submitted batch job normally starts with its own environment and should not depend on something you happened to load interactively.

---

## 4. The basic SLURM job script

Create:

```bash
nano job.sh
```

Example:

```bash
#!/bin/bash

#SBATCH --job-name=fastqc
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=fastqc_%j.out
#SBATCH --error=fastqc_%j.err

module load FastQC

fastqc -t 4 reads.fastq.gz
```

Submit it:

```bash
sbatch job.sh
```

SLURM returns something like:

```text
Submitted batch job 482731
```

`482731` is your **job ID**.

---

## 5. The SLURM resources that matter

### CPU cores

```bash
#SBATCH --cpus-per-task=8
```

Then make sure your software actually uses them:

```bash
fastqc -t 8 sample.fastq.gz
```

Requesting 16 CPUs does **not** automatically make a single-threaded command use 16 CPUs.

---

### Memory

```bash
#SBATCH --mem=32G
```

Requests 32 GB for the job.

Some clusters also support memory per CPU:

```bash
#SBATCH --mem-per-cpu=4G
```

Do not normally request both unless your cluster explicitly recommends it.

---

### Wall time

```bash
#SBATCH --time=08:00:00
```

Format:

```text
HH:MM:SS
```

Some clusters also allow:

```text
D-HH:MM:SS
```

Example:

```bash
#SBATCH --time=2-00:00:00
```

means **2 days**.

A job exceeding its wall-time limit is terminated.

---

### Partition

Some clusters require:

```bash
#SBATCH --partition=standard
```

See available partitions:

```bash
sinfo
```

Partition names are cluster-specific.

---

## 6. Check your jobs

```bash
squeue -u $USER
```

Common states:

| State | Meaning       |
| ----- | ------------- |
| `PD`  | Pending       |
| `R`   | Running       |
| `CG`  | Completing    |
| `CD`  | Completed     |
| `F`   | Failed        |
| `CA`  | Cancelled     |
| `TO`  | Timed out     |
| `OOM` | Out of memory |

A job disappearing from `squeue` often means it **finished or failed**, not that it vanished mysteriously.

Check completed jobs with:

```bash
sacct
```

Or one specific job:

```bash
sacct -j 482731
```

Useful detailed view:

```bash
sacct -j 482731 \
  --format=JobID,JobName,State,Elapsed,AllocCPUS,MaxRSS,ExitCode
```

---

## 7. Cancel a job

```bash
scancel 482731
```

Cancel all of your jobs:

```bash
scancel -u $USER
```

Use the second command carefully.

---

## 8. Why is my job still pending?

Check:

```bash
squeue -u $USER
```

For more information:

```bash
scontrol show job 482731
```

Common reasons include:

```text
Resources
Priority
Dependency
QOS
PartitionTimeLimit
```

`PD` is not an error by itself.

A request for:

```text
64 CPUs
500 GB RAM
5 days
```

will usually be harder to schedule than:

```text
4 CPUs
16 GB RAM
2 hours
```

Request what the analysis realistically needs.

---

## 9. Read the job output

If your script contains:

```bash
#SBATCH --output=job_%j.out
#SBATCH --error=job_%j.err
```

and your job ID is `482731`, SLURM creates:

```text
job_482731.out
job_482731.err
```

Read them:

```bash
less job_482731.out
```

```bash
less job_482731.err
```

Search errors:

```bash
grep -i error job_482731.err
```

Follow output while a job runs:

```bash
tail -f job_482731.out
```

Exit `tail -f` with:

```text
Ctrl+C
```

---

## 10. Interactive jobs

Sometimes you need a compute node temporarily for testing.

A common SLURM pattern is:

```bash
srun \
  --cpus-per-task=4 \
  --mem=8G \
  --time=01:00:00 \
  --pty bash
```

Now you have an interactive shell backed by allocated compute resources.

Exact commands differ between clusters. Some institutions provide their own wrapper command.

Use interactive jobs for:

* testing scripts
* debugging
* inspecting data
* short R or Python sessions

Do not use the login node for heavy analysis just because it feels interactive.

---

## 11. Run the same analysis on many samples

Suppose you have:

```text
sample01.fastq.gz
sample02.fastq.gz
sample03.fastq.gz
...
sample100.fastq.gz
```

A **job array** is often better than manually submitting 100 jobs.

```bash
#!/bin/bash

#SBATCH --job-name=fastqc
#SBATCH --array=1-100
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --output=logs/fastqc_%A_%a.out

module load FastQC

sample=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)

fastqc -t 2 "$sample"
```

Submit once:

```bash
sbatch fastqc_array.sh
```

Useful variables:

```text
$SLURM_ARRAY_JOB_ID
$SLURM_ARRAY_TASK_ID
```

Job arrays are excellent for independent per-sample analyses.

---

## 12. Useful SLURM environment variables

Inside a running job:

```bash
echo $SLURM_JOB_ID
echo $SLURM_JOB_NAME
echo $SLURM_CPUS_PER_TASK
echo $SLURM_SUBMIT_DIR
echo $SLURM_NODELIST
```

These tell your script what SLURM allocated.

---

## 13. Check resource usage after the job

A job that finishes successfully can still be badly configured.

Check accounting data:

```bash
sacct -j 482731 \
  --format=JobID,State,Elapsed,AllocCPUS,MaxRSS
```

If your job requested:

```text
128 GB RAM
```

but `MaxRSS` shows roughly:

```text
6 GB
```

you probably over-requested memory.

If it died with:

```text
OUT_OF_MEMORY
```

request more memory or reduce the program's memory usage.

---

## 14. Storage matters too

Clusters commonly provide several storage areas.

### Home

Usually:

```bash
$HOME
```

Good for:

* scripts
* configuration
* small files

Often has a relatively small quota.

### Project/shared storage

Good for:

* datasets
* collaborative projects
* results

### Scratch

Good for:

* temporary files
* intermediate analysis
* high-I/O workflows

Scratch may be automatically deleted after a retention period.

Check disk usage:

```bash
du -sh .
```

Directory sizes:

```bash
du -sh *
```

If supported:

```bash
quota -s
```

Do not assume every filesystem behaves the same way.

---

## 15. Keep large temporary files off `$HOME`

A bioinformatics pipeline can generate hundreds of GB of intermediate data.

Instead of:

```bash
~/project/tmp/
```

your institution may prefer something like:

```bash
/scratch/$USER/project/
```

Exact paths differ by cluster.

---

## 16. Useful Linux commands on HPC

Where am I?

```bash
pwd
```

What's here?

```bash
ls -lh
```

See hidden files:

```bash
ls -lah
```

Directory size:

```bash
du -sh directory/
```

Free disk space:

```bash
df -h
```

View file:

```bash
less file.txt
```

First lines:

```bash
head file.txt
```

Last lines:

```bash
tail file.txt
```

Search text:

```bash
grep "pattern" file.txt
```

Count lines:

```bash
wc -l file.txt
```

Find FASTQ files:

```bash
find . -name "*.fastq.gz"
```

---

# The First-Week Workflow

```text
1. CONNECT
   ssh user@cluster-address

        ↓

2. FIND SOFTWARE
   module avail

        ↓

3. ACTIVATE SOFTWARE
   module load R/4.4.1

        ↓

4. WRITE JOB SCRIPT
   nano job.sh

        ↓

5. SUBMIT
   sbatch job.sh

        ↓

6. CHECK
   squeue -u $USER

        ↓

7. INSPECT FINISHED JOB
   sacct -j <jobid>

        ↓

8. READ OUTPUT / ERRORS
   less job_<jobid>.out
```

---

# Six Commands to Remember First

```bash
ssh user@cluster-address
```

Connect to the cluster.

```bash
module avail
```

See installed software.

```bash
module load R/4.4.1
```

Activate a software version.

```bash
sbatch job.sh
```

Submit a batch job.

```bash
squeue -u $USER
```

See queued and running jobs.

```bash
scancel <jobid>
```

Cancel a job.

---

# When Something Fails

### `command not found`

Check modules:

```bash
module avail
module list
```

Then load the required software.

---

### `OUT_OF_MEMORY`

Your job exceeded its allocated RAM.

Check:

```bash
sacct -j <jobid> --format=JobID,State,MaxRSS
```

---

### `TIMEOUT`

Your job exceeded:

```bash
#SBATCH --time=
```

Increase the request if justified.

---

### Job remains `PD`

Inspect:

```bash
squeue -u $USER
scontrol show job <jobid>
```

Pending jobs are normal on shared systems.

---

### Script works interactively but fails with `sbatch`

Check that the job script includes:

* module loads
* complete file paths
* required environment activation
* correct working directory
* sufficient CPU, RAM, and wall time

A batch job should contain everything necessary to reproduce its environment.

---

## One rule worth remembering

**Use the login node to organize work.
Use SLURM to request resources.
Use compute nodes to perform the analysis.**
