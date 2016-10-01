#!/usr/bin/env python

import argparse

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('csv_file')
    args = parser.parse_args()

    csv_file = args.csv_file

    df = pd.DataFrame.from_csv(csv_file, index_col=None)
    df = df[:-70]
    print(df.columns)

    colors = sns.husl_palette(4, l=.5, s=.5)

    t_start = df.iloc[0].stamp
    elapsed_time = (df.stamp - t_start) * 1e-9

    ax1 = plt.subplot(211)
    p1 = plt.plot(elapsed_time, df.iu, color=colors[0], label='IU')
    plt.legend(loc='center left')
    plt.ylabel('IU')

    ax2 = ax1.twinx()
    ax2.plot(elapsed_time, df.volume_tp * 1e3,
             color=colors[1], label='$V_{tp}$')
    ax2.plot(elapsed_time, df.volume_fn * 1e3,
             color=colors[2], label='$V_{fn}$')
    ax2.plot(elapsed_time, df.volume_fp * 1e3,
             color=colors[3], label='$V_{fp}$')
    ax2.set_ylabel('Volume [$10^-3 m^2$]')
    plt.legend(loc='center right')

    plt.subplot(212)
    plt.plot(elapsed_time, df.camera_velocity * 1e3,
             marker='o', color=colors[0], label='camera velocity')
    plt.xlabel('Time [sec]')
    plt.ylabel('Camera Velocity [$10^-3$ m/s]')

    plt.show()


if __name__ == '__main__':
    main()
