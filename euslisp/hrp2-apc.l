(load "package://hrpsys_ros_bridge_tutorials/euslisp/hrp2jsknts-interface.l")
(load "package://hrp2_apc/euslisp/models/kiva-pod.l")
(load "package://hrp2_apc/euslisp/models/kiva-pod-cubes.l")
(load "package://hrp2_apc/euslisp/libs/util.l")

(load "package://pr2eus/speak.l")

(load "models/gifuplastic-900-cart-object.l")
(load "package://jsk_ik_server/euslisp/ik-evaluation.l")

;; setup ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun setup
  (&key (real? nil))
  (setup-robot :real? real?)
  (setup-object)
  (objects (append (list *robot* *kiva-pod* (send *kiva-pod* :get :collision-object)) (send *kiva-pod* :get :bin-cube-list)))
  (send *irtviewer* :change-background (float-vector 1 1 1))
  (send *irtviewer* :draw-objects)
  )

(defun setup-robot
  (&key (real? nil))
  (cond (real?
         (hrp2jsknts-init)
         (setq *robot* *hrp2jsknts*)
         )
        (t
         (setq *robot* (instance hrp2jsknts-robot :init))
         ))
  (send *robot* :fix-leg-to-coords (make-coords))

  (when real?
    (send *ri* :start-auto-balancer)
    (send *ri* :start-st)
    (send *ri* :start-impedance :arms)
    (send *ri* :reset-force-moment-offset-arms)

    (unless (and (boundp '*tf*) *tf*)
      (setq *tf* (instance ros::transform-listener :init)))
    (ros::subscribe "/checkerboard_detector0/objectdetection_pose" geometry_msgs::PoseStamped #'checkerboard-posest-cb)
    (ros::advertise "/interactive_adjust_kiva_pod/move_marker" geometry_msgs::PoseStamped 1)
    )
  )

(defun setup-object
  ()
  ;; instance
  (setq *kiva-pod* (instance kiva-pod-object :init))
  (send *kiva-pod* :put :collision-object (instance kiva-pod-collision-object :init))
  (send (send *kiva-pod* :get :collision-object) :newcoords (make-coords :pos (float-vector 0 0 1310.0)))
  (send *kiva-pod* :assoc (send *kiva-pod* :get :collision-object))
  (setq *cart* (instance gifuplastic-900-cart-object :init))

  ;; bin
  (let* ((bin-vertices-info
          (list
           (list :00 (float-vector -410 410 1780))
           (list :01 (float-vector -410 160 1780))
           (list :02 (float-vector -410 -150 1780))
           (list :03 (float-vector -410 -400 1780))
           (list :10 (float-vector -410 410 1520))
           (list :11 (float-vector -410 160 1520))
           (list :12 (float-vector -410 -150 1520))
           (list :13 (float-vector -410 -400 1520))
           (list :20 (float-vector -410 410 1280))
           (list :21 (float-vector -410 160 1280))
           (list :22 (float-vector -410 -150 1280))
           (list :23 (float-vector -410 -400 1280))
           (list :30 (float-vector -410 410 1050))
           (list :31 (float-vector -410 160 1050))
           (list :32 (float-vector -410 -150 1050))
           (list :33 (float-vector -410 -400 1050))
           (list :40 (float-vector -410 410 790))
           (list :41 (float-vector -410 160 790))
           (list :42 (float-vector -410 -150 790))
           (list :43 (float-vector -410 -400 790))
           ))
         (bin-depth 370)
         (bin-width-num 3)
         (bin-height-num 4)
         (bin-cube-list)
         )
    (dotimes (bin-height-id bin-height-num)
      (dotimes (bin-width-id bin-width-num)
        (let* ((bin-id (read-from-string (format nil ":~a~a" bin-height-id bin-width-id)))
               (next-bin-id (read-from-string (format nil ":~a~a" (1+ bin-height-id) (1+ bin-width-id))))
               (bin-pos (v+ (send *kiva-pod* :worldpos) (cadr (assoc bin-id bin-vertices-info))))
               (next-bin-pos (v+ (v+ (send *kiva-pod* :worldpos) (cadr (assoc next-bin-id bin-vertices-info))) (float-vector 370 0 0)))
               (bin-cube (apply #'make-cube (mapcar #'abs (coerce (v- bin-pos next-bin-pos) cons))))
               (bin-number (+ (* bin-width-num bin-height-id) bin-width-id))
               )
          (send bin-cube :set-color (float-vector 0 0 0) 0.0)
          (send bin-cube :name (read-from-string (format nil ":bin-~a" bin-number)))
          (send bin-cube :newcoords (make-coords :pos (midpoint 0.5 bin-pos next-bin-pos)))
          (when (or (= bin-number 6) (= bin-number 7) (= bin-number 8))
            (send bin-cube :translate (float-vector 0 0 30) :world))
          (send *kiva-pod* :assoc bin-cube)
          (send *kiva-pod* :put (read-from-string (format nil ":bin-~a" bin-number)) bin-cube)
          (send *kiva-pod* :put (read-from-string (format nil ":bin-~a" (int2char bin-number))) bin-cube)
          (push bin-cube bin-cube-list)
          )))
    (send *kiva-pod* :put :bin-cube-list bin-cube-list)
    )

  ;; spot
  (let* ((bin-jkl-reach-coords-relative-rarm
          (make-coords :pos (float-vector -525.0 325.0 -970.0) :rpy (list 0.349 0 0)))
         (bin-ghi-reach-coords-relative-rarm
          (make-coords :pos (float-vector -525.0 375.0 -1215.0) :rpy (list 0.349 0 0)))
         (bin-jkl-reach-coords-relative-larm
          (make-coords :pos (float-vector -525.0 -325.0 -970.0) :rpy (list -0.349 0 0)))
         (bin-ghi-reach-coords-relative-larm
          (make-coords :pos (float-vector -525.0 -375.0 -1215.0) :rpy (list -0.349 0 0)))
         )
    (dolist (bin-id (list :bin-j :bin-k :bin-l))
      (send *kiva-pod* :put (read-from-string (format nil "~a-reach-coords-rarm" bin-id))
            (make-cascoords
             :coords (send (send (send (send *kiva-pod* :get bin-id) :worldcoords) :copy-worldcoords)
                           :transform bin-jkl-reach-coords-relative-rarm :local)
             :parent *kiva-pod*))
      (send *kiva-pod* :put (read-from-string (format nil "~a-reach-coords-larm" bin-id))
            (make-cascoords
             :coords (send (send (send (send *kiva-pod* :get bin-id) :worldcoords) :copy-worldcoords)
                           :transform bin-jkl-reach-coords-relative-larm :local)
             :parent *kiva-pod*))
      )
    (dolist (bin-id (list :bin-g :bin-h :bin-i))
      (send *kiva-pod* :put (read-from-string (format nil "~a-reach-coords-rarm" bin-id))
            (make-cascoords
             :coords (send (send (send (send *kiva-pod* :get bin-id) :worldcoords) :copy-worldcoords)
                           :transform bin-ghi-reach-coords-relative-rarm :local)
             :parent *kiva-pod*))
      (send *kiva-pod* :put (read-from-string (format nil "~a-reach-coords-larm" bin-id))
            (make-cascoords
             :coords (send (send (send (send *kiva-pod* :get bin-id) :worldcoords) :copy-worldcoords)
                           :transform bin-ghi-reach-coords-relative-larm :local)
             :parent *kiva-pod*))
      )
    )
  (send *kiva-pod* :put :cart-reach-coords
        (make-cascoords
         :coords (send (send *kiva-pod* :copy-worldcoords) :transform
                       (make-coords :pos (float-vector -25.0 -50.0 1200.0) :rpy (list pi 0 pi/2)))
         :parent *kiva-pod*))

  ;; checkerboard
  (send *kiva-pod* :put :checkerboard
        (make-cascoords
         :coords (send (send (send (send *kiva-pod* :copy-worldcoords) :translate (float-vector -399.096 436.608 424.558) :local)
                             :rotate -pi/2 :x :local) :rotate pi/2 :z :local)
         :parent *kiva-pod*))

  ;; place
  (send *kiva-pod* :newcoords (make-coords :pos (float-vector 750 0 50) :rpy (list -pi/2 0 pi/2)))
  (send-all (send *kiva-pod* :bodies) :set-color :gray30 0.2)
  (send-all (send (send *kiva-pod* :get :collision-object) :bodies) :set-color #f(1 0 0) 0.1)
  )


;; demo ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun demo-hrp2-apc
  (&key (obj-name "cherokee_easy_tee_shirt")
        (bin-id :bin-l)
        (arm :rarm)
        (obj-place :left)
        (walk-dist-offset 0)
        )

  (when (or (and (equal arm :rarm) (equal obj-place :right)) (and (equal arm :larm) (equal obj-place :left)))
    (warning-message 1 "obj-place ~a is not supported for arm ~a.~%" obj-place arm)
    (return-from demo-hrp2-apc nil)
    )
  (when (and (or (equal bin-id :bin-g) (equal bin-id :bin-h) (equal bin-id :bin-i)) (equal obj-place :down))
    (warning-message 1 "obj-place ~a is not supported for bin-id ~a.~%" obj-place bin-id)
    (return-from demo-hrp2-apc nil)
    )
  (when (and (or (equal bin-id :bin-g) (equal bin-id :bin-h) (equal bin-id :bin-i)) (equal arm :larm))
    (warning-message 1 "arm ~a is not supported for bin-id ~a.~%" arm bin-id)
    (return-from demo-hrp2-apc nil)
    )

  (let* (ik-offset
         walk-offset
         (walk-dist 250)
         )
    (cond ((or (equal obj-place :left) (equal obj-place :right))
           (cond ((or (equal bin-id :bin-g) (equal bin-id :bin-h) (equal bin-id :bin-i))
                  (setq ik-offset (float-vector -50 -5 0)) ;; based on experiment with real robot
                  )
                 (t
                  (setq ik-offset (float-vector -50 0 0))
                  ))
           )
          (t ;; (equal obj-place :down)
           (setq ik-offset (float-vector -50 0 25))
           ))

    (set-target-bin-obj :bin-id bin-id :obj obj-name)

    (print-with-wait "walk-to-bin for look" "棚の見える位置へ移動します．")
    (walk-to-bin :bin-id bin-id :arm :rarm :offset (float-vector (- walk-dist) -300 0))

    (print-with-wait "look-around-bin" "棚の中を見ます．")
    (look-around-bin :bin-id bin-id)

    (print-with-wait "walk-to-bin for reach" "棚へ移動します．")
    (walk-to-bin :bin-id bin-id :arm arm :offset (float-vector (- walk-dist) 0 0))

    (print-with-wait "reach" "腕を伸ばします．")
    (solve-fullbody-ik :arm arm :bin-id bin-id :obj-place obj-place :offset (v+ ik-offset (float-vector -100 0 0)))
    (model2real)

    (solve-fullbody-ik :arm arm :bin-id bin-id :obj-place obj-place :offset ik-offset)
    (model2real)

    (open-hand)

    (print-with-wait "footstep-for-reach forward" "前に歩きます．")
    (footstep-for-reach :dir :forward :dist (+ walk-dist walk-dist-offset))

    (print-with-wait "grasp" "掴みます．")
    (cond ((equal obj-place :left)
           (cond ((or (equal bin-id :bin-g) (equal bin-id :bin-h) (equal bin-id :bin-i))
                  (send *robot* arm :move-end-pos #f(50 50 -50) :world) ;; based on experiment with real robot
                  )
                 (t
                  (send *robot* arm :move-end-pos #f(50 100 -50) :world)
                  ))
           )
          ((equal obj-place :right)
           (cond ((or (equal bin-id :bin-g) (equal bin-id :bin-h) (equal bin-id :bin-i))
                  (send *robot* arm :move-end-pos #f(50 -50 -50) :world) ;; based on experiment with real robot
                  )
                 (t
                  (send *robot* arm :move-end-pos #f(50 -100 -50) :world)
                  ))
           )
          (t ;; (equal obj-place :down)
           (send *robot* arm :move-end-pos #f(50 0 -80) :world)
           (send *robot* arm :move-end-rot 20 :z :local)
           ))
    (model2real)

    (close-hand)

    (solve-fullbody-ik :arm arm :bin-id bin-id :obj-place obj-place :offset ik-offset)
    (model2real)

    (print-with-wait "footstep-for-reach backward" "後ろに歩きます．")
    (footstep-for-reach :dir :backward :dist (- (+ walk-dist walk-dist-offset)))

    (print-with-wait "walk-from-bin-to-thoth" "台車へ移動します．")
    (walk-from-bin-to-thoth :arm arm :obj-place obj-place)

    (print-with-wait "release-object-to-thoth" "台車に置きます．")
    (release-object-to-thoth :arm arm)
    (model2real)

    (open-hand)

    (send *robot* :reset-manip-pose)
    (model2real)

    (print-with-wait "walk-from-thoth-to-bin" "棚へ移動します．")
    (walk-from-thoth-to-bin)
    ))
;; (demo-hrp2-apc :arm :rarm :obj-place :left :bin-id :bin-l)
;; (demo-hrp2-apc :arm :rarm :obj-place :down :bin-id :bin-l)
;; (demo-hrp2-apc :arm :larm :obj-place :right :bin-id :bin-k)
;; (demo-hrp2-apc :arm :rarm :obj-place :left :bin-id :bin-i)

;; recognition ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun checkerboard-posest-cb
  (msg)
  (setq *checkerboard-coords* (ros::tf-pose->coords (send msg :pose)))
  (warning-message 2 "detect checkerboard: ~a~%" *checkerboard-coords*)
  )

(defun get-checkerboard-pose
  (&key (fix-for :kiva-pod))
  (let* ((camera-relative-checkerboard-coords)
         (leg-to-camera-transformation)
         (leg-relative-checkerboard-coords)
         (world-relative-checkerboard-coords)
         (world-relative-checkerboard-coords-fixed)
         )
    (setq *checkerboard-coords* nil)
    (while t
      (when *checkerboard-coords*
        (setq camera-relative-checkerboard-coords (send *checkerboard-coords* :copy-worldcoords))
        (setq leg-to-camera-transformation (send *tf* :lookup-transform "lleg_end_coords" "camera_rgb_optical_frame" (ros::time 0)))
        (cond (leg-to-camera-transformation
               (setq leg-to-camera-transformation (send leg-to-camera-transformation :copy-worldcoords))
               )
              (t
               (warning-message 1 "tf transformation error in update-pepperbox-pose~%")
               (return-from update-pepperbox-pose nil)
               ))
        (setq leg-relative-checkerboard-coords
              (send leg-to-camera-transformation :transform camera-relative-checkerboard-coords :local))
        (setq world-relative-checkerboard-coords
              (send (send (send *robot* :lleg :end-coords) :copy-worldcoords)
                    :transform leg-relative-checkerboard-coords :local))

        (cond ((equal fix-for :kiva-pod)
               (setq world-relative-checkerboard-coords-fixed
                     (send (send (send (send world-relative-checkerboard-coords :copy-worldcoords)
                                       :rotate pi/2 :x :local) :rotate pi/2 :y :local) :rotate pi/2 :z :local))
               (setq world-relative-checkerboard-coords-fixed
                     (make-coords
                      :pos (float-vector (elt (send world-relative-checkerboard-coords-fixed :worldpos) 0)
                                         (elt (send world-relative-checkerboard-coords-fixed :worldpos) 1)
                                         (elt (send (send *kiva-pod* :get :checkerboard) :worldpos) 2))
                      :rpy (list (elt (car (rpy-angle (send world-relative-checkerboard-coords-fixed :worldrot))) 0) 0 0)))
               )
              ((equal fix-for :cart)
               (setq world-relative-checkerboard-coords-fixed
                     (send (send (send world-relative-checkerboard-coords :copy-worldcoords)
                                 :rotate pi :x :local) :rotate pi/2 :z :local))
               (setq world-relative-checkerboard-coords-fixed
                     (make-coords
                      :pos (float-vector (elt (send world-relative-checkerboard-coords-fixed :worldpos) 0)
                                         (elt (send world-relative-checkerboard-coords-fixed :worldpos) 1)
                                         0)
                      :rpy (list (elt (car (rpy-angle (send world-relative-checkerboard-coords-fixed :worldrot))) 0) 0 0)))

               )
              (t
               (setq world-relative-checkerboard-coords-fixed world-relative-checkerboard-coords)
               ))
        (return))
      (ros::spin-once))
    world-relative-checkerboard-coords-fixed))

(defun get-checkerboard-pose-average
  (&key (fix-for :kiva-pod)
        (ave-num 4)
        (pos-thre 25)
        (rot-thre 0.2)
        )
  (let* (checkerboard-pose
         checkerboard-pose-ave
         (cnt 0))
    (while (< cnt ave-num)
      (setq checkerboard-pose (get-checkerboard-pose :fix-for fix-for))
      (cond ((= cnt 0)
             (setq checkerboard-pose-ave checkerboard-pose)
             )
            ((or (> (norm (send checkerboard-pose-ave :difference-position checkerboard-pose)) pos-thre)
                 (> (norm (send checkerboard-pose-ave :difference-rotation checkerboard-pose)) rot-thre))
             (setq checkerboard-pose-ave checkerboard-pose)
             (setq cnt 0)
             )
            (t
             (setq checkerboard-pose-ave (midcoords (/ (float cnt) (1+ cnt)) checkerboard-pose checkerboard-pose-ave))
             ))
      (incf cnt)
      )
    checkerboard-pose-ave))

(defun place-robot-relative-to-kiva-pod
  ()
  ;; (send *robot* :fix-leg-to-coords
  ;;       (send (send (send *robot* :foot-midcoords) :copy-worldcoords)
  ;;             :transform (send *a* :transformation (send (send *kiva-pod* :get :checkerboard) :copy-worldcoords) :local) :local))
  (send *robot* :move-coords (send (send *kiva-pod* :get :checkerboard) :copy-worldcoords) (get-checkerboard-pose-average :fix-for :kiva-pod))
  (send *irtviewer* :draw-objects)
  )

(defun publish-kiva-pod-pose
  ()
  (place-robot-relative-to-kiva-pod)
  (let* ((msg (instance geometry_msgs::PoseStamped :init))
         (hdr (instance std_msgs::header :init :stamp (ros::time-now) :frame_id "BODY"))
         (kiva-pod-coords
          (send (send (car (send *robot* :links)) :copy-worldcoords)
                :transformation (send (send *kiva-pod* :get :collision-object) :copy-worldcoords) :local))
         (kiva-pod-pose
          (ros::coords->tf-pose kiva-pod-coords))
         )
    (send msg :header hdr)
    (send msg :pose kiva-pod-pose)
    (ros::publish "/interactive_adjust_kiva_pod/move_marker" msg)
    ))

;; motion ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun solve-fullbody-ik
  (&key (arm :rarm)
        (bin-id :bin-11)
        (obj-place :left)
        (offset (float-vector 0 0 0))
        )
  (let* ((av-orig (copy-seq (send *robot* :angle-vector)))
         (foot-midcoords-orig (send (send *robot* :foot-midcoords) :copy-worldcoords))
         ik-ret
         )
    (send *robot* :reset-pose)
    (send *robot* arm :wrist-p :joint-angle 0)
    (send *robot* arm :wrist-r :joint-angle 0)

    (send *robot* :fix-leg-to-coords
          (send *kiva-pod* :get (read-from-string (format nil "~a-reach-coords-~a" bin-id (string-downcase (string arm))))))

    (let* ((target-rpy
            (cond ((or (and (equal obj-place :left) (equal arm :rarm)) (and (equal obj-place :right) (equal arm :larm)))
                   (list 0 0 0)
                   )
                  ((or (and (equal obj-place :left) (equal arm :larm)) (and (equal obj-place :right) (equal arm :rarm)))
                   (list 0 0 pi)
                   )
                  ((equal obj-place :down)
                   (list 0 0 -pi/2)
                   )))
           (tc
            (append (list (make-coords :pos (send (send *kiva-pod* :get bin-id) :centroid) :rpy target-rpy))
                    (send-all (send *robot* :legs :end-coords) :copy-worldcoords)
                    (list (send (send *robot* :head :end-coords) :copy-worldcoords))))
           (mt
            (append (list (send *robot* arm :end-coords))
                    (send *robot* :legs :end-coords)
                    (list (send *robot* :head :end-coords))))
           (ll
            (mapcar #'(lambda (mt) (send *robot* :link-list (send mt :parent))) mt))
           )
      (setq ik-ret
            (send *robot* :fullbody-inverse-kinematics
                  tc
                  :move-target mt
                  :link-list ll
                  :thre (list 10 1 1 10)
                  :rthre (list (deg2rad 10) (deg2rad 1) (deg2rad 1) (deg2rad 10))
                  :cog-gain 0.2
                  :centroid-thre 50
                  :translation-axis (list t t t nil)
                  :rotation-axis (list t t t nil)
                  :loop 1000
                  :max (float-vector 500 500 0 20 20 10)
                  :additional-weight-list
                  (list (list (send *robot* :rleg :crotch-r :child-link) 0)
                        (list (send *robot* :lleg :crotch-r :child-link) 0)
                        (list (send *robot* :rleg :ankle-r :child-link) 0)
                        (list (send *robot* :lleg :ankle-r :child-link) 0)
                        (list (send *robot* :rleg :toe-p :child-link) 0)
                        (list (send *robot* :lleg :toe-p :child-link) 0)
                        (list (send *robot* arm :wrist-p :child-link) 0)
                        (list (send *robot* arm :wrist-r :child-link) 0)
                        )
                  :look-at-target t
                  :debug-view :no-message
                  :collision (send *kiva-pod* :get :collision-object)
                  :check-collision t
                  :additional-check #'(lambda () (> (car (mapcar #'(lambda (c) (car c)) (send *robot* :get :collision-distance))) 10.0)) ;; this threshold should be same with collision-distance-limit
                  :avoid-collision-distance 150
                  :avoid-collision-null-gain 10.0
                  :avoid-collision-joint-gain 0.8
                  :collision-distance-limit 10.0
                  :collision-avoidance-link-pair
                  (mapcar #'(lambda (rl) (list rl (car (send (send *kiva-pod* :get :collision-object) :links)))) (send *robot* :head))
                  ))
      (when (eps> (norm offset) 0.0) (send *robot* arm :move-end-pos offset :world))
      )
    (unless ik-ret
      (send *robot* :angle-vector av-orig))
    (send *robot* :fix-leg-to-coords foot-midcoords-orig)
    ik-ret))

(defun walk-to-bin
  (&key (bin-id :bin-l)
        (arm :arm)
        (offset (float-vector -250 0 0)))
  ;; recog
  (send *robot* :reset-manip-pose)
  (send *robot* :head :neck-y :joint-angle 30)
  (model2real :tm 3000)
  (place-robot-relative-to-kiva-pod)

  ;; walk
  (let* ((reach-coords
          (send (send (send *kiva-pod* :get (read-from-string (format nil "~a-reach-coords-~a" bin-id (string-downcase (string arm))))) :copy-worldcoords) :translate offset :world))
         (reach-coords-relative-to-robot
          (send (send (send *robot* :foot-midcoords) :copy-worldcoords) :transformation reach-coords :local))
         go-pos-x go-pos-y go-pos-theta
         )
    (send *robot* :fix-leg-to-coords reach-coords)
    (send *irtviewer* :draw-objects)
    (setq go-pos-x (* 0.001 (elt (send reach-coords-relative-to-robot :worldpos) 0)))
    (setq go-pos-y (* 0.001 (elt (send reach-coords-relative-to-robot :worldpos) 1)))
    (setq go-pos-theta (rad2deg (elt (car (rpy-angle (send reach-coords-relative-to-robot :worldrot))) 0)))
    (warning-message 2 "press Enter for go-pos ~a ~a ~a~%" go-pos-x go-pos-y go-pos-theta)
    (when (y-or-n-p)
      (send *ri* :go-pos go-pos-x go-pos-y go-pos-theta))
    ))

(defun look-around-bin
  (&key (bin-id :bin-l))

  (publish-kiva-pod-pose)

  (let* ((foot-midcoords-orig (send (send *robot* :foot-midcoords) :copy-worldcoords))
         (neck-y-angle -20)
         (neck-p-offset 0)
         (neck-p-step 15)
         )
    (when (or (equal bin-id :bin-g) (equal bin-id :bin-h) (equal bin-id :bin-i))
      (setq neck-p-offset -20))

    ;; clear serivce

    (send *robot* :reset-manip-pose)
    (send *robot* :legs :move-end-pos (float-vector 0 0 150) :world)
    (send *robot* :fix-leg-to-coords foot-midcoords-orig)
    (send *robot* :head :neck-y :joint-angle neck-y-angle)
    (send *robot* :head :neck-p :joint-angle (- (+ 15 neck-p-offset) neck-p-step))
    (model2real :tm 8000)
    ;; update service
    (send *robot* :head :neck-p :joint-angle neck-p-step :relative t)
    (model2real :tm 1000)
    ;; update service
    (send *robot* :head :neck-p :joint-angle neck-p-step :relative t)
    (model2real :tm 1000)
    ;; update service

    (send *robot* :reset-manip-pose)
    (send *robot* :legs :move-end-pos (float-vector 0 0 100) :world)
    (send *robot* :fix-leg-to-coords foot-midcoords-orig)
    (send *robot* :head :neck-y :joint-angle neck-y-angle)
    (send *robot* :head :neck-p :joint-angle (- (+ 20 neck-p-offset) neck-p-step))
    (model2real :tm 2000)
    ;; update service
    (send *robot* :head :neck-p :joint-angle neck-p-step :relative t)
    (model2real :tm 1000)
    ;; update service
    (send *robot* :head :neck-p :joint-angle neck-p-step :relative t)
    (model2real :tm 1000)
    ;; update service

    (send *robot* :reset-manip-pose)
    (send *robot* :legs :move-end-pos (float-vector 0 0 50) :world)
    (send *robot* :fix-leg-to-coords foot-midcoords-orig)
    (send *robot* :head :neck-y :joint-angle neck-y-angle)
    (send *robot* :head :neck-p :joint-angle (- (+ 25 neck-p-offset) neck-p-step))
    (model2real :tm 2000)
    ;; update service
    (send *robot* :head :neck-p :joint-angle neck-p-step :relative t)
    (model2real :tm 1000)
    ;; update service
    (send *robot* :head :neck-p :joint-angle neck-p-step :relative t)
    (model2real :tm 1000)
    ;; update service

    (send *robot* :reset-manip-pose)
    (send *robot* :fix-leg-to-coords foot-midcoords-orig)
    (send *robot* :head :neck-y :joint-angle neck-y-angle)
    (send *robot* :head :neck-p :joint-angle (+ 30 neck-p-offset))
    (model2real :tm 2000)
    ;; update service
    (send *robot* :head :neck-p :joint-angle neck-p-step :relative t)
    (model2real :tm 1000)
    ;; update service
    (send *robot* :head :neck-p :joint-angle neck-p-step :relative t)
    (model2real :tm 1000)
    ;; update service
    )
  )

(defun footstep-for-reach
  (&key (dir :forward) (dist 0))
  (let* (lleg-coords-orig
         rleg-coords-orig
         lleg-coords-new
         rleg-coords-new
         footstep-list
         (step (if (equal dir :forward) 80 -40))
         )
    (when (or (and (equal dir :forward) (< dist 0)) (and (equal dir :backward) (> dist 0)))
      (warning-message 1 "walking direction and distance are not match.~%")
      (return-from footstep-for-reach nil))

    (setq lleg-coords-orig (send (send *robot* :lleg :end-coords) :copy-worldcoords))
    (setq rleg-coords-orig (send (send *robot* :rleg :end-coords) :copy-worldcoords))
    (send lleg-coords-orig :name :lleg)
    (send rleg-coords-orig :name :rleg)

    (cond ((or (and (equal dir :forward) (>= (elt (send lleg-coords-orig :worldpos) 0) (elt (send rleg-coords-orig :worldpos) 0)))
               (and (equal dir :backward) (>= (elt (send rleg-coords-orig :worldpos) 0) (elt (send lleg-coords-orig :worldpos) 0))))
           (push rleg-coords-orig footstep-list)
           )
          (t
           (push lleg-coords-orig footstep-list)
           ))

    (while t
      (when (eps= (float dist) 0.0)
        (cond ((equal (send (car footstep-list) :name) :lleg)
               (push rleg-coords-new footstep-list)
               )
              (t
               (push lleg-coords-new footstep-list)
               ))
        (return))

      (when (or (and (equal dir :forward) (<= (- dist step) 0)) (and (equal dir :backward) (>= (- dist step) 0)))
        (setq step dist))

      (setq dist (- dist step))

      (send *robot* :translate (float-vector step 0 0) :world)
      (setq lleg-coords-new (send (send *robot* :lleg :end-coords) :copy-worldcoords))
      (setq rleg-coords-new (send (send *robot* :rleg :end-coords) :copy-worldcoords))
      (send lleg-coords-new :name :lleg)
      (send rleg-coords-new :name :rleg)

      (cond ((equal (send (car footstep-list) :name) :lleg)
             (push rleg-coords-new footstep-list)
             )
            (t
             (push lleg-coords-new footstep-list)
             ))

      )

    (setq footstep-list (reverse footstep-list))
    (setq *footstep-list* footstep-list)

    (send *ri* :set-auto-balancer-param :is-hand-fix-mode t)
    (send *ri* :set-foot-steps-no-wait footstep-list)
    (send *ri* :wait-foot-steps)
    (send *ri* :set-auto-balancer-param :is-hand-fix-mode nil)
    )
  )

(defun walk-from-bin-to-thoth
  (&key (obj-place :left) (arm :rarm))

  (send *robot* :reset-manip-pose)
  (send *robot* :head :neck-y :joint-angle 30)
  (when (equal obj-place :down)
    (send *robot* arm :move-end-rot (if (equal arm :larm) 90 -90) :x :local))
  (model2real)

  (let* ((reach-coords
          (send *kiva-pod* :get :cart-reach-coords))
         (reach-coords-relative-to-robot
          (send (send (send *robot* :foot-midcoords) :copy-worldcoords) :transformation reach-coords :local))
         go-pos-x go-pos-y go-pos-theta
         )
    (send *robot* :fix-leg-to-coords reach-coords)
    (send *irtviewer* :draw-objects)
    (setq go-pos-x (* 0.001 (elt (send reach-coords-relative-to-robot :worldpos) 0)))
    (setq go-pos-y (* 0.001 (elt (send reach-coords-relative-to-robot :worldpos) 1)))
    (setq go-pos-theta (rad2deg (elt (car (rpy-angle (send reach-coords-relative-to-robot :worldrot))) 0)))
    (warning-message 2 "press Enter for go-pos ~a ~a ~a~%" go-pos-x go-pos-y go-pos-theta)
    (when (y-or-n-p)
      (send *ri* :go-pos go-pos-x go-pos-y go-pos-theta))
    )

  (let* ((reach-coords
          (send (get-checkerboard-pose-average :fix-for :cart) :translate (float-vector -750 -600 0) :local))
         (reach-coords-relative-to-robot
          (send (send (send *robot* :foot-midcoords) :copy-worldcoords) :transformation reach-coords :local))
         go-pos-x go-pos-y go-pos-theta
         )
    (send *robot* :fix-leg-to-coords reach-coords)
    (send *irtviewer* :draw-objects)
    (setq go-pos-x (* 0.001 (elt (send reach-coords-relative-to-robot :worldpos) 0)))
    (setq go-pos-y (* 0.001 (elt (send reach-coords-relative-to-robot :worldpos) 1)))
    (setq go-pos-theta (rad2deg (elt (car (rpy-angle (send reach-coords-relative-to-robot :worldrot))) 0)))
    (warning-message 2 "press Enter for go-pos ~a ~a ~a~%" go-pos-x go-pos-y go-pos-theta)
    (when (y-or-n-p)
      (send *ri* :go-pos go-pos-x go-pos-y go-pos-theta))
    )
  )

(defun walk-from-thoth-to-bin
  ()
  (send *ri* :go-pos -0.3 0 -90)
  )


(defun release-object-to-thoth
  (&key (arm :rarm))
  (let* ((av-orig (copy-seq (send *robot* :angle-vector)))
         (foot-midcoords-orig (send (send *robot* :foot-midcoords) :copy-worldcoords))
         ik-ret
         )
    (let* ((tc
            (append (list (send (send (send (send *robot* :foot-midcoords) :copy-worldcoords) :translate (float-vector 500 0 400) :local) :rotate (if (equal arm :larm) pi/2 -pi/2) :x :local))
                    (send-all (send *robot* :legs :end-coords) :copy-worldcoords)))
           (mt
            (append (list (send *robot* arm :end-coords))
                    (send *robot* :legs :end-coords)))
           (ll
            (mapcar #'(lambda (mt) (send *robot* :link-list (send mt :parent))) mt))
           )
      (send *robot* :reset-manip-pose)
      (send *robot* :fix-leg-to-coords foot-midcoords-orig)
      (setq ik-ret
            (send *robot* :fullbody-inverse-kinematics
                  tc
                  :move-target mt
                  :link-list ll
                  :thre (list 20 1 1)
                  :rthre (list (deg2rad 10) (deg2rad 1) (deg2rad 1))
                  :cog-gain 0.1
                  :centroid-thre 50
                  :translation-axis (list t t t)
                  :rotation-axis (list :z t t)
                  :loop 1000
                  :max (float-vector 500 500 0 20 20 10)
                  :additional-weight-list
                  (list (list (send *robot* :rleg :toe-p :child-link) 0)
                        (list (send *robot* :lleg :toe-p :child-link) 0)
                        )
                  :look-at-target t
                  :debug-view :no-message
                  ))
      )
    (unless ik-ret
      (send *robot* :angle-vector av-orig))
    (send *robot* :fix-leg-to-coords foot-midcoords-orig)
    ik-ret))


;; collision ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun check-collision
  (&key (robot *robot*) (obj (send *kiva-pod* :get :collision-object)) (link-list (send robot :links))
        (draw? t) (bool? t) (hand? :root) (only-check? nil))
  "check collision between robot and object
   arguments:
     robot: instance of robot
     obj: instance of object
     link-list: list of robot link
     draw?: whether to draw or not
     bool?: whether to return boolean value or collision list
     hand?: whether to contain hand to robot link.
            nil for not contain hand link.
            :root for contain only hand root link.
            t for contain all hand links (hand root link and finger link)
     only-check?: whether to check only collision existence or search collision link
  "
  (let* (res)
    (cond
     ((equal hand? :root)
      (when (and (member :hand (send robot :methods)) (send robot :hand :arms))
        (setq link-list (append link-list (flatten (mapcar #'car (send-all (send robot :hand :arms) :links))))))
      )
     (hand?
      (when (and (member :hand (send robot :methods)) (send robot :hand :arms))
        (setq link-list (append link-list (flatten (send-all (send robot :hand :arms) :links)))))
      ))
    (cond
     (only-check?
      (dolist (l link-list)
        (let* ((coll-res (pqp-collision-check l obj)))
          (unless (= coll-res 0)
            (cond (bool? (setq res t))
                  (t (push (list l obj)) res))
            (return))))
      )
     (t
      (dolist (l link-list)
        (let* ((coll-res (pqp-collision-distance l obj)))
          (when (<= (car coll-res) 0)
            (when (and draw? (boundp '*irtviewer*)) (send (elt coll-res 1) :draw-on :flush t :size 100 :width 5 :color #f(1 0 0)))
            (when bool? (setq res t) (return))
            (push (list l (elt coll-res 1)) res))))
      ))
    res))


;; analyze ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun draw-reachability-map
  (&key (arm :rarm) (obj-place :left))
  (let* ((target-rpy
          (cond ((or (and (equal obj-place :left) (equal arm :rarm)) (and (equal obj-place :right) (equal arm :larm)))
                 (list 0 0 0)
                 )
                ((or (and (equal obj-place :left) (equal arm :larm)) (and (equal obj-place :right) (equal arm :rarm)))
                 (list 0 0 pi)
                 )
                ((equal obj-place :down)
                 (list 0 0 -pi/2)
                 ))
          )
         )
    (setq *rmap* (instance ik-grid :init (cons 0.0 800.0) (cons -600.0 600.0) (cons 800.0 2000.0) :grid-step 100))
    ;; (ik-evaluation *robot* *rmap* arm (list :rotation-axis :z)
    ;;                :rotation (send (make-coords :rpy target-rpy) :worldrot))
    (ik-evaluation *robot* *rmap* arm
                   (list :additional-weight-list
                         (list (list (send *robot* :rleg :crotch-r :child-link) 0)
                               (list (send *robot* :lleg :crotch-r :child-link) 0)
                               (list (send *robot* :rleg :ankle-r :child-link) 0)
                               (list (send *robot* :lleg :ankle-r :child-link) 0)
                               (list (send *robot* :rleg :toe-p :child-link) 0)
                               (list (send *robot* :lleg :toe-p :child-link) 0)
                               (list (send *robot* arm :wrist-p :child-link) 0)
                               (list (send *robot* arm :wrist-r :child-link) 0))
                         )
                   :rotation (send (make-coords :rpy target-rpy) :worldrot)
                   :initial-pose (progn (send *robot* :reset-pose) (send *robot* arm :wrist-p :joint-angle 0) (send *robot* arm :wrist-r :joint-angle 0) (send *robot* :angle-vector))
                   :fullbody t
                   :update-view nil
                   )
    (objects (append (send *rmap* :get-cubes) (list *robot* *kiva-pod*)))
    ))

;; test ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun test-fullbody-ik-for-bin
  ()
  (dolist (arm (list :larm :rarm))
    (dolist (bin-id (list :bin-g :bin-h :bin-i :bin-j :bin-k :bin-l))
      (unless (and (or (equal bin-id :bin-g) (equal bin-id :bin-h) (equal bin-id :bin-i)) (equal arm :larm))
        ;; left
        (unless (equal arm :larm)
          (warning-message 2 "test-fullbody-ik  bin: ~a obj-place: ~a arm: ~a~%" bin-id :left arm)
          (send *robot* :fix-leg-to-coords (send *kiva-pod* :get (read-from-string (format nil "~a-reach-coords-~a" bin-id (string-downcase (string arm))))))
          (solve-fullbody-ik :arm arm :bin-id bin-id :obj-place :left :offset (float-vector -50 0 0))
          (send *robot* arm :move-end-pos #f(50 100 -50) :world)
          )

        ;; right
        (unless (equal arm :rarm)
          (warning-message 2 "test-fullbody-ik  bin: ~a obj-place: ~a arm: ~a~%" bin-id :right arm)
          (send *robot* :fix-leg-to-coords (send *kiva-pod* :get (read-from-string (format nil "~a-reach-coords-~a" bin-id (string-downcase (string arm))))))
          (solve-fullbody-ik :arm arm :bin-id bin-id :obj-place :right :offset (float-vector -50 0 0))
          (send *robot* arm :move-end-pos #f(50 -100 -50) :world)
          )

        ;; down
        (unless (or (equal bin-id :bin-g) (equal bin-id :bin-h) (equal bin-id :bin-i))
          (warning-message 2 "test-fullbody-ik  bin: ~a obj-place: ~a arm: ~a~%" bin-id :down arm)
          (send *robot* :fix-leg-to-coords (send *kiva-pod* :get (read-from-string (format nil "~a-reach-coords-~a" bin-id (string-downcase (string arm))))))
          (solve-fullbody-ik :arm arm :bin-id bin-id :obj-place :down :offset (float-vector -50 0 25))
          (send *robot* arm :move-end-pos #f(50 0 -80) :world)
          (send *robot* arm :move-end-rot 20 :z :local)
          )
        )))
  )

(defun test-collision-check
  ()
  (setup)

  (send *robot* :reset-manip-pose)
  (send *irtviewer* :draw-objects)
  (warning-message 2 "collision check result: ref: ~a act: ~a~%" nil (check-collision))
  (read-line)

  (send *robot* :rarm :move-end-pos (float-vector 100 0 0) :world)
  (send *irtviewer* :draw-objects)
  (warning-message 2 "collision check result: ref: ~a act: ~a~%" t (check-collision))
  (read-line)

  (send *robot* :rarm :move-end-pos (float-vector 0 40 0) :world)
  (send *irtviewer* :draw-objects)
  (warning-message 2 "collision check result: ref: ~a act: ~a~%" nil (check-collision))
  (read-line)

  (send *robot* :rarm :move-end-pos (float-vector 100 0 0) :world)
  (send *irtviewer* :draw-objects)
  (warning-message 2 "collision check result: ref: ~a act: ~a~%" nil (check-collision))
  (read-line)

  (send *robot* :rarm :move-end-pos (float-vector 100 0 0) :world)
  (send *irtviewer* :draw-objects)
  (warning-message 2 "collision check result: ref: ~a act: ~a~%" nil (check-collision))
  (read-line)

  (send *robot* :rarm :move-end-pos (float-vector 0 0 100) :world)
  (send *irtviewer* :draw-objects)
  (warning-message 2 "collision check result: ref: ~a act: ~a~%" t (check-collision))
  (read-line)

  (send *robot* :rarm :move-end-pos (float-vector 0 0 150) :world)
  (send *irtviewer* :draw-objects)
  (warning-message 2 "collision check result: ref: ~a act: ~a~%" nil (check-collision))
  (read-line)
  )

(defun draw-footstep-for-reach
  (&key (footstep-list *footstep-list*))
  (dolist (footstep footstep-list)
    (send footstep :draw-on :flush t :size 50 :width 5 :color (if (equal (send footstep :name) :lleg) #f(1 0 0) #f(0 1 0)))
    (read-line)
    )
  )


;; utils ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun set-target-bin-obj
  (&key (bin-id :bin-l) (obj "cherokee_easy_tee_shirt"))
  (ros::set-dynamic-reconfigure-param "/hrp2_apc/bbox_array_to_bbox" "index" :int (get-int-from-bin-id bin-id))
  (ros::set-dynamic-reconfigure-param "/hrp2_apc/fcn/label_to_mask" "label_value" :int (position obj (ros::get-param "/hrp2_apc/fcn/label_names") :test #'string=))
  )
;; (ros::set-dynamic-reconfigure-param "/hrp2_apc/bbox_array_to_bbox" "index" :int 11)
;; (ros::set-dynamic-reconfigure-param "/hrp2_apc/fcn/label_to_mask" "label_value" :int (position "cherokee_easy_tee_shirt" (ros::get-param "/hrp2_apc/fcn/label_names") :test #'string=))

(defun int2char
  (value)
  (coerce (list (+ (car (coerce "a" cons)) value)) string)
  )

(defun char2int
  (value)
  (- (car (coerce value cons)) (car (coerce "a" cons)))
  )

(defun get-int-from-bin-id
  (bin-id)
  (let* ((bin-id-char (car (last (coerce (format nil "~a" bin-id) cons)))))
    (cond ((digit-char-p bin-id-char) ;; bin-0
           (warning-message 1 "not supported yet.~%")
           nil)
          (t ;; bin-a
           (- bin-id-char (car (coerce "a" cons)))
           ))
    ))

(defun model2real
  (&key (tm 5000) (wait? t))
  "send angle-vector.
   arguments:
     tm: time of interpolation [msec]
  "
  (send *ri* :angle-vector (send *robot* :angle-vector) tm)
  (when wait? (send *ri* :wait-interpolation))
  )

(defun hand-model2real
  (&key (wait? t))
  "send hand angle-vector.
   arguments:
     tm: time of interpolation [msec]
  "
  (send *ri* :hand-angle-vector (apply #'concatenate float-vector (send-all (send *robot* :hand :arms) :angle-vector)))
  (when wait? (send *ri* :hand-wait-interpolation))
  )

(defun open-hand
  ()
  (send *robot* :hand :arms :angle-vector #f(90.0 90.0 0.0 0.0 -20.0 -20.0))
  (hand-model2real)
  )

(defun close-hand
  ()
  (send *robot* :hand :arms :angle-vector #f(90.0 0.0 0.0 0.0 -20.0 90.0))
  (hand-model2real)
  )

(defun calib-hand
  ()
  (send *ri* :hand-joint-calib)
  )

(defun print-with-wait
  (text &optional speak-text)
  (when speak-text
    (speak-jp speak-text))
  (while t (when (y-or-n-p (format nil "~a " text)) (return)))
  )
