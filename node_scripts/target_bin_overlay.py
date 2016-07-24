#!/usr/bin/env python

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function


from jsk_rviz_plugins.msg import OverlayText
import rospy


def callback(event):
    target_bin_index = rospy.get_param('~target_bin_index', None)
    lines = []
    for bin_index, bin_name in enumerate(bin_names):
        color = 'green' if bin_index == target_bin_index else 'white'
        lines.append('<span style="color: {};">{}: {}</span>'
                     .format(color, bin_index, bin_name))
    text = OverlayText()
    text.left = 20
    text.top = 20
    text.width = 1200
    text.height = 1200
    text.fg_color.a = 1.0
    text.fg_color.r = 0.3
    text.text_size = 12
    text.text = '\n'.join(lines)
    pub.publish(text)


if __name__ == '__main__':
    rospy.init_node('target_bin_overlay')
    pub = rospy.Publisher("~output", OverlayText, queue_size=1)
    bin_names = rospy.get_param('~bin_names')
    timer = rospy.Timer(rospy.Duration(1), callback)
    rospy.spin()
