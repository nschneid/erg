;;; LinGO big grammar specific functions


(defun preprocess-sentence-string (str)
  ;; replace all punctuation by spaces
  ;; except
  ;; for PAGE compatability, replace #\' by #\space
  ;; except at end of word, when replace by #\space #\s
  (let ((chars (coerce str 'list))
        (result-chars nil))
    (do* ((next-char (car chars) (car remainder))
          (remainder (cdr chars) (cdr remainder)))
         ((null next-char) nil)
         (cond ((eql next-char #\')
                (if (or (null remainder) (eql (car remainder) #\space))
                    (progn
                      (push #\space result-chars)
                      (push #\s result-chars))
                  (push #\space result-chars)))
               ((not (alphanumericp next-char)) 
                (push #\space result-chars))
               (t (push next-char result-chars))))
    (string-trim '(#\space) (coerce (nreverse result-chars) 'string))))
            
(defun establish-linear-precedence (rule-fs)
   ;;;    A function which will order the features of a rule
   ;;;    to give (mother daughter1 ... daughtern)
   ;;;    
   ;;;  Modification - this must always give a feature
   ;;;  position for the mother - it can be NIL if
   ;;; necessary
  (let* ((mother NIL)
         (daughter1 (get-value-at-end-of rule-fs '(ARGS FIRST)))
         (daughter2 (get-value-at-end-of rule-fs '(ARGS REST FIRST)))) 
    (unless (and daughter1 (not (eql daughter1 'no-way-through)))
      (cerror "Ignore it" "Rule without daughter"))
    (append (list nil '(ARGS FIRST))
            (if (and daughter2 (not (eql daughter2 'no-way-through)))
                (list '(ARGS REST FIRST))))))


(defun spelling-change-rule-p (rule)
;;; a function which is used to prevent the parser 
;;; trying to apply a rule which affects spelling and
;;; which should therefore only be applied by the morphology
;;; system.  
;;; Old test was for something which was a subtype of
;;; *morph-rule-type* - this tests for 
;;; < NEEDS-AFFIX > = +
;;; in the rule
  (let ((affix (get-dag-value (tdfs-indef 
                               (rule-full-fs rule)) 'needs-affix)))
    (and affix (equal (type-of-fs affix) '(+)))))

(defun redundancy-rule-p (rule)
;;; a function which is used to prevent the parser 
;;; trying to apply a rule which is only used
;;; as a redundancy rule 
;;; this version tests for 
;;; < PRODUCTIVE > = -
;;; in the rule
  (let ((affix (get-dag-value 
                (tdfs-indef (rule-full-fs rule)) 'productive)))
    (and affix (equal (type-of-fs affix) '(-)))))
             

;;; return true for types that shouldn't be displayed in type hierarchy
;;; window. None of their descendents (if any) will be displayed either

(defun hide-in-type-hierarchy-p (type-name)
   ;; starts with _, or ends with _[0-9][M]LE[0-9]
   (and (symbolp type-name)
      (or
         ;; graphs are pretty unreadable without glbtypes in there as well
         ;; (search "GLBTYPE" (symbol-name type-name))
         (eql (char (symbol-name type-name) 0) #\_)
         (let* ((name (symbol-name type-name))
                (end (length name))
                (cur (position #\_ name :from-end t)))
            ;; wish I had a regexp package available...
            (and cur
               (< (incf cur) end)
               (if (digit-char-p (char name cur)) (< (incf cur) end) t)
               (if (eql (char name cur) #\M) (< (incf cur) end) t)
               (if (eql (char name cur) #\L) (< (incf cur) end))
               (if (eql (char name cur) #\E) (<= (incf cur) end))
               (or (= cur end)
                   (and (digit-char-p (char name cur)) (= (incf cur) end))))))))

