;;;
;;; a couple of _temporary_ patches to LKB system code for better generation
;;;                                                           (9-dec-03; oe)
;;;

(in-package :lkb)


;;; For better batch testing of MRS quality, esp produce-one-scope()

; In lkb/src/mrs/mrsresolve.lsp, modified chain-down-margs() to also allow
; for top-level conjunctions (including discourse relation) - clearly
; grammar-specific, so should probably be in user-fns.lsp, or should
; have global in this function bound to list of grammar-specific feature
; names.

(in-package :mrs)
(defun chain-down-margs (rel mrsstruct)
  (let* ((marg-fvp (dolist (fvpair (rel-flist rel))
		    (when (or (eq (fvpair-feature fvpair) 'lkb::marg)
                              (eq (fvpair-feature fvpair) 'lkb::r-hndl)
                              (eq (fvpair-feature fvpair) 'lkb::main))
		      (return fvpair))))
	(marg-value 
	 (if marg-fvp
	       (get-var-num (fvpair-value marg-fvp)))))
    (if marg-value
	(let ((top-rels
	       (get-rels-with-label-num marg-value mrsstruct)))
	  (if top-rels
	      (if (cdr top-rels)
		  nil
		(chain-down-margs (car top-rels) mrsstruct))
	    (dolist (qeq (psoa-h-cons mrsstruct))
	      (when (eq marg-value (var-id (hcons-scarg qeq)))
		(return (values qeq marg-fvp)))))))))


; In mrs/idioms.lisp
; Added check in idiom_rel-p() since mt::transfer-mrs() is surprised at
; finding a predicate name as value of ARG1 for degree specifiers of
; quantifiers (as in "almost every") and assigns a "u" type variable,
; which this function did not expect as value of PRED.
(in-package :lkb)
(defun idiom-rel-p (rel)
  ;;; FIX
  ;;; relation name ends with _i or -i -- this won't quite do because
  ;;; we want to allow for different senses and anyway this should use the
  ;;; standard pred parsing code
  (setf myrel rel)
  (let* ((relpred (mrs::rel-pred rel))
         (relname (when (and relpred 
                             (or (symbolp relpred) (stringp relpred)))
                    (string-downcase relpred))))
    (and relname
         (or 
          (equal "_i" (subseq relname (- (length relname) 2)))
          (equal "-i" (subseq relname (- (length relname) 2)))))))


; In lkb/src/lexdb/headers.lsp
; Added "5" to load-foreign-types for 64-bit
(defun psql-initialize ()
  (unless (libpq-p)
    #+:linux
    (let (#+allegro 
	  (excl::*load-foreign-types* 
	   (append '("3" "4" "5") excl::*load-foreign-types*))
	  )
      (load-libpq '("libpq.so.5" "libpq.so" "libpq.so.4" "libpq.so.3")))
    #+:mswindows
    (load-libpq '("libpq.dll"))
    #-(or :linux :mswindows)
    (load-libpq nil)))

(setf ppcre:*use-bmh-matchers* nil)

;; DPF 15-feb-10 - In lkb/rmrs/rmrs-convert.lisp, in convert-rmrs-ep-to-mrs()
;; Temporary patch to accommodate conversion of EPs with 
;; unknown-word predicates.  FIX ...
(in-package :mrs)
(defun convert-rmrs-ep-to-mrs (ep rargs)
 (let* ((problems nil)
	 (rmrs-pred (rel-pred ep))
	 (mrs-pred (convert-rmrs-pred-to-mrs rmrs-pred))
	 (semi-pred (or (mt::find-semi-entries mrs-pred)
			mrs-pred)))
   (if semi-pred
	(let ((new-ep
	      (make-rel
	       :handel (rel-handel ep)
	       :parameter-strings (rel-parameter-strings ep)
              :extra (rel-extra ep)
	       :pred semi-pred
	       :flist (cons (convert-rmrs-main-arg (car (rel-flist ep)))
			    (loop for rarg in rargs
				collect
				  (deparsonify rarg)))
              :str (rel-str ep)
	       :cfrom (rel-cfrom ep)
	       :cto (rel-cto ep))))
	  (values new-ep problems))
     (values nil
	      (list (format nil "No entry found in SEM-I for ~A" 
			    rmrs-pred))))))

;; DPF 2011-feb-27
;; Recent versions of Postgres (since 2010) are not happy with the string
;; value "*" as a variable over columns, as given for reqd-flds in e.g. 
;; retrieve-entry2().  So replaced these values '("*") with '(*) in four
;; functions in lkb/src/lexdb files as below (removing the double quotes).
;; (The same change would probably be needed in psql-lex-database2.lsp for
;; single-user users.)

(in-package :lkb)

;; In psql-lex-database.lsp
(defmethod retrieve-entry2 ((lex mu-psql-lex-database) name &key (reqd-fields '(*)))
  (let ((qname (psql-quote-literal name)))
    (get-records lex
		 (format nil
			 "SELECT ~a FROM (SELECT rev.* FROM public.rev as rev JOIN lex_cache USING (name,userid,modstamp) WHERE lex_cache.name = ~a UNION SELECT rev.* FROM rev JOIN lex_cache USING (name,userid,modstamp) WHERE lex_cache.name = ~a) as foo"
			 (fields-str lex reqd-fields)
			 qname qname))))

;; In psql-lex-database0.lsp
(defmethod retrieve-raw-record-no-cache ((lex psql-lex-database) id &optional (reqd-fields '(*)))
  (unless (connection lex)
    (format t "~&(LexDB) WARNING:  no connection to psql-lex-database")
    (return-from retrieve-raw-record-no-cache))
  (retrieve-entry2 lex (2-str id) :reqd-fields reqd-fields))

;; Also in psql-lex-database0.lsp
(defmethod get-dot-lex-record ((lex psql-lex-database) id &optional (fields '(*)))
  (let ((table (retrieve-raw-record-no-cache lex id fields)))
    (dot (cols table) (car (recs table)))))

;; And finally in psqllex.lsp, special handling for asterisk value
(defmethod fields-str ((lex psql-lex-database) fields)
  (if (and (consp fields) (eq (first fields) '*))
    '*
    (concat-str
     (mapcar #'(lambda (x) (quote-ident lex x))
	     fields)
     :sep-c #\,)))


;; Avoid bogus complaint about PSQL server version - now outdated information
(defmethod check-psql-server-version ((lex mu-psql-lex-database))
  t)

;; DPF 2014-10-27 (redefined from lkb/src/io-tdl/tdltypeinput.lsp)
;; Allow type documuntation strings to be marked withh triple quotes, for
;; compatibility with PET
;;
(defun read-tdl-type-comment (istream name)
  ;;; enclosed in """..."""s - called when we've just peeked a "
  (let ((start-position (file-position istream))
	(comment-res nil))
    ;; record this in case the comment isn't closed
    (read-char istream)
    (if (eql (peek-char nil istream nil 'eof) #\")
      (progn (read-char istream)
	     (if (eql (peek-char nil istream nil 'eof) #\")
		 (read-char istream)
	       (lkb-read-cerror 
		istream 
		"Need three double-quote marks for type comment for ~A (comment start at ~A)" 
		name start-position)))
      (lkb-read-cerror 
		istream 
		"Need three double-quote marks for type comment for ~A (comment start at ~A)" 
		name start-position))
    (loop 
      (let ((new-char (peek-char nil istream nil 'eof)))
	(cond ((eql new-char 'eof)
	       (lkb-read-cerror 
		istream 
		"File ended in middle of type comment for ~A (comment start at ~A)" 
		name start-position)
	       (return))
	      ((and (eql new-char #\")
		    (read-char istream)
		    (eql (peek-char nil istream nil 'eof) #\")
		    (read-char istream)
		    (eql (peek-char nil istream nil 'eof) #\")
		    (read-char istream))
	       (return))
	      (t (push (read-char istream) comment-res)))))
    (coerce (nreverse comment-res) 'string)))

;; Now using modern SEM-I construction machinery, so set this flag accordingly:
(setf mrs::*normalize-predicates-p* t)
