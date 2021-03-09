#!/usr/bin/python3

import matplotlib.pyplot as plt
import numpy as np
import argparse
import os.path
import sys
import math
from matplotlib.backends.backend_pdf import PdfPages

import ROOT

labelsize = 15
plt.rc('font', family='serif', size=labelsize)
plt.rc('xtick', labelsize=labelsize)
plt.rc('ytick', labelsize=labelsize)
plt.rc('text', usetex=True)


def get_eff_area(filename, azimuth=0, index=2.0):
    lge, eff, eff_err = list(), list(), list()

    if not os.path.isfile(filename):
        print('File {} does not exists'.format(filename))
        return None, None, None

    file = ROOT.TFile.Open(filename)
    for entry in file.fEffArea:
        if (entry.az == azimuth and entry.index == index):
            lge = list(entry.e0)
            eff = list(entry.eff)
            eff_err = list(entry.eff_error)
            return lge, eff, eff_err
        else:
            continue
    print('get_eff_area failed')
    return None, None, None


if __name__ == '__main__':

    if len(sys.argv) != 3:
        print('Wrong number of args')
        exit()

    lge0, eff0, eff_err0 = get_eff_area(sys.argv[1])
    lge1, eff1, eff_err1 = get_eff_area(sys.argv[2])

    print(lge0)
    print(lge1)

    diff = list()
    rel_err0, rel_err1 = list(), list()
    for i in range(len(lge0)):
        d = (eff0[i] - eff1[i]) / math.sqrt(eff_err0[i]*eff_err0[i] + eff_err1[i]*eff_err1[i])
        diff.append(d)
        rel_err0.append(eff_err0[i] / eff0[i])
        rel_err1.append(eff_err1[i] / eff1[i])

    figName = 'figures/EffArea_testingSplit.pdf'
    with PdfPages(figName) as pdf:
        fig = plt.figure(figsize=(8, 6), tight_layout=True)
        ax = plt.gca()
        ax.set_yscale('log')
        ax.set_xlabel(r'log$_{10}$($E$/TeV)')
        ax.set_ylabel(r'$A_\mathrm{eff}$ (cm$^2$)')

        ax.errorbar(
            lge0,
            eff0,
            yerr=eff_err0,
            marker='o',
            linestyle='none'
        )
        ax.errorbar(
            lge1,
            eff1,
            yerr=eff_err1,
            marker='s',
            linestyle='none',
            markersize=15,
            fillstyle='none'
        )

        ax.set_ylim(1, 1e6)
        ax.set_xlim(-1.5, 2.5)

        pdf.savefig(fig)
        plt.close()

        fig = plt.figure(figsize=(8, 6), tight_layout=True)
        ax = plt.gca()
        ax.set_xlabel(r'log$_{10}$($E$/TeV)')
        ax.set_ylabel(r'$\sigma$ / A')

        ax.errorbar(
            lge0,
            rel_err0,
            marker='o',
            linestyle='none'
        )
        ax.errorbar(
            lge1,
            rel_err1,
            marker='s',
            linestyle='none',
            markersize=15,
            fillstyle='none'
        )

        ax.set_ylim(0, 0.5)
        ax.set_xlim(-1.5, 2.5)

        pdf.savefig(fig)
        plt.close()

        fig = plt.figure(figsize=(8, 6), tight_layout=True)
        ax = plt.gca()
        ax.set_xlabel(r'log$_{10}$($E$/TeV)')
        ax.set_ylabel(r'$\Delta/\sigma$')

        ax.errorbar(
            lge0,
            diff,
            marker='o',
            linestyle='none'
        )

        ax.plot(
            [-1.5, 2.5],
            [0, 0],
            color='k',
            linestyle='--'
        )

        ax.set_ylim(-0.5, 0.5)
        ax.set_xlim(-1.5, 2.5)

        pdf.savefig(fig)
        plt.close()
