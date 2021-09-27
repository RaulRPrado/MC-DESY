#!/usr/bin/python3

import matplotlib.pyplot as plt
import numpy as np
import argparse
import math
import os.path
from matplotlib.backends.backend_pdf import PdfPages

import ROOT

labelsize = 15
plt.rc('font', family='serif', size=labelsize)
plt.rc('xtick', labelsize=labelsize)
plt.rc('ytick', labelsize=labelsize)
plt.rc('text', usetex=True)


def check_woff(atm, zenith, wobble, nsb, pdf):
    print('check_woff({}, {}, {}, {})'.format(atm, zenith, wobble, nsb))

    woff_rad = list()
    for i_split in range(10):
        run = str(961201 + i_split)
        try:
            filename = (
                '/lustre/fs23/group/veritas/V6_DESY/EffAreaTesting/v501/CARE/V6_ATM'
                + str(atm) + '_gamma_ze' + str(zenith)
                + '_TL5035MA20/ze' + str(zenith) + 'deg_offset' + str(wobble) + 'deg_NSB'
                + str(nsb) + 'MHz/' + run + '.root'
            )

            if not os.path.isfile(filename):
                # print('File {} does not exists'.format(filename))
                continue

            try:
                file = ROOT.TFile.Open(filename)
            except:
                print('Could not open file {}'.format(filename))
                continue

            nInFile = 0
            for entry in file.showerpars:
                if float(entry.Xoff[0]) > -99 and not float(entry.Xoff[0]) == 0.:
                    woff_rad.append(math.sqrt(entry.Xoff[0]**2 + entry.Yoff[0]**2))
                    nInFile += 1
                if nInFile > 10000:
                    break

        except:
            print('Could not read file for run {}'.format(run))
            continue

    mean_woff = np.sum(woff_rad) / len(woff_rad)
    diff = math.fabs(mean_woff - float(wobble))
    sigma = np.std(woff_rad)

    fig = plt.figure(figsize=(8, 6), tight_layout=True)

    ax = plt.gca()
    ax.set_title('NSB = {}, mu = {:.3f}, sigma = {:.3f}'.format(nsb, mean_woff, sigma))
    ax.set_xlabel('Woff')

    ax.hist(woff_rad, bins=np.linspace(0.0, 2.5, 100))

    pdf.savefig(fig)
    plt.close()

    return


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
    parser.add_argument(
        '-w',
        '--wobble',
        help='Wobble offset',
        type=float,
        required=False,
        choices=[0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    )
    zenith = parser.parse_args().zenith
    atm = parser.parse_args().atm
    wob = parser.parse_args().wobble

    if wob is None:
        all_wobble = [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
        figName = 'figures/Woff_atm{}_ze{}.pdf'.format(atm, zenith)
    else:
        all_wobble = [wob]
        figName = 'figures/Woff_atm{}_ze{}_wob{}.pdf'.format(atm, zenith, wob)

    all_nsb = [50, 75, 100, 130, 160, 200, 250, 300, 350, 400, 450]
    # all_nsb = [50]

    with PdfPages(figName) as pdf:
        for nsb in all_nsb:
            for wob in all_wobble:
                check_woff(atm, zenith, wob, nsb, pdf)
