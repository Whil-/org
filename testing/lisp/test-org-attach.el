;;; test-org-attach.el --- tests for org-attach.el      -*- lexical-binding: t; -*-

;; Copyright (C) 2017, 2019

;; Author: Marco Wahl
;; Keywords: internal

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(require 'org-test)
(require 'org-attach)
(eval-and-compile (require 'cl-lib))

(ert-deftest test-org-attach/dir ()
  "Test `org-attach-get' specifications."
  (org-test-in-example-file org-test-attachments-file
    ;; Link inside H1
    (org-next-link)
    (save-excursion
      (org-open-at-point)
      (should (equal "Text in fileA\n" (buffer-string))))
    ;; * H1.1
    (org-next-visible-heading 1)
    (let ((org-attach-use-inheritance nil))
      (should-not (equal "att1" (org-attach-dir))))
    (let ((org-attach-use-inheritance t))
      (should (equal "att1" (org-attach-dir))))
    ;; Link inside H1.1
    (org-next-link)
    (save-excursion
      (let ((org-attach-use-inheritance nil))
	(org-open-at-point)
	(should-not (equal "Text in fileB\n" (buffer-string)))))
    (save-excursion
      (let ((org-attach-use-inheritance t))
	(org-open-at-point)
	(should (equal "Text in fileB\n" (buffer-string)))))
    ;; * H1.2
    (org-next-visible-heading 1)
    (should (equal '("fileC" "fileD") (org-attach-file-list (org-attach-dir))))
    ;; * H2
    (org-next-visible-heading 1)
    (let ((org-attach-id-dir "data/"))
      (should (equal '("fileE") (org-attach-file-list (org-attach-dir))))
      (save-excursion
	(org-attach-open-in-emacs)
	(should (equal "peek-a-boo\n" (buffer-string)))))
    ;; * H3
    (org-next-visible-heading 1)
    ;; DIR has priority over ID
    (should (equal '("fileA" "fileB") (org-attach-file-list (org-attach-dir))))
    ;; * H3.1
    (org-next-visible-heading 1)
    (let ((org-attach-use-inheritance nil))
      (should (equal "data/ab/cd12345" (file-relative-name (org-attach-dir)))))
    (let ((org-attach-use-inheritance t))
      ;; This is where it get's a bit sketchy...! DIR always has
      ;; priority over ID, even if ID is declared "higher up" in the
      ;; tree.  This can potentially be revised.  But it is also
      ;; pretty clean.  DIR is always higher in priority than ID right
      ;; now, no matter the depth in the tree.
      (should (equal '("fileA" "fileB") (org-attach-file-list (org-attach-dir)))))))

(ert-deftest test-org-attach/dired-attach-to-next-best-subtree/1 ()
  "Attach file at point in dired to subtree."
  (should
   (let ((a-filename (make-temp-file "a"))) ; file is an attach candidate.
     (unwind-protect
	 (org-test-with-temp-text-in-file
	  "* foo   :foo:"
	  (split-window)
	  (dired temporary-file-directory)
	  (cl-assert (eq 'dired-mode major-mode))
	  (revert-buffer)
	  (dired-goto-file a-filename)
					; action
	  (call-interactively #'org-attach-dired-to-subtree)
					; check
	  (delete-window)
	  (cl-assert (eq 'org-mode major-mode))
	  (beginning-of-buffer)
	  (search-forward "* foo")
					; expectation.  tag ATTACH has been appended.
	  (cl-reduce (lambda (x y) (or x y))
		     (mapcar (lambda (x) (string-equal "ATTACH" x))
			     (plist-get
			      (plist-get
			       (org-element-at-point) 'headline) :tags))))
       (delete-file a-filename)))))

(ert-deftest test-org-attach/dired-attach-to-next-best-subtree/2 ()
  "Attach 2 marked files."
  (should
   (let ((a-filename (make-temp-file "a"))
	 (b-filename (make-temp-file "b"))) ; attach candidates.
     (unwind-protect
	 (org-test-with-temp-text-in-file
	  "* foo"
	  (split-window)
	  (dired temporary-file-directory)
	  (cl-assert (eq 'dired-mode major-mode))
	  (revert-buffer)
	  (dired-goto-file a-filename)
	  (dired-mark 1)
	  (dired-goto-file b-filename)
	  (dired-mark 1)
					; action
	  (call-interactively #'org-attach-dired-to-subtree)
					; check
	  (delete-window)
	  (cl-assert (eq 'org-mode major-mode))
	  (beginning-of-buffer)
	  (search-forward "* foo")
	  (and (file-exists-p (concat (org-attach-dir) "/"
				      (file-name-nondirectory a-filename)))
               (file-exists-p (concat (org-attach-dir) "/"
				      (file-name-nondirectory b-filename)))))
       (delete-file a-filename)
       (delete-file b-filename)))))


(provide 'test-org-attach)
;;; test-org-attach.el ends here
