#!/bin/zsh

export VBFSYS=/afs/ifh.de/group/cta/scratch/prado/sw/libVBF

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$VBFSYS/lib
export PATH=$VBFSYS/bin:$VBFSYS/include:$PATH

