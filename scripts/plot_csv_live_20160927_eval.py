#!/usr/bin/env python

import argparse

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


parser = argparse.ArgumentParser()
parser.add_argument('csv_file')
args = parser.parse_args()

csv_file = args.csv_file

df = pd.DataFrame.from_csv(csv_file, index_col=None)
df = df.sort(columns='stamp')
print(df.columns)

colors = sns.husl_palette(4, l=.5, s=.5)

t_start = df.stamp[0]

ax1 = plt.subplot(211)
p1 = plt.plot(df.stamp - t_start, df.iu, color=colors[0], label='IU')
plt.legend(loc='center left')
plt.xlabel('Time [ns]')
plt.ylabel('IU')

ax2 = ax1.twinx()
ax2.set_ylabel('Volume [$m^2$]')
ax2.plot(df.stamp - t_start, df.volume_tp,
         color=colors[1], label='$V_{tp}$')
ax2.plot(df.stamp - t_start, df.volume_fn,
         color=colors[2], label='$V_{fn}$')
ax2.plot(df.stamp - t_start, df.volume_fp,
         color=colors[3], label='$V_{fp}$')
plt.legend(loc='center right')

plt.subplot(212)
plt.plot(df.stamp - t_start, df.camera_velocity,
         color=colors[0], label='camera velocity')
plt.legend(loc='upper right')
plt.xlabel('Time [ns]')
plt.ylabel('Camera Velocity')

plt.show()
