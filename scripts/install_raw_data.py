#!/usr/bin/env python

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from jsk_data import download_data


def main():
    PKG = 'hrp2_apc'

    download_data(
        pkg_name=PKG,
        path='raw_data/2016-07-19-16-46-05-hrp2_rosbag_apc_look_around.bag',
        url='https://drive.google.com/uc?id=0B9P1L--7Wd2vYmdYdjFmSHV4dkU',
        md5='d344dc71d4f545012fa7cdfa9dea4b15',
    )

    download_data(
        pkg_name=PKG,
        path='raw_data/hrp2_apc_2016-07-27-21-06-33.bag',
        url='https://drive.google.com/uc?id=0B9P1L--7Wd2vUTZjUHlfUVFSM1k',
        md5='9e575b0a7d630d050a3a42a7f5b364a1',
    )

    download_data(
        pkg=PKG,
        path='raw_data/hrp2_apc_2016-07-27-22-08-02.bag',
        url='https://drive.google.com/uc?id=0B9P1L--7Wd2vMDA4NW9YSEpoczQ',
        md5='9f43c592d1fd9a88b29117172be77a17',
    )


if __name__ == '__main__':
    main()
