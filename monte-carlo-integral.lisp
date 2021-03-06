(setq *read-default-float-format* 'double-float)
;; (ql:quickload :lparallel)
;; (setf lparallel:*kernel* (lparallel:make-kernel 2))

;; Monte Carlo Integral
(defun std-deviation (sample)
  (let* ((sample-size (length sample))
	 (mean (/ (reduce #'+ sample) sample-size))
	 (diff-squared (lambda (x) (expt (- x mean) 2))))
    (sqrt (/ (reduce #'+ (mapcar diff-squared sample))
	     sample-size))))

(defun monte-carlo-integral (func inits ends sample-size &key (constraint nil))
  "5 outputs: estimated value of integral, standard deviation of integral, accepted rate in sample, estimated volume (constraint) and standard deviation of volume"
  (let ((sample nil)
	(intervals (mapcar #'- ends inits))
	(volume 0.0e0)
	(sample-point nil)
	(cnt-accept 0)
	(accept-rate 0)
	(result 0.0e0))
    (setf volume (float (reduce #'* intervals)))
    (dotimes (i sample-size)
      (setf sample-point
	    (mapcar (lambda (x y) (+ x (* (random 1.0e0) y))) inits intervals))
      (when (or (null constraint) (apply constraint sample-point))
	(push (apply func sample-point) sample)
	(incf cnt-accept)))
    (setf accept-rate (/ cnt-accept sample-size)
	  result (* (reduce #'+ sample) (/ volume sample-size)))
    (let ((estmtd-vol (* accept-rate volume))
	  (stdev 0.0e0))
      (setf stdev (/ (std-deviation (mapcar (lambda (x) (* estmtd-vol x)) sample)) (sqrt cnt-accept)))
      (values result stdev accept-rate estmtd-vol (/ estmtd-vol (sqrt sample-size))))))

;; (defun monte-carlo-integral-map (func init end sample-size)
;;   (let ((sample (make-array sample-size
;; 			    :element-type *read-default-float-format*
;; 			    :initial-element 1.0e0))
;; 	(interval (- end init))
;; 	(result 0.0e0)
;; 	(abs-err 0.03e0))
;;     (setf sample (map 'vector
;; 		      (lambda (x) (+ init (* interval (random x))))
;; 		      sample))
;;     (setf sample (map 'vector func sample))
;;     (setf result (/ (* (reduce #'+ sample) interval) sample-size))
;;     (setf abs-err (/ result (sqrt sample-size)))
;;     (values result abs-err)))


(defun example-monte-carlo-integral ()
  (let ((value 0)
	(stdev 0)
	(acc-rate 0)
	(estimated-vol 0)
	(vol-stdev 0)
	(unit-3dim-ball (lambda (x y) (* 2 (sqrt (- 1.0e0 (* x x) (* y y))))))
	(in-unit-disk (lambda (x y) (< (+ (* x x) (* y y)) 1.0))))
    (setf (values value stdev acc-rate estimated-vol vol-stdev)
	  (monte-carlo-integral unit-3dim-ball '(-1 -1) '(1 1) 1000000
				:constraint in-unit-disk))
    (format t "sample-size: 1,000,000~%")
    (format t "Integrated value: (exact) 4*pi/3 = 4.18879..., (MC) ~6Fpm~,5F(1sigma)~%" value stdev)
    (format t "Area: (exact) pi, (MC) ~6Fpm~,5F(1simga)~%" estimated-vol vol-stdev)))
