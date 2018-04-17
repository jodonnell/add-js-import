;;; add-js-import.el --- a package to create a javascript import for you
;; Copyright (C) 2018 Jacob O'Donnell

;; Author: Jacob O'Donnell <jacobodonnell@gmail.com>
;; Maintainer: Jacob O'Donnell <jacobodonnell@gmail.com>
;; URL: http://github.com/jodonnell/add-js-import
;; Created: 14th April 2018
;; Version: 1.0
;; Keywords: tools, languages, convenience
;; Package-Requires: ((emacs "24.4") (seq "1.11") (projectile "0.10.0"))

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

;; Adds the necessary import for the symbol under the point when you
;; call add-js-import-at-point

;; TODO:
;; Handle errors (file you are in doesnt compile)
;; put import at bottom of import list
;; handle more than one matches
;; make install plan
;; check if file is already being imported from
;; requires projectile

;;; Code:

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

(defun add-js-import--is-empty? (string)
  "Check to see if a STRING is empty."
  (eq (length string) 0))

(defun add-js-import--semi-flag()
  "Add the semi flag if the option is on."
  (if add-js-import-use-semicolons
      "--semi"
    ""))

(defun add-js-import--command-list(project-path symbol)
  "Return the shell command list of the command to run for PROJECT-PATH and SYMBOL."
  `(,add-js-import-node-executable
    ,add-js-import-node-import-path
    ,project-path
    ,symbol
    ,(add-js-import--semi-flag)))

(defun add-js-import--run-command(project-path symbol)
  "Run the command to get the package imports for PROJECT-PATH and SYMBOL."
  (shell-command-to-string
   (string-join (add-js-import--command-list project-path symbol) " ")))

(defun add-js-import--install-packages-and-rerun(project-path symbol)
  "Install the node dependencies and rerun for PROJECT-PATH and SYMBOL."
  (shell-command-to-string (concat
                            add-js-import-npm-executable " --prefix "
                            (file-name-directory add-js-import-node-import-path)
                            " install "
                            (file-name-directory add-js-import-node-import-path)))
  (add-js-import--run-command project-path symbol))

(defun add-js-import--run-command-and-error-handle(project-path symbol)
  "Run the command for PROJECT-PATH and SYMBOL and handle any errors."
  (let ((output (add-js-import--run-command project-path symbol)))
    (if (string-match-p (regexp-quote "Error: Cannot find module '") output)
        (add-js-import--install-packages-and-rerun project-path symbol)
      output)))

(defun add-js-import--shell-output-to-list(output)
  "Turn the shell OUTPUT to a list."
  (seq-remove
   'add-js-import--is-empty?
   (split-string output "\n")))

(defun add-js-import--insert-import(import)
  "Insert the IMPORT statement at the top of the file."
  (save-excursion
    (beginning-of-buffer)
    (insert (concat import "\n"))))

(defun add-js-import(project-path symbol)
  "Find and add the js import for PROJECT-PATH and SYMBOL."
  (let ((imports (add-js-import--shell-output-to-list
                  (add-js-import--run-command-and-error-handle
                   project-path
                   symbol))))
    (if (eq (length imports) 1)
        (add-js-import--insert-import (car imports)))))

;;;###autoload
(defun add-js-import-at-point()
  "Find and add the js import for current projectile project and thing at point."
  (interactive)
  (add-js-import
   (projectile-project-root)
   (thing-at-point 'symbol)))

(provide 'add-js-import)

;;; add-js-import.el ends here
