;;; slha-mode.el --- Major mode for SUSY Les Houches Accord (SLHA) files

;; Copyright (C) 2014 Misho

;; Author: Misho <sho.iwamoto@ipmu.jp>
;; Keywords: languages

;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject
;; to the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
;; IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
;; CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
;; TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
;; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:

;; On SLHA format, see following papers:
;;   * http://arxiv.org/abs/hep-ph/0311123 for SLHA
;;   * http://arxiv.org/abs/0801.0045      for SLHA2
;;
;; This package is maintained at GitHub:
;;   * http://github.com/misho104/slha-mode
;; As I am novice on building a major mode, your comments / help are
;; welcome!

;;; Code:

(provide 'slha-mode)

(defun slha-mode ()
  "Major mode for editing SUSY Les Houches Accord file."
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'slha-mode mode-name "SLHA")
;  (setq indent-line-function 'slha-basic-indent-line)
  (setq comment-fill-column 20000)
  (make-local-variable 'skeleton-end-hook)
  (make-local-variable 'paragraph-start)
  (make-local-variable 'paragraph-separate)
  (make-local-variable 'comment-start)
  (make-local-variable 'comment-start-skip)


  (setq slha-mode-map (make-sparse-keymap))
  (define-key slha-mode-map [tab] 'slha-basic-indent-line)
  (use-local-map slha-mode-map)

  (setq skeleton-end-hook (lambda ()
                (or (eolp) (newline) (indent-relative)))
    paragraph-start (concat page-delimiter "\\|$")
    paragraph-separate paragraph-start
    comment-start "# "
    comment-start-skip "#+\\s-*"
    slha-indentation 4
    )

  (defun slha-basic-indent-line ()
    (interactive)
    (let* ((eolpos (save-excursion (end-of-line) (point)))
           (bolpos (save-excursion (beginning-of-line) (point)))
           (compos (save-excursion (beginning-of-line)
                                   (while (and (< (point) eolpos) (not (eq (following-char) ?#)))
                                     (forward-char)
                                     )
                                   (if (eq (following-char) ?#) (point) -1)))
           (previous
            (if (< (current-column) comment-column)
                (save-excursion
                  (while (and (progn (beginning-of-line)
                                     (not (bobp)))
                              (progn
                                (forward-line -1)
                                (back-to-indentation)
                                (or (eolp) (eq (following-char) ?#)))))
                  (current-column))
              100))
           current)
      (if (and (> compos 0) (> (point) (- compos 2)))
          (indent-for-comment)
        (save-excursion
          (indent-to (if (eq this-command 'newline-and-indent)
                         previous
                       (if (< (current-column)
                              (setq current (progn (back-to-indentation)
                                                   (current-column))))
                           (if (eolp) previous 0)
                         (delete-region (point)
                                        (progn (beginning-of-line) (point)))
                         previous))))
        (if (< (current-column) (current-indentation))
            (skip-chars-forward " \t")))))

  (copy-face font-lock-variable-name-face 'font-lock-known-variable-name-face)
  (defvar font-lock-known-variable-name-face 'font-lock-known-variable-name-face)
  (set-face-underline-p font-lock-known-variable-name-face t)
  (font-lock-add-keywords
   'nil
   '(
   ;;;
   ;;; BLOCKS
   ;;;
     ("^\\(BLOCK\\) +\\<\\(MODSEL\\|SMINPUTS\\|\\(EXT\\|MIN\\)PAR\\|MASS\\|\\(N\\|U\\|V\\|STOP\\|SBOT\\|STAU\\)MIX\\|ALPHA\\|SPINFO\\|DCINFO\\) *\\(#.*\\)?$"
      (1 font-lock-type-face t) (2 font-lock-variable-name-face t))
     ("^\\(BLOCK\\) +\\<\\(HMIX\\|GAUGE\\|MSOFT\\|AU\\|AD\\|AE\\|YU\\|YD\\|YE\\) +\\(Q=\\) *\\([0-9\\.E\\+\\-]+\\) *\\(#.*\\)?$"
      (1 font-lock-type-face t) (2 font-lock-variable-name-face t) (3 font-lock-type-face t) (4 font-lock-string-face t))
     ("^\\(BLOCK\\) +\\<\\([A-Z0-9_-]+\\) *\\(#.*\\)?$"
      (1 font-lock-type-face))
     ("^\\(DECAY\\) +\\([0-9]+\\) +\\([0-9.E+-]+\\) *\\(#.*\\)?$"  ;;; uint double
      (1 font-lock-type-face) (2 font-lock-function-name-face) (3 font-lock-string-face))
   ;;;
   ;;; DATA
   ;;;
     ("^ +\\([0-9]+\\) +\\([0-9\\-]+\\) *\\(#.*\\)?$"  ;;; uint int
      (1 font-lock-function-name-face) (2 font-lock-constant-face))
     ("^ +\\([0-9]+\\) +\\([0-9.E+-]+\\) *\\(#.*\\)?$"  ;;; uint double
      (1 font-lock-function-name-face) (2 font-lock-string-face))
     ("^ +\\([0-9]+\\) +\\([0-9]+\\) +\\([0-9\\.E\\+\\-]+\\) *\\(#.*\\)?$"  ;;; uint uint double (for MIXs)
      (1 font-lock-function-name-face) (2 font-lock-function-name-face) (3 font-lock-string-face))
     ("^ +\\([0-9\\.E\\+\\-]+\\) *\\(#.*\\)?$"  ;;; double (for ALPHA)
      (1 font-lock-string-face))
     ("^ +\\([0-9]+\\) \\([^#\\n\\r]*\\)"
      (1 font-lock-function-name-face))
     ;;; decays  (double uint int int ...)
     ("^ +\\([0-9\\.E\\+\\-]+\\) +\\(2\\) +\\([0-9\\+\\-]+\\) +\\([0-9\\+\\-]+\\) *\\(#.*\\)?$"
      (1 font-lock-string-face) (2 font-lock-function-name-face) (3 font-lock-constant-face) (4 font-lock-constant-face))
     ("^ +\\([0-9\\.E\\+\\-]+\\) +\\(3\\) +\\([0-9\\+\\-]+\\) +\\([0-9\\+\\-]+\\) +\\([0-9\\+\\-]+\\) *\\(#.*\\)?$"
      (1 font-lock-string-face) (2 font-lock-function-name-face) (3 font-lock-constant-face) (4 font-lock-constant-face) (5 font-lock-constant-face))
     ("^ +\\([0-9\\.E\\+\\-]+\\) +\\(4\\) +\\([0-9\\+\\-]+\\) +\\([0-9\\+\\-]+\\) +\\([0-9\\+\\-]+\\) +\\([0-9\\+\\-]+\\) *\\(#.*\\)?$"
      (1 font-lock-string-face) (2 font-lock-function-name-face) (3 font-lock-constant-face) (4 font-lock-constant-face) (5 font-lock-constant-face) (6 font-lock-constant-face))

   ;;; COMMENT
     ("#.*" (0 font-lock-comment-face t))
     )

   'set
   )
   (set 'font-lock-keywords-case-fold-search t))


;;; slha-mode.el ends here
