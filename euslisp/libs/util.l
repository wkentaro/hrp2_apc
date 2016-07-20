;; vim: set ft=lisp:


(defmacro pushback (el lst)
  `(if (null ,lst)
       (setf ,lst (list ,el))
     (nconc ,lst (list ,el))))


(defun zip (a b) (pairlis a b))


(defun dict (zipped)
  (let ((table (make-hash-table :test #'equal)))
    (dolist (el zipped)
      (sethash (car el) table (cdr el))
      )
    table))
