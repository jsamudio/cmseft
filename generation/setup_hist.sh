#!/bin/bash

# Set up the environment
unset PYTHONPATH  # To avoid conflicts

if [ "$(which conda 2>/dev/null)" == "" ]; then
  echo "Conda not found, please install mambaforge by following the instructions"
  echo "at https://github.com/conda-forge/miniforge#install"
  return 1
elif [ "$(which conda 2>/dev/null)" == "/usr/bin/conda" ]; then
  echo "Conda found, but not where you want it! Please install mambaforge by following the instructions"
  echo "at https://github.com/conda-forge/miniforge#install"
  return 1
fi

# Initialize conda
source "$(conda info --base)/etc/profile.d/conda.sh"

# Accept Anaconda Terms of Service
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main || return 1
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r || return 1

# Create the environment if it doesn't exist
if ! conda env list | grep -q "^coffea-env "; then
  echo "Creating coffea-env environment..."
  conda env create -n coffea-env -f ../histograms/environment.yml || return 1
fi

# Activate the environment
conda activate coffea-env

echo "coffea-env environment activated."
