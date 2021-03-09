#!/bin/zsh

# export VBFSYS=/afs/ifh.de/group/cta/scratch/prado/sw/libVBF
export FITSSYS=/afs/ifh.de/group/cta/VERITAS/software/FITS/cfitsio

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$VBFSYS/lib
export PATH=$VBFSYS/bin:$VBFSYS/include:$PATH

