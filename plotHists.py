#!/usr/bin/python3

import matplotlib.pyplot as plt
import numpy as np
import sys

if __name__ == '__main__':

    time_file = sys.argv[1] if len(sys.argv) > 1 else 'time.lis'
    size_file = sys.argv[2] if len(sys.argv) > 2 else 'size.lis'

    size = np.loadtxt(size_file, unpack=True)
    time = np.loadtxt(time_file, unpack=True)
    time = [t / 60 for t in time]

    plt.figure(figsize=(8, 6))
    ax = plt.gca()
    ax.set_xlabel('size')

    ax.hist(size, bins=150)

    plt.show()

    plt.figure(figsize=(8, 6))
    ax = plt.gca()
    ax.set_xlabel('runtime [min]')

    ax.hist(time, bins=150)

    plt.show()

    if len(size) == len(time):

        plt.figure(figsize=(8, 6))
        ax = plt.gca()
        ax.set_xlabel('size')
        ax.set_ylabel('runtime [min]')

        ax.scatter(size, time, s=5)

        plt.show()
