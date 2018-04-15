;;; add-js-import.el --- a package to create the javascript import statements for you
;; Copyright (C) 2018 Jacob O'Donnell

;; Author: Jacob O'Donnell <jacobodonnell@gmail.com>
;; Maintainer: Jacob O'Donnell <jacobodonnell@gmail.com>
;; URL: http://github.com/jodonnell/add-js-import
;; Created: 14th April 2018
;; Version: 1.0
;; Keywords: lisp, tools

;;; Code:

;; TODO:
;; Handle errors (file you are in doesnt compile)
;; put import at bottom of import list
;; handle more than one matches
;; make install plan

(require 'seq)
(require 'thingatpt)

(defcustom add-js-import-use-semicolons t
  "A boolean variable for wether your codebase uses semicolons or not."
  :type 'boolean
  :group 'add-js-import)

(defcustom add-js-import-node-executable "node"
  "Name or path of the node executable binary file."
  :type '(choice (const nil) string)
  :group 'add-js-import)

(defvar add-js-import-node-import-path
  (concat (file-name-directory buffer-file-name) "find_js_import.js"))

(defun is-empty? (thing)
  (eq (length thing) 0))

(defun command-list(project-path symbol)
  (if use-semicolons
      `(,add-js-import-node-executable
        ,add-js-import-node-import-path
        ,project-path
        ,symbol
        "--semi")
    `(,add-js-import-node-executable
      ,add-js-import-node-import-path
      ,project-path
      ,symbol)))

(defun run-command(project-path symbol)
  (shell-command-to-string
   (string-join (command-list project-path symbol) " ")))

(defun shell-output-to-list(output)
  (seq-remove
   'is-empty?
   (split-string output "\n")))

(defun insert-import(import)
  (save-excursion
    (beginning-of-buffer)
    (insert (concat import "\n"))))

(defun add-js-import(project-path symbol)
  (let ((imports (shell-output-to-list
                  (run-command
                   project-path
                   symbol))))
    (if (eq (length imports) 1)
        (insert-import (car imports)))))

;;;###autoload
(defun add-js-import-at-point()
  (interactive)
  (add-js-import
   (projectile-project-root)
   (thing-at-point 'symbol)))

(provide 'add-js-import)

;;; add-js-import.el ends here
