# hrp2_apc

3D Object Segmentation for Shelf Bin Picking by Humanoid with Deep Learning and Occupancy Voxel Grid Map


<a href="https://www.youtube.com/watch?v=4zKFnVIGB_I">
 <img src="http://i3.ytimg.com/vi/4zKFnVIGB_I/maxresdefault.jpg" width="50%" />
</a>
<p>
  <a href="https://www.youtube.com/watch?v=4zKFnVIGB_I">
    <i>https://www.youtube.com/watch?v=4zKFnVIGB_I</i>
  </a>
</p>

## Citation

```bib
@InProceedings{Wada:etal:Humanoids2016,
  title={{3D Object Segmentation for Shelf Bin Picking by Humanoid with Deep Learning and Occupancy Voxel Grid Map}},
  author={Kentaro Wada and Masaki Murooka and Kei Okada and Masayuki Inaba},
  booktitle={Proceedings of the IEEE-RAS International Conference on Humanoid Robots (Humanoids)},
  year={2016},
}
```

## Installation

```bash
mkdir -p ~/catkin_ws/src
cd ~/catkin_ws
catkin init

wstool init src https://raw.githubusercontent.com/wkentaro/hrp2_apc/master/rosinstall
rosdep install --from-path . -r -y -i
catkin build

export ROBOT=HRP2JSKNTS
```

## Usage

Download rosbag data.

```bash
rosrun hrp2_apc install_raw_data.py
```

Looking around demo.

```bash
roslaunch hrp2_apc hrp2_rosbag_apc_look_around.launch
```

## Private

-  Paper: <https://github.com/wkentaro/hrp2_apc-paper>
-  Data: <https://drive.google.com/drive/u/1/folders/0B9P1L--7Wd2vUWlQcnZLY0FPeDA>
