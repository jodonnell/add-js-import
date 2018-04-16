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
;; check if file is already being imported from
;; requires projectile

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

(defcustom add-js-import-npm-executable "npm"
  "Name or path of the npm executable binary file."
  :type '(choice (const nil) string)
  :group 'add-js-import)

(defvar add-js-import-node-import-path
  (concat (file-name-directory buffer-file-name) "find_js_import.js"))

(defun add-js-import--is-empty? (thing)
  (eq (length thing) 0))

(defun add-js-import--semi-flag()
  (if add-js-import-use-semicolons
      "--semi"
    ""))

(defun add-js-import--command-list(project-path symbol)
  `(,add-js-import-node-executable
    ,add-js-import-node-import-path
    ,project-path
    ,symbol
    ,(add-js-import--semi-flag)))

(defun add-js-import--run-command(project-path symbol)
  (shell-command-to-string
   (string-join (add-js-import--command-list project-path symbol) " ")))

(defun add-js-import--install-packages-and-rerun(project-path symbol)
  (shell-command-to-string (concat
                            add-js-import-npm-executable " --prefix "
                            (file-name-directory add-js-import-node-import-path)
                            " install "
                            (file-name-directory add-js-import-node-import-path)))
  (add-js-import--run-command project-path symbol))

(defun add-js-import--run-command-and-error-handle(project-path symbol)
  (let ((output (add-js-import--run-command project-path symbol)))
    (if (string-match-p (regexp-quote "Error: Cannot find module '") output)
        (add-js-import--install-packages-and-rerun project-path symbol)
      output)))

(defun add-js-import--shell-output-to-list(output)
  (seq-remove
   'add-js-import--is-empty?
   (split-string output "\n")))

(defun add-js-import--insert-import(import)
  (save-excursion
    (beginning-of-buffer)
    (insert (concat import "\n"))))

(defun add-js-import(project-path symbol)
  (let ((imports (shell-output-to-list
                  (add-js-import--run-command-and-error-handle
                   project-path
                   symbol))))
    (if (eq (length imports) 1)
        (add-js-import--insert-import (car imports)))))

;;;###autoload
(defun add-js-import-at-point()
  (interactive)
  (add-js-import
   (projectile-project-root)
   (thing-at-point 'symbol)))

(provide 'add-js-import)

;;; add-js-import.el ends here
