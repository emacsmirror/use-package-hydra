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
