;;; use-package-hydra-tests.el --- Tests for use-package-hydra.el

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;


;;; Code:

(require 'cl)
(require 'ert)

(require 'package)
(package-initialize)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-refresh-contents)
(package-install 'use-package)
(require 'use-package)

(setq use-package-always-ensure nil
      use-package-verbose 'errors
      use-package-expand-minimally t
      ;; These are needed for certain tests below where the `pcase' match
      ;; expression is large and contains holes, such as the :after tests.
      max-lisp-eval-depth 8000
      max-specpdl-size 8000)

(unless (fboundp 'macroexpand-1)
  (defun macroexpand-1 (form &optional environment)
    "Perform (at most) one step of macroexpansion."
    (cond
     ((consp form)
      (let* ((head (car form))
             (env-expander (assq head environment)))
        (if env-expander
            (if (cdr env-expander)
                (apply (cdr env-expander) (cdr form))
              form)
          (if (not (and (symbolp head) (fboundp head)))
              form
            (let ((def (autoload-do-load (symbol-function head) head 'macro)))
              (cond
               ;; Follow alias, but only for macros, otherwise we may end up
               ;; skipping an important compiler-macro (e.g. cl--block-wrapper).
               ((and (symbolp def) (macrop def)) (cons def (cdr form)))
               ((not (consp def)) form)
               (t
                (if (eq 'macro (car def))
                    (apply (cdr def) (cdr form))
                  form))))))))
     (t form))))

(defmacro expand-minimally (form)
  `(let ((use-package-verbose 'errors)
         (use-package-expand-minimally t))
     (macroexpand-1 ',form)))

(defmacro expand-maximally (form)
  `(let ((use-package-verbose 'debug)
         (use-package-expand-minimally nil))
     (macroexpand-1 ',form)))

(defmacro match-expansion (form &rest value)
  `(should (pcase (expand-minimally ,form)
             ,@(mapcar #'(lambda (x) (list x t)) value))))

(defun fix-expansion ()
  (interactive)
  (save-excursion
    (unless (looking-at "(match-expansion")
      (backward-up-list))
    (when (looking-at "(match-expansion")
      (re-search-forward "(\\(use-package\\|bind-key\\)")
      (goto-char (match-beginning 0))
      (let ((decl (read (current-buffer))))
        (kill-sexp)
        (let (vars)
          (catch 'exit
            (save-excursion
              (while (ignore-errors (backward-up-list) t)
                (when (looking-at "(let\\s-+")
                  (goto-char (match-end 0))
                  (setq vars (read (current-buffer)))
                  (throw 'exit t)))))
          (eval
           `(let (,@ (append vars
                             '((use-package-verbose 'errors)
                               (use-package-expand-minimally t))))
              (insert ?\n ?\` (pp-to-string (macroexpand-1 decl))))))))))

(bind-key "C-c C-u" #'fix-expansion emacs-lisp-mode-map)

(eval-when-compile
  (defun plist-delete (plist property)
    "Delete PROPERTY from PLIST"
    (let (p)
      (while plist
        (if (not (eq property (car plist)))
            (setq p (plist-put p (car plist) (nth 1 plist))))
        (setq plist (cddr plist)))
      p))

  ;; `cl-flet' does not work for some of the mocking we do below, while `flet'
  ;; always does.
  (setplist 'flet (plist-delete (symbol-plist 'flet) 'byte-obsolete-info)))

(ert-deftest use-package-test-normalize/:hydra ()
  ;; basic example
  (should (equal (use-package-hydra--normalize
                  'foopkg :hydra (hydra-foo (foo-mode-map "<f2>")
                                            "Zoom"
                                            ("g" text-scale-increase "in")
                                            ("l" text-scale-decrease "out")))
                 '((hydra-foo (foo-mode-map "<f2>")
                              "Zoom"
                              ("g" text-scale-increase "in")
                              ("l" text-scale-decrease "out")))))
  ;; omits docstring
  (should (equal (use-package-hydra--normalize
                  'foopkg :hydra (hydra-foo (foo-mode-map "<f2>")
                                            ("g" text-scale-increase "in")
                                            ("l" text-scale-decrease "out")))
                 '((hydra-foo (foo-mode-map "<f2>")
                              ("g" text-scale-increase "in")
                              ("l" text-scale-decrease "out")))))
  ;; nil for body-map and body-key
  (should (equal (use-package-hydra--normalize
                  'foopkg :hydra (hydra-foo (nil ni)
                                            ("g" text-scale-increase "in")
                                            ("l" text-scale-decrease "out")))
                 '((hydra-foo (nil nil)
                              ("g" text-scale-increase "in")
                              ("l" text-scale-decrease "out")))))
  ;; omits body-map and body-key completely
  (should (equal (use-package-hydra--normalize
                  'foopkg :hydra (hydra-foo ()
                                            ("g" text-scale-increase "in")
                                            ("l" text-scale-decrease "out")))
                 '((hydra-foo ()
                              ("g" text-scale-increase "in")
                              ("l" text-scale-decrease "out")))))
  ;; body only has a plist with a color
  (should (equal (use-package-hydra--normalize
                  'foopkg :hydra (hydra-foo (:color pink)
                                            ("g" text-scale-increase "in")
                                            ("l" text-scale-decrease "out")))
                 '((hydra-foo (:color pink)
                              ("g" text-scale-increase "in")
                              ("l" text-scale-decrease "out")))))
  ;; omits head-hint
  (should (equal (use-package-hydra--normalize
                  'foopkg :hydra (hydra-foo (foo-mode-map "<f2>")
                                            ("g" text-scale-increase)
                                            ("l" text-scale-decrease)))
                 '((hydra-foo (foo-mode-map "<f2>")
                              ("g" text-scale-increase)
                              ("l" text-scale-decrease)))))
  ;; has plist for heads
  (should (equal (use-package-hydra--normalize
                  'foopkg :hydra (hydra-foo (foo-mode-map "<f2>")
                                            ("g" text-scale-increase "in" :bind nil)
                                            ("l" text-scale-decrease "out" :bind nil)))
                 '((hydra-foo (foo-mode-map "<f2>")
                              ("g" text-scale-increase "in" :bind nil)
                              ("l" text-scale-decrease "out" :bind nil)))))
  ;; omits head-hint and has plist for heads
  (should (equal (use-package-hydra--normalize
                  'foopkg :hydra (hydra-foo (foo-mode-map "<f2>")
                                            ("g" text-scale-increase :bind nil)
                                            ("l" text-scale-decrease :bind nil)))
                 '((hydra-foo (foo-mode-map "<f2>")
                              ("g" text-scale-increase :bind nil)
                              ("l" text-scale-decrease :bind nil))))))


;; Local Variables:
;; indent-tabs-mode: nil
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:

;;; use-package-hydra-tests.el ends here
