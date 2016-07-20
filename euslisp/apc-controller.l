;; vim: set ft=lisp:

(require "package://hrp2_models/euslisp/hrp2jsknts.l")
(require "package://hrp2_apc/euslisp/models/kiva-pod.l")
(require "package://hrp2_apc/euslisp/libs/util.l")


(defclass apc-controller
  :super propertied-object
  :slots (
          robot_
          kiva-pod_
          bin-coords_
          )
  )

(defmethod apc-controller
  (:init
    ()
    (setq robot_ (instance hrp2jsknts-robot :init))
    (setq kiva-pod_ (instance kiva-pod-object :init))
    (send kiva-pod_ :locate (float-vector 1350 0 0) :world)
    (send self :_init-bin-coords)
    )
  (:_init-bin-coords
    ()
    (let (bin-coords)
      ;; bin_a
      (pushback
        (cons :a
              (send (send kiva-pod_ :copy-worldcoords)
                    :translate (float-vector -410 410 1780) :world)
              )
        bin-coords)
      ;; bin_b
      (pushback
        (cons :b
              (send (send kiva-pod_ :copy-worldcoords)
                    :translate (float-vector -410 160 1780) :world)
              )
        bin-coords)
      ;; bin_c
      (pushback
        (cons :c
              (send (send kiva-pod_ :copy-worldcoords)
                    :translate (float-vector -410 -150 1780) :world)
              )
        bin-coords)
      ;; bin_d
      (pushback
        (cons :d
              (send (send kiva-pod_ :copy-worldcoords)
                    :translate (float-vector -410 410 1520) :world)
              )
        bin-coords)
      ;; bin_e
      (pushback
        (cons :e
              (send (send kiva-pod_ :copy-worldcoords)
                    :translate (float-vector -410 160 1520) :world)
              )
        bin-coords)
      ;; bin_f
      (pushback
        (cons :f
              (send (send kiva-pod_ :copy-worldcoords)
                    :translate (float-vector -410 -150 1520) :world)
              )
        bin-coords)
      ;; bin_g
      (pushback
        (cons :g
              (send (send kiva-pod_ :copy-worldcoords)
                    :translate (float-vector -410 410 1280) :world)
              )
        bin-coords)
      ;; bin_h
      (pushback
        (cons :h
              (send (send kiva-pod_ :copy-worldcoords)
                    :translate (float-vector -410 160 1280) :world)
              )
        bin-coords)
      ;; bin_i
      (pushback
        (cons :i
              (send (send kiva-pod_ :copy-worldcoords)
                    :translate (float-vector -410 -150 1280) :world)
              )
        bin-coords)
      ;; bin_j
      (pushback
        (cons :j
              (send (send kiva-pod_ :copy-worldcoords)
                    :translate (float-vector -410 410 1050) :world)
              )
        bin-coords)
      ;; bin_k
      (pushback
        (cons :k
              (send (send kiva-pod_ :copy-worldcoords)
                    :translate (float-vector -410 160 1050) :world)
              )
        bin-coords)
      ;; bin_l
      (pushback
        (cons :l
              (send (send kiva-pod_ :copy-worldcoords)
                    :translate (float-vector -410 -150 1050) :world)
              )
        bin-coords)
      (setq bin-coords_ (dict bin-coords))))
  (:draw-models
    ()
    (let ((object-list (list robot_ kiva-pod_)))
      (setq object-list
            (append object-list (send bin-coords_ :list-values)))
      (objects object-list)))
  )


(defun main ()
  (setq *controller* (instance apc-controller :init))
  (send *controller* :draw-models)
  )


;; __main__
(main)
