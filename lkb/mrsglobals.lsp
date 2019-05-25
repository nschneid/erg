(in-package "MRS")

(setf *sem-relation-suffix* "_rel")

(setf *value-feats* `(,(vsym "CARG")))

(setf *feat-priority-list*  
  `( ,(vsym "LTOP") ,(vsym "INDEX") ,(vsym "LBL")
     ,(vsym "ARG0") ,(vsym "ARG1") ,(vsym "ARG2") ,(vsym "ARG3") 
     ,(vsym "RSTR") ,(vsym "BODY")
     ,(vsym "MARG") ,(vsym "CARG")))
                                 
(setf *ignored-sem-features* 
  (union
   *ignored-sem-features* 
   (list (vsym "LNK") (vsym "WLINK") (vsym "PARAMS")
         (vsym "CFROM") (vsym "CTO"))))

(setf *ignored-extra-features* 
  (union
   *ignored-extra-features*
   (list (vsym "SORT") (vsym "INSTLOC"))))

; (setf *top-level-rel-types*  `(,(vsym "PRON_REL")))
(setf *top-level-rel-types*  nil)

(defparameter *mrs-to-vit* nil)

(defparameter *mrs-for-language* 'english)

(defparameter *mrs-scoping* nil)
(setf *scoping-call-limit* 1000000)

(setf *initial-semantics-path* 
  `(,(vsym "SYNSEM") ,(vsym "LOCAL") ,(vsym "CONT") ))

(setf *main-semantics-path* 
  `(,(vsym "SYNSEM") ,(vsym "LOCAL") ,(vsym "CONT") 
    ,(vsym "RELS") ,(vsym "LIST")))

(setf *construction-semantics-path*
  `(,(vsym "C-CONT") ,(vsym "RELS") ,(vsym "LIST")))

(setf lkb::*c-cont-check-path* 
  `(,(vsym "C-CONT")))

(setf *psoa-top-h-path* (list (vsym "HOOK") (vsym "LTOP")))

(setf *top-hcons* "qeq")

(defparameter *psoa-index-path* 
  `(,(vsym "HOOK") ,(vsym "INDEX"))
  "path to get an index from a psoa")

(defparameter *psoa-event-path* `(,(vsym "HOOK") ,(vsym "INDEX")))
(defparameter *psoa-liszt-path* `(,(vsym "RELS") ,(vsym "LIST")))
(defparameter *psoa-rh-cons-path* `(,(vsym "HCONS") ,(vsym "LIST")))

(defparameter *rel-handel-path*
    `(,(vsym "LBL"))
  "path to get the handel from a relation")

(defparameter *sc-arg-feature* (vsym "HARG")
  "the feature in a qeq that leads to the first argument")

(defparameter *outscpd-feature* (vsym "LARG")
  "the feature in a qeq that leads to the second argument")

(defparameter *quant-rel-types* nil)

(defparameter *bv-feature* (vsym "ARG0"))

(defparameter *scope-feat* (vsym "BODY"))

(setf *top-semantics-type* 
  (vsym "predsort"))

