; Emacs Config


(setq tramp-default-method "plink")
(require 'tramp)

(add-to-list 'default-frame-alist '(fullscreen . maximized))

; Cx-b lists candidate buffers
(ido-mode 1)
;(setq ido-separator "\n") ; Set for vertical list

; -----------------------------------------------
; General

; Tabs and indentation
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq indent-line-function 'insert-tab)
(setq c-default-style "linux") 
(setq c-basic-offset 4) 
(c-set-offset 'comment-intro 0)


; Opening remote files and jumping to definitions will scan for VC files
; This can be very slow, don't think I need this feature for anything so just disable 
(setq vc-ignore-dir-regexp
  (format "\\(%s\\)\\|\\(%s\\)" vc-ignore-dir-regexp tramp-file-name-regexp)
)
(setq vc-handled-backends '(Git))

; On windows, moving mouse on menu bar creates system wide alert chimes
; Disable
(setq ring-bell-function 'ignore)

; Switch between header and source file
(global-set-key (kbd "M-o") 'ff-find-other-file)

; Line numbers on the left
(add-hook 'prog-mode-hook 'display-line-numbers-mode)

; -----------------------------------------------
; Packaging 
(require 'package) ;; Emacs builtin

;; set package.el repositories
(setq package-archives '(("elpa" . "https://elpa.gnu.org/packages/")
                         ("melpa" . "https://melpa.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

(package-initialize)
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(use-package delight :ensure t)
(use-package use-package-ensure-system-package :ensure t)

; -----------------------------------------------
; Language server front end
; Use clangd for C/C++ mode
(use-package eglot
  :ensure t)
(add-to-list 'eglot-server-programs '((c++-mode c-mode) "clangd"))
(add-hook 'c-mode-hook 'eglot-ensure)
(add-hook 'c++-mode-hook 'eglot-ensure)
(setq eldoc-idle-delay 0.1)

; Company mode 
(use-package company
  :ensure t
  :after eglot
  :custom
  (company-begin-commands '(self-insert-command))
  (company-idle-delay 0.1)
  (company-minimum-prefix-length 0)
  (company-show-quick-access t)
  (company-tooltip-align-annotations 't)
)
(add-hook 'after-init-hook 'global-company-mode)
; Company mode tab complete and escape abort
(define-key company-active-map (kbd "RET") nil)
(define-key company-active-map [return] nil)
(define-key company-active-map (kbd "TAB") 'company-complete-selection)
(define-key company-active-map [tab] 'company-complete-selection)
(define-key company-active-map [escape] 'company-abort)


; Turn off company mode in remote shells (slow!)
(defun my-shell-mode-setup-function () 
  (when (fboundp 'company-mode)
             (file-remote-p default-directory)
    (company-mode -1)))
(add-hook 'shell-mode-hook 'my-shell-mode-setup-function)


; -----------------------------------------------
; clang-format
; On a remote system, clang-format file paths look on the local system with matching directory
; Fix is to use clang-format file in home directory and spoof the path to match
(add-to-list 'load-path "~/.emacs.d/external/clang-format/")
(require 'clang-format)
;; Fix clang-format (and clang-format+ mode) in tramp mode.
; https://github.com/kljohann/clang-format.el/issues/5
(defun tramp-aware-clang-format (orig-fun start end &optional style assume-file-name)
  (unless assume-file-name
    (setq assume-file-name
          (if (file-remote-p buffer-file-name)
              (concat (getenv "HOME") "/" (file-name-nondirectory buffer-file-name))
            buffer-file-name)))
  (apply orig-fun (list start end style assume-file-name)))
(advice-add 'clang-format-region :around #'tramp-aware-clang-format)
(add-hook
  'c++-mode-hook
  (lambda ()
    (local-set-key (kbd "C-c f") #'clang-format-buffer)
  )
)

; -----------------------------------------------
; CMake and compiling C/C++
(use-package cmake-mode
  :ensure t
  :mode ("CMakeLists\\.txt\\'" "\\.cmake\\'")
)

(use-package cmake-font-lock
  :ensure t
  :after (cmake-mode)
  :hook (cmake-mode . cmake-font-lock-activate)
)

; Scroll the output during compilation
(setq compilation-scroll-output 'first-error)

; Local compile commands for the respective compile mode with a cmake project
(defun my-cmake-release-compile ()
  "Compile cmake build directory."
  (interactive)
  (setq cmake-ide-project-dir (replace-regexp-in-string "/.*:.*:" "" (projectile-project-root)))
  (set (make-local-variable 'compile-command)
    ; (concat "bash -c '" cmake-ide-project-dir "scripts/compile.sh build compile'")
    (concat cmake-ide-project-dir "scripts/compile.sh build compile")
  )
  (call-interactively 'compile)
)
(defun my-cmake-release-recompile ()
  "Recompile cmake build directory."
  (interactive)
  (setq cmake-ide-project-dir (replace-regexp-in-string "/.*:.*:" "" (projectile-project-root)))
  (set (make-local-variable 'compile-command)
    ; (concat "bash -c '" cmake-ide-project-dir "scripts/compile.sh build recompile'")
    (concat cmake-ide-project-dir "scripts/compile.sh build recompile")
  )
  (call-interactively 'compile)
)
(defun my-cmake-debug-compile ()
  "Compile cmake build directory."
  (interactive)
  (set (make-local-variable 'compile-command)
    (setq cmake-ide-project-dir (replace-regexp-in-string "/.*:.*:" "" (projectile-project-root)))
    ; (concat "bash -c '" cmake-ide-project-dir "scripts/compile.sh debug compile'")
    (concat cmake-ide-project-dir "scripts/compile.sh debug compile")
  )
  (call-interactively 'compile)
)
(defun my-cmake-debug-recompile ()
  "Recompile cmake build directory."
  (interactive)
  (set (make-local-variable 'compile-command)
    (setq cmake-ide-project-dir (replace-regexp-in-string "/.*:.*:" "" (projectile-project-root)))
    ; (concat "bash -c '" cmake-ide-project-dir "scripts/compile.sh debug recompile'")
    (concat cmake-ide-project-dir "scripts/compile.sh debug recompile")
  )
  (call-interactively 'compile)
)
(defun my-single-file-compile ()
  "Compile a the current file."
  (interactive)
  (set (make-local-variable 'compile-command)
    (concat "g++ -Wall -Wextra -Og -std=c++17 " (file-name-nondirectory buffer-file-name) " -o " (file-name-nondirectory (file-name-sans-extension buffer-file-name)) )
  )
  (call-interactively 'compile)
)
(setq compile-history '("make"))  

; Keybinds for compile/recompile with a cmake project for build and debug builds
(require 'cc-mode)
(define-key c-mode-base-map (kbd "S-<f5>") 'my-cmake-release-compile)
(define-key c-mode-base-map (kbd "<f5>") 'my-cmake-release-recompile)
(define-key c-mode-base-map (kbd "S-<f6>") 'my-cmake-debug-compile)
(define-key c-mode-base-map (kbd "<f6>") 'my-cmake-debug-recompile)
(define-key c-mode-base-map (kbd "C-c c") 'my-single-file-compile)


; Set compile build commands based on current project folder
; This requires a .git folder in the project root
; (add-hook
;   'c-mode-common-hook 
;   (lambda ()
;     (with-eval-after-load 'projectile
;       (if projectile-project-root
;         (setq cmake-ide-project-dir (replace-regexp-in-string "/.*:.*:" "" (projectile-project-root)))
;       )
;     )
;   )
; )

; from enberg on #emacs
; If compilation exists successfully, close buffer after 2 seconds
(add-hook 'compilation-finish-functions
  (lambda (buf str)
    (if (null (string-match ".*exited abnormally.*" str))
      ;;no errors, make the compilation window go away in a few seconds
      (progn
        (run-at-time
         "2 sec" nil 'delete-windows-on
         (get-buffer-create "*compilation*")
        )
        (message "No Compilation Errors!")
      )
    )
  )
)

; Sometimes buffer contains color codes, ensure we can see it
(require 'ansi-color)
(defun colorize-compilation-buffer ()
  (ansi-color-apply-on-region compilation-filter-start (point-max))
)
(add-hook 'compilation-filter-hook 'colorize-compilation-buffer)


;Force tramp to use a bash shell
(connection-local-set-profile-variables
 'remote-connection-bash
 '(
    (explicit-shell-file-name . "/bin/bash")
    (explicit-bash-args . ("-i"))
   )
)

(connection-local-set-profiles
 '(
   :application tramp
   :protocol "plinkx"
   :user nil
   :machine nil)
 'remote-connection-bash)
(connection-local-set-profiles
 '(
   :application tramp
   :protocol "ssh"
   :user nil
   :machine nil)
 'remote-connection-bash)


(defun save-all-and-compile ()
  (save-some-buffers 1)
  (compile compile-command))

; -----------------------------------------------
; Prevent custom-set-variables being written here
(setq custom-file (concat user-emacs-directory "custom.el"))
(load custom-file 'noerror)

; -----------------------------------------------
; project tree explorer
(add-to-list 'load-path "~/.emacs.d/external/emacs-neotree/")
(require 'neotree)
(setq neo-theme (if (display-graphic-p) 'icons 'arrow))
(setq-default neo-show-hidden-files t)


(defun my-neotree-project-dir-toggle ()
  "Open NeoTree using the project root, using projectile, find-file-in-project,
or the current buffer directory."
  (interactive)
  (require 'neotree)
  (let* ((filepath (buffer-file-name))
         (project-dir
          (with-demoted-errors "neotree-project-dir-toggle error: %S"
              (cond
               ((featurep 'projectile)
                (projectile-project-root))
               ((featurep 'find-file-in-project)
                (ffip-project-root))
               (t ;; Fall back to version control root.
                (if filepath
                    (vc-call-backend
                     (vc-responsible-backend filepath) 'root filepath)
                  nil)))))
         (neo-smart-open t))

    (if (and (fboundp 'neo-global--window-exists-p)
             (neo-global--window-exists-p))
        (neotree-hide)
      (neotree-show)
      (when project-dir
        (neotree-dir project-dir))
      (when filepath
        (neotree-find filepath)))))
; Toggle neotree open/close
(global-set-key [f8] 'my-neotree-project-dir-toggle)

; ;;Neotree
; (with-eval-after-load 'neotree
;   (evil-define-key 'evilified neotree-mode-map (kbd "C-w l") 'evil-window-right)
;   (evil-define-key 'evilified neotree-mode-map (kbd "C-w <right>") 'evil-window-right))

; -----------------------------------------------
;remap default goto-line
(add-to-list 'load-path "~/.emacs.d/external/goto-line-preview/")
(require 'goto-line-preview)
(global-set-key [remap goto-line] 'goto-line-preview)

; -----------------------------------------------
;Line indent guides
(add-to-list 'load-path "~/.emacs.d/external/highlight-indent-guides/")
(require 'highlight-indent-guides)
(add-hook 'prog-mode-hook 'highlight-indent-guides-mode)  ;enable by default
(setq highlight-indent-guides-method 'character) ; Method [fill,column,character,bitmap]
(setq highlight-indent-guides-responsive 'top)   ; Responsive guide [nil,top,stack]

; -----------------------------------------------
; themes
(add-to-list 'load-path "~/.emacs.d/external/doomemacs-themes/")
(require 'doom-themes)
(setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
      doom-themes-enable-italic t) ; if nil, italics is universally disabled

; Themes I like
(setq my-theme-onedark 'doom-one)
(setq my-theme-vsdark 'doom-dark+)
(setq my-theme-onedark-vibrant 'doom-vibrant)
(setq my-theme-onelight 'doom-one-light)
(setq my-theme-opera 'doom-opera)
(setq my-theme-palenight 'doom-palenight)
(setq my-theme-snazzy 'doom-snazzy)
(setq my-theme-material 'doom-material)
(setq my-theme-material-dark 'doom-material-dark)
(setq my-theme-monokai-pro 'doom-monokai-pro)
(setq my-theme-homage-black 'doom-homage-black)
(setq my-theme-homage-white 'doom-homage-white)

; Setting for dark and light theme
(setq my-theme-dark my-theme-onedark-vibrant)
(setq my-theme-light my-theme-homage-white)

; Start with dark theme
(load-theme my-theme-dark t)

; Switch between two custom themes
(defun toggle-theme-custom ()
  (interactive)
  (cond ((eq (car custom-enabled-themes)  my-theme-dark)
          (mapc #'disable-theme custom-enabled-themes)
          (load-theme my-theme-light)
        )
        ((eq (car custom-enabled-themes) my-theme-light)
          (mapc #'disable-theme custom-enabled-themes)
          (load-theme  my-theme-dark))))

; Switch between two custom themes
(defun toggle-theme-default ()
  (interactive)
  (if (eq (car custom-enabled-themes)  my-theme-dark)
      (disable-theme  my-theme-dark)
    (enable-theme  my-theme-dark)))
(global-set-key (kbd "C-c t") 'toggle-theme-custom)

; -----------------------------------------------

; emacs-dashboard
; M-x all-the-icons-install-fonts
(add-to-list 'load-path "~/.emacs.d/external/all-the-icons/")
(require 'all-the-icons)
(add-to-list 'load-path "~/.emacs.d/external/page-break-lines/")
(require 'page-break-lines)
(add-to-list 'load-path "~/.emacs.d/external/projectile/")
(require 'projectile)
(projectile-mode +1)
(when (eq system-type 'darwin)
  ;(define-key projectile-mode-map (kbd "s-p") 'projectile-command-map))
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))
(when (eq system-type 'windows-nt)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))
(when (eq system-type 'gnu/linux)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))


(add-to-list 'load-path "~/.emacs.d/external/emacs-dashboard/")
(require 'dashboard)
(dashboard-setup-startup-hook)
(setq dashboard-projects-backend 'projectile)
(setq dashboard-items '((projects . 10)
			(recents . 5)
			(bookmarks . 5)))
(setq dashboard-set-heading-icons t)
(setq dashboard-set-file-icons t)
