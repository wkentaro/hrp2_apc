(require "package://hrp2_apc/euslisp/models/kiva-pod-convex.l")

(defun kiva-pod-cubes ()
  (let* (cube-list (kiva-pod (instance kiva-pod-robot :init)))
    (dolist (body0 (send kiva-pod :bodies))
      (let* (cube)
        (setq cube
              (apply #'make-cube
                     (coerce
                      (scale 2
                             (v- (send (send body0 :box) :maxpoint)
                                 (send (send body0 :box) :minpoint)))
                      cons)))
        (send cube :locate (send (send body0 :box) :center))
        (push cube cube-list)
        ))
    (dolist (cube (cdr cube-list))
      (send (car cube-list) :assoc cube))
    cube-list))

(defclass kiva-pod-collision-object
  :super cascaded-link
  :slots ())
(defmethod kiva-pod-collision-object
  (:init
   ()
   (let (b)
     (send-super :init)
     (setq b (instance bodyset-link :init (make-cascoords) :bodies (kiva-pod-cubes)))
     (setq links (list b))
     (send self :assoc b)
     (send self :init-ending)
     self))
  )
