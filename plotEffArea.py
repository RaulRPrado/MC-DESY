#!/usr/bin/python3

import matplotlib.pyplot as plt
import numpy as np
import argparse
from matplotlib.backends.backend_pdf import PdfPages
import os.path

import ROOT

labelsize = 15
plt.rc('font', family='serif', size=labelsize)
plt.rc('xtick', labelsize=labelsize)
plt.rc('ytick', labelsize=labelsize)
plt.rc('text', usetex=True)


def get_eff_area(atm, zenith, wobble, nsb, azimuth=0, index=2.0):
    filename = (
        '/lustre/fs23/group/veritas/V6_DESY/EffAreaTesting/v501/CARE/V6_ATM'
        + str(atm) + '_gamma_ze' + str(zenith)
        + '_TL5035MA20/EffectiveAreas_Cut-NTel2-PointSource-Moderate-Box/'
        + 'EffArea-CARE-V6-ID0-Ze' + str(zenith) + 'deg-' + str(wobble) + 'wob-' + str(nsb)
        + '-Cut-NTel2-PointSource-Moderate-Box.root'
    )

    lge, eff, eff_err = list(), list(), list()

    if not os.path.isfile(filename):
        print('File {} does not exists'.format(filename))
        return None, None, None

    file = ROOT.TFile.Open(filename)
    for entry in file.fEffArea:
        if entry.az == azimuth and entry.index == index:
            lge = list(entry.e0)
            eff = list(entry.eff)
            eff_err = list(entry.eff_error)
            return lge, eff, eff_err
        else:
            continue
    print('get_eff_area failed')
    return None, None, None


if __name__ == '__main__':

    parser = argparse.ArgumentParser(
        description='Plot Eff Area for a certain zenith angle simulation set.'
    )
    parser.add_argument(
        '-z',
        '--zenith',
        help='Zenith angle (in deg)',
        type=str,
        required=True,
        choices=['00', '20', '30', '35', '40', '45', '50', '55', '60']
    )
    parser.add_argument(
        '-a',
        '--atm',
        help='Atm (61 or 62)',
        type=str,
        required=True,
        choices=['61', '62']
    )
    zenith = parser.parse_args().zenith
    atm = parser.parse_args().atm

    all_wobble = [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    all_nsb = [50, 75, 100, 130, 160, 200, 250, 300, 350, 400, 450]

    figName = 'figures/EffArea_atm{}_ze{}_comparingWobble.pdf'.format(atm, zenith)
    with PdfPages(figName) as pdf:
        for nsb in all_nsb:
            print('Starting NSB {}'.format(nsb))
            fig = plt.figure(figsize=(8, 6), tight_layout=True)

            ax = plt.gca()
            ax.set_yscale('log')
            ax.set_xlabel(r'log$_{10}$($E$/TeV)')
            ax.set_ylabel(r'$A_\mathrm{eff}$ (cm$^2$)')
            ax.set_title('NSB {} MHz'.format(nsb))

            for wob in all_wobble:
                lge, eff, eff_err = get_eff_area(atm, zenith, wob, nsb)
                if lge is None:
                    continue
                ax.errorbar(
                    lge,
                    eff,
                    yerr=eff_err,
                    marker='o',
                    linestyle='none',
                    label='{} deg'.format(wob)
                )

            ax.set_ylim(1, 1e6)
            ax.set_xlim(-1.5, 2.5)

            ax.legend(frameon=False, ncol=2, loc='best')
            pdf.savefig(fig)
            plt.close()

    figName = 'figures/EffArea_atm{}_ze{}_comparingNSB.pdf'.format(atm, zenith)
    with PdfPages(figName) as pdf:
        for wob in all_wobble:
            print('Starting Wobble {}'.format(wob))
            fig = plt.figure(figsize=(8, 6), tight_layout=True)

            ax = plt.gca()
            ax.set_yscale('log')
            ax.set_xlabel(r'log$_{10}$($E$/TeV)')
            ax.set_ylabel(r'$A_\mathrm{eff}$ (cm$^2$)')
            ax.set_title('Offset {} deg'.format(wob))

            for nsb in all_nsb:
                lge, eff, eff_err = get_eff_area(atm, zenith, wob, nsb)
                if lge is None:
                    continue
                ax.errorbar(
                    lge,
                    eff,
                    yerr=eff_err,
                    marker='o',
                    linestyle='none',
                    label='{} MHz'.format(nsb)
                )

            ax.set_ylim(1, 1e6)
            ax.set_xlim(-1.5, 2.5)

            ax.legend(frameon=False, ncol=2, loc='best')
            pdf.savefig(fig)
            plt.close()

    # if show:
    #     plt.show()
    # else:
    #     plt.savefig(
    #         'figures/NumberRecProd3b.png',
    #         format='png',
    #         bbox_inches='tight'
    #     )
    #     plt.savefig(
    #         'figures/NumberRecProd3b.pdf',
    #         format='pdf',
    #         bbox_inches='tight'
    #     )
