;;; slime-scratch-log.el

;; Copyright (C) 2010-2011 by kmori

;; Author: mori_dev <mori.dev.asdf@gmail.com>
;; Prefix: ssl-

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Install
;; Put this file into load-path'ed directory, and byte compile it if
;; desired.  And put the following expression into your ~/.emacs.
;;
;; (require 'slime-scratch-log)

;;; Change Log

;; 0.0.1: slime-scratch-log.el 0.0.1 released.

(eval-when-compile
  (require 'cl))

(defvar ssl-slime-scratch-log-file "~/.emacs.d/.slime-scratch-log")
(defvar ssl-prev-slime-scratch-string-file "~/.emacs.d/.slime-scratch-log-prev")
(defvar ssl-restore-slime-scratch-p t)
(defvar ssl-prohibit-kill-slime-scratch-buffer-p t)

(defun ssl-dump-slime-scratch-when-kill-buf ()
  (interactive)
  (when (string= "*slime-scratch*" (buffer-name))
    (ssl-make-prev-slime-scratch-string-file)
    (ssl-append-slime-scratch-log-file)))

(defun ssl-dump-slime-scratch-when-kill-emacs ()
  (interactive)
  (ssl-awhen (get-buffer "*slime-scratch*")  
    (with-current-buffer it
      (ssl-make-prev-slime-scratch-string-file)
      (ssl-append-slime-scratch-log-file))))

(defun ssl-make-prev-slime-scratch-string-file ()
  (write-region (point-min) (point-max) ssl-prev-slime-scratch-string-file))

(defun ssl-append-slime-scratch-log-file ()
  (let* ((time (format-time-string "* %Y/%m/%d-%H:%m" (current-time)))
         (buf-str (buffer-substring-no-properties (point-min) (point-max)))
         (contents (concat "\n" time "\n" buf-str)))
    (with-current-buffer (get-buffer-create "tmp")
      (erase-buffer)
      (insert contents)
      (append-to-file (point-min) (point-max) ssl-slime-scratch-log-file))))

(defun ssl-restore-scratch ()
  (interactive)
  (when ssl-restore-slime-scratch-p
    (with-current-buffer "*slime-scratch*"
      (erase-buffer)
      (when (file-exists-p ssl-prev-slime-scratch-string-file)
        (insert-file-contents ssl-prev-slime-scratch-string-file)))))

(defun ssl-slime-scratch-buffer-p ()
  (if (string= "*slime-scratch*" (buffer-name)) nil t))

;; Utility
(defmacro ssl-aif (test-form then-form &rest else-forms)
  (declare (indent 2))
  `(let ((it ,test-form))
     (if it ,then-form ,@else-forms)))

(defmacro* ssl-awhen (test-form &body body)
  (declare (indent 1))
  `(ssl-aif ,test-form
       (progn ,@body)))

(add-hook 'kill-buffer-hook 'ssl-dump-slime-scratch-when-kill-buf)
(add-hook 'kill-emacs-hook 'ssl-dump-slime-scratch-when-kill-emacs)
(add-hook 'emacs-startup-hook 'ssl-restore-scratch)
(when ssl-prohibit-kill-slime-scratch-buffer-p
  (add-hook 'kill-buffer-query-functions 'ssl-slime-scratch-buffer-p))

;;;; Bug report
(defvar slime-scratch-log-maintainer-mail-address
  (concat "mori.de" "v.asdf@gm" "ail.com"))
(defvar slime-scratch-log-bug-report-salutation
  "Describe bug below, using a precise recipe.

When I executed M-x ...

How to send a bug report:
  1) Be sure to use the LATEST version of slime-scratch-log.el.
  2) Enable debugger. M-x toggle-debug-on-error or (setq debug-on-error t)
  3) Use Lisp version instead of compiled one: (load \"slime-scratch-log.el\")
  4) If you got an error, please paste *Backtrace* buffer.
  5) Type C-c C-c to send.
# If you are a Japanese, please write in Japanese:-)")
(defun slime-scratch-log-send-bug-report ()
  (interactive)
  (reporter-submit-bug-report
   slime-scratch-log-maintainer-mail-address
   "slime-scratch-log.el"
   (apropos-internal "^eldoc-" 'boundp)
   nil nil
   slime-scratch-log-bug-report-salutation))

(provide 'slime-scratch-log)
