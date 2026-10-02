# Reviewer run instructions

Manuscript: "Neural networks learn forward dynamics when freed from numerical integration"

This repository contains the data and the MATLAB scripts that regenerate the figures of the manuscript. Please keep the data archives and the scripts in their current locations before running the instructions below.

## Repository contents

- `SUBMISSION/PAPER/` contains the submitted manuscript (DOCX and PDF).
- `SUBMISSION/FIGURES/PDF AND PNG/` contains the rendered figure files `FIG1`, `FIG2` and `FIG3` (PDF and 600 dpi PNG).
- `SUBMISSION/FIGURES/DATA AND SCRIPTS/` contains one script and one data archive per figure:
  - `FIG1.m` with `FIG1.zip`
  - `FIG2.m` with `FIG2.zip`
  - `FIG3.m` with `FIG3.zip`

Panels a and b of Figure 1 are schematics and are provided in the rendered figure only. `FIG1.m` regenerates panel c.

## Requirements

- MATLAB. The scripts were tested with R2026a; earlier releases have not been tested.
- Statistics and Machine Learning Toolbox, for `FIG2.m`.
- The Arial font.

## Regenerate the figures

Each script reads its data archive from the folder that contains the script, so the archives do not need to be extracted.

From the MATLAB command window, with the repository root as the current folder:

```matlab
cd('SUBMISSION/FIGURES/DATA AND SCRIPTS')
FIG1
FIG2
FIG3
```

Or from a terminal, at the repository root:

```bash
cd "SUBMISSION/FIGURES/DATA AND SCRIPTS"
matlab -batch "FIG1; FIG2; FIG3"
```

If `matlab` is not on the PATH, use its full path, for example `/Applications/MATLAB_R2026a.app/bin/matlab` on macOS.

The three scripts together take about one minute.

Regenerated outputs, written to `SUBMISSION/FIGURES/DATA AND SCRIPTS/`:

- `FIG1c.pdf`, `FIG1c.svg`, `FIG1c.png` (panel c of Figure 1)
- `FIG2.pdf`, `FIG2.svg`, `FIG2.png`
- `FIG3.pdf`, `FIG3.svg`, `FIG3.png`
- `FIG2_rmse_per_trial.csv` (joint-angle RMSE of every movement, both models, both conditions)
- `FIG2_summary.csv` (number of movements, mean, s.d., median, quartiles and percentiles per group, the fold difference between the models, and the Lilliefors test of normality)
- `FIG2_statistics.csv` (Kruskal-Wallis test and Dunn-Sidak pairwise comparisons)

The regenerated files should match the rendered figures in `SUBMISSION/FIGURES/PDF AND PNG/`. Small differences in fonts, PDF metadata or raster antialiasing can occur across operating systems and MATLAB releases.

## Data archives

Each archive holds CSV files and a text file that describes them (`FIG1_README.txt`, `FIG2_README.txt`, `FIG3_README.txt`).

- `FIG1.zip`: one test movement (`move_4_to_8`) without and with a torque pulse. Joint angles of the physics engine, the APE and the direct mapping model, and the joint torques.
- `FIG2.zip`: all 90 test movements without and with a torque pulse (180 files). Joint angles of the physics engine, the APE and the direct mapping model.
- `FIG3.zip`: one test movement (`move_8_to_6`) without and with a torque pulse. Joint accelerations of the physics engine and the APE, and the joint torques.

Angles are in radians, accelerations in rad/s^2, torques in N m and time in seconds, sampled every 0.1 ms. The scripts convert angles and accelerations to degrees.

To inspect an archive without running MATLAB:

```bash
cd "SUBMISSION/FIGURES/DATA AND SCRIPTS"
unzip -l FIG2.zip
unzip -p FIG2.zip FIG2_README.txt
```
