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
    cube-list)
  )
