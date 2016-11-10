#!/usr/bin/env python

import argparse

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


def plot_v1(csv_file):
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


def plot_v2(csv_file):
    df = pd.DataFrame.from_csv(csv_file, index_col=None)
    print(df.columns)

    colors = sns.husl_palette(3, l=.5, s=.5)

    df_mv = df.query('single_view == False')
    t_start = df_mv.iloc[0].stamp
    df_sv = df.query('single_view == True')
    df_sv = df_sv.query('stamp >= {0}'.format(t_start))

    plt.subplot(211)
    # single-view
    elapsed_time = (df_sv.stamp - t_start) * 1e-9
    plt.plot(elapsed_time, df_sv.iu, color=colors[0],
             marker='o', label='Single View')
    # multi-views
    elapsed_time = (df_mv.stamp - t_start) * 1e-9
    plt.plot(elapsed_time, df_mv.iu, color=colors[1],
             marker='o', label='Multi Views')
    #
    plt.xlim(0, 40)
    plt.legend(loc='upper left')
    plt.ylabel('IU')

    # camera velocity
    elapsed_time = (df_mv.stamp - t_start) * 1e-9

    plt.subplot(212)
    plt.plot(elapsed_time, df_mv.camera_velocity * 1e3,
             marker='o', color=colors[2], label='camera velocity')
    plt.xlim(0, 40)
    plt.xlabel('Time [sec]')
    plt.ylabel('Camera Velocity [$10^-3$ m/s]')

    plt.show()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('csv_file')
    parser.add_argument('-v', '--version', type=int, default=2)
    args = parser.parse_args()

    csv_file = args.csv_file
    version = args.version

    if version == 1:
        plot_v1(csv_file)
    else:
        plot_v2(csv_file)


if __name__ == '__main__':
    main()
