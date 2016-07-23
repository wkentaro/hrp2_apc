#!/usr/bin/env python

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function


from jsk_rviz_plugins.msg import OverlayText
import rospy


def callback(event):
    target_label_value = rospy.get_param('~target_label_value', None)
    lines = []
    for label_value, label_name in enumerate(label_names):
        color = 'green' if label_value == target_label_value else 'white'
        lines.append('<span style="color: {};">{}: {}</span>'
                     .format(color, label_value, label_name))
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
    rospy.init_node('label_names_overlay')
    pub = rospy.Publisher("~output", OverlayText, queue_size=1)
    label_names = rospy.get_param('~label_names')
    timer = rospy.Timer(rospy.Duration(1), callback)
    rospy.spin()
