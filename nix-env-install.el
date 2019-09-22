;;; nix-env-install.el --- Install packages using nix-env -*- lexical-binding: t -*-

;; Copyright (C) 2019 Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.1
;; Package-Requires: ((emacs "25.1"))
;; Keywords: processes tools
;; URL: https://github.com/akirak/nix-env-install

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library lets you install packages using nix-env.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'json)

(defgroup nix-env-install nil
  "Install packages using nix-env."
  :group 'nix)

(when (memq system-type '(ms-dos windows-nt cygwin))
  (user-error "Nix doesn't run on non-UNIX systems"))

;;;; Uninstallation command
;;;###autoload
(defun nix-env-install-uninstall (package)
  "Uninstall PACKAGE installed by nix-env."
  (interactive (list (completing-read "Package: "
                                      (process-lines "nix-env" "-q"))))
  (message (shell-command-to-string
            (format "nix-env -e %s" (shell-quote-argument package)))))

;;;; NPM for JavaScript/TypeScript
(defcustom nix-env-install-after-npm-function nil
  "Function called after installation of npm packages."
  :type 'function
  :group 'nix-env-install)

;;;###autoload
(defun nix-env-install-npm (packages)
  "Install PACKAGES from npm using Nix."
  (interactive (list (split-string (read-string "npm packages: ") " ")))
  (let* ((tmpdir (string-trim-right (shell-command-to-string "mktemp -d -t emacs-node2nix-XXX")))
         (default-directory tmpdir)
         (packages-json-file (expand-file-name "npm-packages.json" tmpdir))
         (s2 `(lambda (proc event)
                (when (equal event "finished\n")
                  (message "Finished installing npm packages: %s" (quote ,packages)))
                (unless (process-live-p proc)
                  (delete-directory ,tmpdir t)
                  )
                (when nix-env-install-after-npm-function
                  (funcall nix-env-install-after-npm-function p))))
         (s1 `(lambda (_proc event)
                (when (equal event "finished\n")
                  (message "Installing npm packages using nix-env...")
                  (make-process :name "nix-env-install"
                                :buffer "*nix-env-install npm*"
                                :command (quote ,(apply #'append
                                                        (list "nix-env"
                                                              "-f" (expand-file-name "default.nix" tmpdir)
                                                              "-i")
                                                        (mapcar (lambda (it) (list "-A" it))
                                                                (cl-etypecase packages
                                                                  (list packages)
                                                                  (string (list packages))))))
                                :sentinel ,s2)))))
    (with-temp-buffer
      (insert (json-encode (cl-typecase packages
                             (list packages)
                             (string (list packages)))))
      (write-file packages-json-file))
    (message "Generating Nix expressions using node2nix for %s..." packages)
    (make-process :name "nix-env-install-node2nix"
                  :buffer "*nix-env-install node2nix*"
                  :command `("nix-shell" "-p" "nodePackages.node2nix"
                             "--run" ,(format "node2nix -i %s --nodejs-10"
                                              packages-json-file))
                  :sentinel s1)))

(provide 'nix-env-install)
;;; nix-env-install.el ends here
