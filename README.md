Scripts for VERITAS MC production at DESY

Author: Raul R Prado (raul.prado@desy.de)

- Software installed in $(DESY_SCRATCH)/prado/sw
- files at lustre
- usage, subGrOptics
- subManyGeneric
- 


ISSUES:

    - Wrong arguments to collect_arguments function breaks the code without error message


SOFTWARES

- VBF
  - v0.3.4
  - $RAUL/sw/CARE/VBF-0.3.4
  - source $RAUL/loadVBF.sh

- GrOptics
  - v4.2.1
  - $RAUL/sw/GrOptics

- CARE
  - v1.6.3
  - $RAUL/sw/CARE


BUG REPORT - EFF. AREA MISMATCH BETWEEN DESY AND GATECH PRODUCTION - Aug. 2019

- CONFIG FILES

  - In GrOptics pilot file: * ARRAYCONFIG ./Config/VERITAS_NewArray.cfg

  - In VERITAS_NewArray.cfg: * TELFAC DC GRISU ./Config/Upgrade_20120827_v420_3.cfg ./Config/VERITAS_NewArray.cfg

  - CARE std cfg file: config/CARE/CARE_VERITAS_AfterPMTUpgrade_V6Nahee_withPMTransitTimeSpread.cfg

