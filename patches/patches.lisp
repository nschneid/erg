(in-package "MAIN")


#|
;; In /usr/local/page2.3/src/nutshell/protocols/call-eng-scanner.lisp
;; Corrected top level scanner call to eliminate punctuation.

(in-package "MAIN")

(defmethod call-component ((cpu controller)
			   (target eng-scanner)
			   &key direction)
  (declare (ignore direction))
  (let ((in (input-stream target)))
    (if (setf (output-stream target)
	  (strings-to-typed-items 
	     (remove-if #'(lambda (x)
			    (unless (consp x)
			      (member (char x 0) %special-chars% 
				      :test #'char-equal)))
			(eng-scan-input in t nil))))
	:forward
      :backward))
  nil)
|#

(progn
  (in-package :cl-user)
  (load (dir-and-name *source-grammar* "mrsglobals-eng"))
  (setf mrs::*ordered-mrs-rule-list* nil) 
  (with-open-file (istream (dir-and-name (dir-append tdl::*source-grammar* 
						     "data/")
					 "raw1.rules")
		   :direction :input)
    (loop (let ((rule (read istream nil nil)))
	    (unless rule (return))
	    (push rule mrs::*ordered-mrs-rule-list*))))
  (setf mrs::*ordered-mrs-rule-list* 
    (nreverse mrs::*ordered-mrs-rule-list*))
  (load (dir-and-name (dir-append tdl::*source-grammar* 
				  "data/")
		      "page-db-eng.lisp"))
  (setq mrs::%vit-indent% ",~%    ")
  (setq mrs::*mrs-to-vit* t)
  )

(setf trees::*label-names* 
   '("CONJ" "S" "S-R" "ADV" "ADV-R" "ADV-D" "P-N" "P-I" "P-S" "PP-N" "PP-I" "PP-S" "N" "NP" "ADJ" "VP" "V" "DET" "COMP" "NEG" "XP" "B")
;'("CONJ" "ADV" "PP" "NP" "ADJ" "VP" "V" "S" "P" "DET" "N" "COMP" "NEG" "XP" "B")
   trees::*node-labels* (trees::ordered-label-list)
   trees::*meta-symbols* (trees::get-instances :meta) foo nil)


(in-package "MAIN")




