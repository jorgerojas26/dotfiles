;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; Keymaps
(map! :leader
      :desc "Switch to last buffer"
      "l" #'mode-line-other-buffer)
(map! :leader
      :desc "Switch to last workspace"
      "p l" #'+workspace/other)


;; Company config
(setq company-minimum-prefix-length 1)
(setq company-idle-delay 0.1)

;; Corfu config
(setq-local corfu-auto        t
            corfu-auto-delay  0 ;; TOO SMALL - NOT RECOMMENDED
            corfu-auto-prefix 1 ;; TOO SMALL - NOT RECOMMENDED
            completion-cycle-threshold 3)



;; General config
(setq auto-save-default nil)

(setq confirm-kill-emacs nil)


(add-hook 'js2-mode-hook 'biomejs-format-mode)
(add-hook 'typescript-mode-hook 'biomejs-format-mode)
(add-hook 'web-mode-hook 'biomejs-format-mode)

(defun deno-project-p ()
  (let ((root (projectile-project-root)))
    (unless (null root)
      (let ((config1 (concat root "deno.jsonc"))
            (config2 (concat root "deno.json")))
        (or (file-exists-p config1) (file-exists-p config2))))))

(defun fmt-for-deno ()
  (if (deno-project-p)
      (deno-fmt-mode)))

(add-hook 'typescript-mode-hook #'fmt-for-deno)
(add-hook 'js2-mode-hook #'fmt-for-deno)

;; Org mode
(setq org-return-follows-link  t)

;; Make the indentation look nicer
(add-hook 'org-mode-hook 'org-indent-mode)

;; Hide the markers so you just see bold text as BOLD-TEXT and not *BOLD-TEXT*
(setq org-hide-emphasis-markers t)

;; Wrap the lines in org mode so that things are easier to read
(add-hook 'org-mode-hook 'visual-line-mode)

(use-package! websocket
  :after org-roam)

(use-package! org-roam-ui
  :after org-roam ;; or :after org
  ;;         normally we'd recommend hooking orui after org-roam, but since org-roam does not have
  ;;         a hookable mode anymore, you're advised to pick something yourself
  ;;         if you don't care about startup time, use
  ;;  :hook (after-init . org-roam-ui-mode)
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))

;; Encryption
(setq org-journal-enable-encryption t)
(setq org-journal-encrypt-journal t)
(setq org-journal-enable-agenda-integration t)



;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Jorge Rojas"
      user-mail-address "jorgeluisrojasb@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
(setq doom-font (font-spec :family "Fira Code" :size 16 :weight 'semi-light))

;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'catppuccin)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