(setf *rel-name-path* `(,(vsym "PRED") ))

;;;
;;; as of late 2008, the VPM (aka variable property mapping) machinery also 
;;; defines the correspondence of grammar-internal variable types to variable
;;; types (or sorts, in MRS XML lingo) on actual MRSs, e.g. `event' == `e', et
;;; al.  with that mapping as part of the VPM, the old parameters *event-type*
;;; etc. are no longer needed.  yes, we can!                   (20-jan-09; oe)
;;;
(setf *variable-type-mapping* :semi)

;;;
;;; starting with its 1214 release, the ERG makes MRS predicate normalization
;;; the default, i.e. eliminates the symbol vs. string contrast on predicates;
;;; whereas a grammar might use either one (or both, even for the abstractly
;;; same predicate, e.g. _afterwards_p and "_afterwards_p" in the 1214 ERG),
;;; these shall be treated as equivalent in the MRS universe.  also, we will
;;; now always strip the (optional) *sem-relation-suffix* (‘_rel’ in the ERG)
;;; from predicate names, as this is a mechanism on the TFS side only (to give
;;; the grammar something like a separate namespace for its predicates).  in
;;; the past, some MRS serializations suppressed the symbol vs. type contrast,
;;; some exposed it; likewise, some stripped the suffix, and others kept it.
;;; see the discussion on the ‘developers’ list from january 2016 for details.
;;;
(setf *normalize-predicates-p* t)

;;;
;;; context condition in MRS munging rules
;;; 
(defparameter *mrs-rule-condition-path* (list (vsym "CONTEXT")))


;;; the following are needed only for the detection of fragments
;;; indicated in the LinGO gramar by the value of ROOT

(setf *root-path* `(,(vsym "ROOT")))

(setf *false-type* (vsym "-"))

(setf *true-type* (vsym "+"))

;;;
;;; disable so-called `CARG injection' on so-called `ersatz' lexical entries.
;;; this mechanism was unprincipled in the first place (firing on everything
;;; whose orthography ended in the literal string "ersatz"), and now that the
;;; ERG has moved into the chart mapping universe (PET only, so far), generic
;;; lexical entries are treated differently anyway.  `ersatz'ing was a remnant
;;; from the YY days, and in this one case at least we are happy to have put 
;;; it behind us :-).                                          (21-jan-09; oe)
;;;
#+:smaf
(setf smaf::*ersatz-carg-path* nil)

;;;
; DPF Upped from 100 to 200
; DPF 1-Jul-03 Upped from 200 to 500 due to treatment of unspec_loc_rel for
; e.g. free relatives.  Maybe should make this generic rel more specific.
(setf *maximum-genindex-relations* 500)

;;;
;;; a function currently only used in the paraphraser transfer grammar, to do
;;; post-parsing normalization of predicates associated to unknown words.  see
;;; the discussion on the `developers' list in May 2009 for background.  this
;;; should in principle be incorporated into MRS read-out already, i.e. there
;;; should be a way of registering MRS post-processing hooks.   (2-jun-09; oe)
;;;
;;; normalize-mrs() is keyed off a table of <tag, rule, pattern> triples, each
;;; pairing a PTB PoS tag with an orthographemic rule of the grammar (to strip
;;; off inflectional suffixes, if any), and a format() template used to create
;;; the normalized PRED value.
;;;
(defparameter *mrs-normalization-heuristics*
  '(("JJ[RS]?" nil "_~a_a_unknown")
    ("(?:FW|NN)" nil "_~a_n_unknown")
    ("NNS":n_pl_olr "_~a_n_unknown")
    ("RB" nil "_~a_a_unknown")
    ("VBP?" :v_3s-fin_olr "_~a_v_unknown")
    ("VBD" :v_pst_olr "_~a_v_unknown")
    ("VBG" :v_prp_olr "_~a_v_unknown")
    ("VBN" :v_psp_olr "_~a_v_unknown")
    ("VBZ" :v_3s-fin_olr "_~a_v_unknown")))

(defun normalize-mrs (mrs)
  (loop
      for ep in (psoa-liszt mrs)
      for pred = (rel-pred ep)
      when (stringp pred) do
        (loop
            for (tag rule pattern) in *mrs-normalization-heuristics*
            for re = (format nil "(?i)^_([^_]+)/~a_u_unknown$" tag)
            thereis 
              (multiple-value-bind (start end starts ends) (ppcre:scan re pred)
                (when (and start end)
                  (let* ((form (subseq pred (aref starts 0) (aref ends 0)))
                         (form (string-upcase form)))
                    (cond
                     #+:lkb
                     (rule 
                      (let* ((stems (lkb::one-step-morph-analyse form))
                             (stem (first (rassoc (intern rule :lkb) stems))))
                        (when stem
                          (setf (rel-pred ep)
                            (format nil pattern (string-downcase stem))))))
                     (t
                      (setf (rel-pred ep)
                        (format nil pattern (string-downcase form))))))))))
  mrs)

