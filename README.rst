hrp2_apc
========

3D object segmentation for shelf bin picking by humanoid with deep learning and occupancy voxel grid map.


Citation
--------

.. code-block:: bib

  @inproceedings{wada20163d,
    title={3D object segmentation for shelf bin picking by humanoid with deep learning and occupancy voxel grid map},
    author={Wada, Kentaro and Murooka, Masaki and Okada, Kei and Inaba, Masayuki},
    booktitle={Humanoid Robots (Humanoids), 2016 IEEE-RAS 16th International Conference on},
    pages={1149--1154},
    year={2016},
    organization={IEEE}
  }


Installation
------------

.. code-block:: bash

  mkdir -p ~/catkin_ws/src
  cd ~/catkin_ws
  catkin init

  wstool init src https://raw.githubusercontent.com/wkentaro/hrp2_apc/master/rosinstall
  rosdep install --from-path . -r -y -i
  catkin build

  export ROBOT=HRP2JSKNTS


Usage
-----

Download rosbag data.

.. code-block:: bash

  rosrun hrp2_apc install_raw_data.py


Looking around demo.

.. code-block:: bash

  roslaunch hrp2_apc hrp2_rosbag_apc_look_around.launch


Private
-------

- Paper: https://github.com/wkentaro/hrp2_apc-paper
- Data: https://drive.google.com/drive/u/1/folders/0B9P1L--7Wd2vUWlQcnZLY0FPeDA
