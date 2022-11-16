;; Copyright (C) 2021 Free Software Foundation, Inc

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.
(require 'cask "~/.cask/cask.el")
(let*
    ((parent-dir
      (if (string-match "test/$" default-directory)
	(file-name-directory (directory-file-name default-directory))
      default-directory)))
  (cask-initialize parent-dir))
;; There is a bug on Travis where we are getting
;; "Symbol’s function definition is void: make-mutex"
;; We'll work around it here
(if (not (functionp 'make-mutex))
    (defun make-mutex(&optional name)))
