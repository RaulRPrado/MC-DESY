#!/bin/bash

######
# ROOT

if [ ! -z "${LD_LIBRARY_PATH}" ]; then
    export LD_LIBRARY_PATH=""
fi

# shellcheck disable=SC1091
source /afs/ifh.de/group/cta/scratch/prado/MC-VERITAS/loadROOT.sh

export SW_DIR="/afs/ifh.de/group/cta/scratch/prado/sw"

#####
# VBF
export VBF_DIR="${SW_DIR}/libVBF"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${VBF_DIR}/lib
export PATH=${VBF_DIR}/bin:$PATH

########
# ROBAST
export ROBAST_DIR="${SW_DIR}/GrOptics/v1.5.0_beta"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ROBAST_DIR
