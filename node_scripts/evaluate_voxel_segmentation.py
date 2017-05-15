#!/usr/bin/env python

from __future__ import division
from __future__ import print_function

import os.path as osp

import numpy as np

from jsk_recognition_msgs.msg import BoundingBox
import rospkg
import rospy
import tf
from visualization_msgs.msg import MarkerArray


def compute_iu_between_voxels_and_bbox(marker_array, bbox):
    bbox_volume = bbox.dimensions.x * bbox.dimensions.y * bbox.dimensions.z
    bbox_center = bbox.pose.position
    bbox_min_pt = (
        bbox_center.x - bbox.dimensions.x / 2,
        bbox_center.y - bbox.dimensions.y / 2,
        bbox_center.z - bbox.dimensions.z / 2,
    )
    bbox_max_pt = (
        bbox_center.x + bbox.dimensions.x / 2,
        bbox_center.y + bbox.dimensions.y / 2,
        bbox_center.z + bbox.dimensions.z / 2,
    )
    true_positive = 0
    false_positive = 0
    for marker in marker_array.markers:
        assert bbox.header.frame_id == marker.header.frame_id
        marker_volume = marker.scale.x * marker.scale.y * marker.scale.z
        for point in marker.points:
            if bbox_min_pt[0] <= point.x <= bbox_max_pt[0] and \
               bbox_min_pt[1] <= point.y <= bbox_max_pt[1] and \
               bbox_min_pt[2] <= point.z <= bbox_max_pt[2]:
                true_positive += marker_volume
            else:
                false_positive += marker_volume
    false_negative = bbox_volume - true_positive

    # intersect over union
    iu = true_positive / (true_positive + false_negative + false_positive)
    return iu, true_positive, false_negative, false_positive


class EvaluateVoxelOctomap(object):

    def __init__(self):
        # key is is_single_view
        self.prev_stamp = {True: rospy.Time(0), False: rospy.Time(0)}

        self.bbox = None
        self.tf_listener = tf.TransformListener()
        rp = rospkg.RosPack()
        # TODO(wkentaro): Generalize path
        self.log_file = osp.join(rp.get_path('hrp2_apc'), 'log.txt')
        with open(self.log_file, 'a') as f:
            f.write('stamp,camera_velocity,volume_tp,volume_fn,volume_fp,iu,single_view\n')
        self.subscribe()

    def subscribe(self):
        self.sub_box_gt = rospy.Subscriber(
            '~input/bbox_gt', BoundingBox, self.cb_bbox)
        self.sub_voxels = rospy.Subscriber(
            '~input/voxels', MarkerArray, self.cb_voxels,
            callback_args=False)
        self.sub_voxels_single_view = rospy.Subscriber(
            '~input/voxels_single_view', MarkerArray, self.cb_voxels,
            callback_args=True)

    def cb_bbox(self, bbox_msg):
        self.bbox = bbox_msg
        self.sub_box_gt.unregister()

    def cb_voxels(self, marker_array_msg, is_single_view):
        stamp = marker_array_msg.markers[0].header.stamp
        if stamp < self.prev_stamp[is_single_view]:
            rospy.logwarn('Time is reversed, skipping.')
            return
        self.prev_stamp[is_single_view] = stamp
        # TODO(wkentaro): Generalize frames
        if self.bbox is None:
            rospy.logerr('Bounding box annotated by human is not set.')
            return
        try:
            vel_linear, _ = self.tf_listener.lookupTwist(
                "camera_link", "HEAD_LINK0",
                rospy.Time(0), rospy.Duration(1.0))
        except tf.ExtrapolationException as e:
            rospy.logerr(e)
            return
        velocity = np.linalg.norm(list(vel_linear))
        iu, tp, fn, fp = compute_iu_between_voxels_and_bbox(
            marker_array_msg,
            self.bbox,
        )
        with open(self.log_file, 'a') as f:
            f.write('{stamp},{vel},{tp},{fn},{fp},{iu},{is_sv}\n'
                    .format(stamp=stamp.to_nsec(),
                            vel=velocity,
                            tp=tp, fn=fn, fp=fp, iu=iu,
                            is_sv=is_single_view))


if __name__ == '__main__':
    rospy.init_node('evaluate_voxel_segmentation')
    evaluator = EvaluateVoxelOctomap()
    rospy.spin()
