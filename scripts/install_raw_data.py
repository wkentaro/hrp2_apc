#!/usr/bin/env python

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from jsk_data import download_data


def main():
    PKG = 'hrp2_apc'

    download_data(
        pkg_name=PKG,
        path='raw_data/hrp2_rosbag_apc_look_around_2016-07-19-16-46-05.bag',
        url='https://drive.google.com/uc?id=0B5qanGnXorOuME83UHQ4Sm5YQTQ',
        md5='',
    )


if __name__ == '__main__':
    main()
