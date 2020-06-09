
void plotEffArea(){

    gSystem->Load("$EVNDISPSYS/lib/libVAnaSum.so");
    VPlotInstrumentResponseFunction a;
    a.addInstrumentResponseData(
        "effArea-v501-TL5035MA20-auxv01-CARE-Cut-NTel2-PointSource-Moderate-Box-GEOID0-V6-ATM62-T1234.root",
        20., 0.5, 0, 2.0, 100, "A_REC"
    );
    a.plotEffectiveArea();

}