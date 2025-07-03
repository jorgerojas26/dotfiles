;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

(setq native-comp-async-report-warnings-errors 'silent)

;; Ensure scratch buffer is writable
(setq initial-scratch-message nil)
(setq initial-buffer-choice nil)
(add-hook 'emacs-startup-hook (lambda () (with-current-buffer "*scratch*"
                                           (setq buffer-read-only nil))))

;; Keymaps
(general-auto-unbind-keys)
(map! :leader
      "a" nil)

(map! :leader
      :desc "Switch to last buffer"
      "l" #'mode-line-other-buffer)

(map! :leader
      :desc "Switch to last workspace"
      "p l" #'+workspace/other)

(map! :leader
      (:prefix ("j" . "journal")
       :desc "Open journal today entry"
       "j" #'org-journal-new-entry)
      )

(map! :leader
      (:prefix ("j" . "journal")
       :desc "Open journal scheduled entry"
       "J" #'org-journal-new-scheduled-entry)
      )

(map! :leader
      (:prefix ("j" . "journal")
       :desc "Search journal by date"
       "s" #'org-journal-new-date-entry)
      )

(defun org-agenda-show-agenda-and-todo (&optional arg)
  (interactive "P")
  (org-agenda arg "n"))

(map! :leader
      (:prefix ("a" . "agenda")
       :desc "Open agenda"
       "a" #'org-agenda-show-agenda-and-todo)
      )

;; Mail

(require 'mu4e)
(require 'gnus-icalendar)
(require 'all-the-icons)

(setq gnus-icalendar-org-capture-file "~/org/meetings.org")
(setq gnus-icalendar-org-capture-headline '("Calendar"))
(setq gnus-icalendar-default-timezone "America/Caracas")
(gnus-icalendar-org-setup)


(require 'timezone)
(set-time-zone-rule "America/Caracas")
(setq org-icalendar-timezone "America/Caracas")


(after! mu4e
  (setq sendmail-program (executable-find "msmtp")
        send-mail-function #'smtpmail-send-it
        message-sendmail-f-is-evil t
        message-sendmail-extra-arguments '("--read-envelope-from")
        message-send-mail-function #'message-send-mail-with-sendmail)
  (setq mu4e-attachment-dir "~/org/attachments")

  (setq mu4e-get-mail-command "mbsync -a"
        mu4e-update-interval 60
        mu4e-use-fancy-chars t
        mu4e-view-show-images t
        mu4e-change-filenames-when-moving t
        mu4e-hide-index-messages t)
  ;; Enable automatic updates
  (mu4e t)
  ;; Start automatic updates
  (mu4e-update-mail-and-index t)

  ;; Configure mu4e-alert
  (require 'mu4e-alert)
  (mu4e-alert-enable-mode-line-display)
  (mu4e-alert-enable-notifications)
  (setq mu4e-alert-interesting-mail-query
        "(flag:unread AND NOT flag:trashed) AND (maildir:/gmail/INBOX OR maildir:/proton/INBOX OR maildir:/outlook/INBOX)")
  (setq mu4e-alert-email-notification-types '(subjects))
  ;; (mu4e-alert-set-default-style 'notifier)
  )

(advice-add #'shr-colorize-region :around (defun shr-no-colourise-region (&rest ignore)))

(set-email-account! "jorge"
                    '((mu4e-sent-folder       . "/gmail/[Gmail]/Sent Mail")
                      (mu4e-trash-folder      . "/gmail/[Gmail]/Trash")
                      (mu4e-drafts-folder     . "/gmail/[Gmail]/Drafts")
                      (mu4e-refile-folder     . "/gmail/[Gmail]/All Mail")
                      (smtpmail-smtp-user     . "jorgeluisrojasb@gmail.com")
                      (user-mail-address      . "jorgeluisrojasb@gmail.com")    ;; only needed for mu < 1.4
                      (mu4e-compose-signature . "")
                      (smtpmail-smtp-user . "jorgeluisrojasb@gmail.com") ;
                      (smtpmail-smtp-server   . "smtp.gmail.com") ;
                      ;; (smtpmail-smtp-service . 465)
                      ;; (smtpmail-stream-type . ssl)
                      )
                    t)

(set-email-account! "andino"
                    '((mu4e-sent-folder       . "/proton/Sent")
                      (mu4e-trash-folder      . "/proton/Trash")
                      (mu4e-drafts-folder     . "/proton/Drafts")
                      (mu4e-refile-folder     . "/proton/All Mail")
                      (smtpmail-smtp-user     . "jorge@andinotechnologies.com")
                      (user-mail-address      . "jorge@andinotechnologies.com")    ;; only needed for mu < 1.4
                      (mu4e-compose-signature . "")
                      (smtpmail-smtp-user . "jorge@andinotechnologies.com") ;
                      (smtpmail-smtp-server   . "127.0.0.1") ;
                      )
                    t)

(set-email-account! "diana"
                    '((mu4e-sent-folder       . "/outlook/Sent")
                      (mu4e-trash-folder      . "/outlook/Deleted")
                      (mu4e-drafts-folder     . "/outlook/Drafts")
                      (mu4e-refile-folder     . "/outlook/Archive")
                      (smtpmail-smtp-user     . "diana_camero15@hotmail.com")
                      (user-mail-address      . "diana_camero15@hotmail.com")    ;; only needed for mu < 1.4
                      (mu4e-compose-signature . "")
                      (smtpmail-smtp-user . "diana_camero15@hotmail.com") ;
                      (smtpmail-smtp-server   . "smtp-mail.outlook.com") ;
                      (smtpmail-smtp-service . 587)
                      (smtpmail-stream-type . ssl)
                      )
                    t)

(setq mu4e-context-policy 'ask-if-none
      mu4e-compose-context-policy 'always-ask)

;; Custom section titles with icons
;; (setq mu4e-main-buffer-hide-personal-addresses t)

;; (after! all-the-icons
;;   (setq mu4e-main-view-title "  Mail Dashboard")

;;   (defun my/mu4e-main-view-title ()
;;     (concat
;;      "\n"
;;      (propertize " " 'display '(space :align-to (- right-fringe 0)))
;;      (propertize (concat (all-the-icons-material "mail" :v-adjust 0.0 :height 1.3 :face 'all-the-icons-blue)
;;                          "  Mail Dashboard")
;;                  'face 'mu4e-title-face)
;;      "\n\n"))

;;   (setq mu4e-main-view-sections
;;         `((:key "f" :name "Favorites" :prefix (lambda () (concat "  " (all-the-icons-material "star" :v-adjust 0.0 :face 'all-the-icons-yellow) " "))
;;            :queries ((,(propertize "Unread messages" 'face 'mu4e-view-link-face)     "flag:unread AND NOT flag:trashed")
;;                      (,(propertize "Today's messages" 'face 'mu4e-view-link-face)     "date:today..now AND NOT flag:trashed")
;;                      (,(propertize "Last 7 days" 'face 'mu4e-view-link-face)          "date:7d..now AND NOT flag:trashed")
;;                      (,(propertize "Messages with attachments" 'face 'mu4e-view-link-face) "flag:attach AND NOT flag:trashed")))

;;           (:key "i" :name "Important" :prefix (lambda () (concat "  " (all-the-icons-material "bookmark" :v-adjust 0.0 :face 'all-the-icons-red) " "))
;;            :queries ((,(propertize "Flagged messages" 'face 'mu4e-view-link-face)    "flag:flagged AND NOT flag:trashed")
;;                      (,(propertize "Important messages" 'face 'mu4e-view-link-face)   "(prio:high OR prio:urgent) AND NOT flag:trashed")))

;;           (:key "m" :name "Maildirs" :prefix (lambda () (concat "  " (all-the-icons-material "folder" :v-adjust 0.0 :face 'all-the-icons-blue) " "))
;;            :queries ((,(propertize "Gmail Inbox" 'face 'mu4e-view-link-face)         "maildir:/gmail/INBOX AND NOT flag:trashed")
;;                      (,(propertize "Proton Inbox" 'face 'mu4e-view-link-face)         "maildir:/proton/INBOX AND NOT flag:trashed")
;;                      (,(propertize "Outlook Inbox" 'face 'mu4e-view-link-face)        "maildir:/outlook/INBOX AND NOT flag:trashed")
;;                      (,(propertize "Drafts" 'face 'mu4e-view-link-face)              "flag:draft AND NOT flag:trashed")
;;                      (,(propertize "Sent messages" 'face 'mu4e-view-link-face)        "(maildir:/gmail/[Gmail]/Sent Mail OR maildir:/proton/Sent OR maildir:/outlook/Sent) AND NOT flag:trashed")
;;                      (,(propertize "All Mail" 'face 'mu4e-view-link-face)            "(maildir:/gmail/[Gmail]/All Mail OR maildir:/proton/All Mail OR maildir:/outlook/Archive) AND NOT flag:trashed")
;;                      (,(propertize "Trash" 'face 'mu4e-view-link-face)               "maildir:/gmail/[Gmail]/Trash OR maildir:/proton/Trash OR maildir:/outlook/Deleted")))

;;           (:key "s" :name "Search & Help" :prefix (lambda () (concat "  " (all-the-icons-material "search" :v-adjust 0.0 :face 'all-the-icons-green) " "))
;;            :queries ((,(propertize "Search messages" 'face 'mu4e-view-link-face) nil)
;;                      (,(propertize "Enter a query" 'face 'mu4e-view-link-face) nil)))))

;;   ;; Custom bookmarks with icons
;;   (setq mu4e-bookmarks
;;         `((:name ,(concat (all-the-icons-faicon "envelope-o" :v-adjust 0.0) " Unread messages")
;;            :query "flag:unread AND NOT flag:trashed"
;;            :key ?u)
;;           (:name ,(concat (all-the-icons-faicon "clock-o" :v-adjust 0.0) " Today's messages")
;;            :query "date:today..now AND NOT flag:trashed"
;;            :key ?t)
;;           (:name ,(concat (all-the-icons-faicon "calendar-o" :v-adjust 0.0) " Last 7 days")
;;            :query "date:7d..now AND NOT flag:trashed"
;;            :key ?w)
;;           (:name ,(concat (all-the-icons-faicon "star-o" :v-adjust 0.0) " Important")
;;            :query "flag:flagged AND NOT flag:trashed"
;;            :key ?i)
;;           (:name ,(concat (all-the-icons-faicon "paperclip" :v-adjust 0.0) " With attachments")
;;            :query "flag:attach AND NOT flag:trashed"
;;            :key ?a)
;;           (:name ,(concat (all-the-icons-faicon "pencil" :v-adjust 0.0) " Drafts")
;;            :query "flag:draft AND NOT flag:trashed"
;;            :key ?d))))

;; Improve message view
(setq mu4e-view-show-addresses t
      mu4e-view-show-images t
      mu4e-view-image-max-width 800
      mu4e-compose-format-flowed t
      mu4e-compose-dont-reply-to-self t
      mu4e-headers-include-related t
      mu4e-headers-skip-duplicates t
      mu4e-headers-auto-update t
      mu4e-headers-results-limit 500
      mu4e-index-cleanup nil
      mu4e-index-lazy-check t)

;; HTML rendering configuration
(require 'mu4e-contrib)
(setq mu4e-html2text-command 'mu4e-shr2text)
(setq shr-color-visible-luminance-min 80)
(setq shr-color-visible-distance-min 5)
(setq shr-use-colors nil)
(setq shr-use-fonts t)
(setq mu4e-view-prefer-html t)
(setq mu4e-view-html-plaintext-ratio-heuristic most-positive-fixnum)

;; Better HTML rendering in dark themes
(setq shr-use-colors nil)
(advice-add #'shr-colorize-region :around (defun shr-no-colourise-region (&rest ignore)))

;; Improve readability
(defun my-mu4e-view-mode-hook ()
  (setq-local line-spacing 0.2)
  (setq-local shr-width 80)  ; Limit the width of rendered HTML
  (variable-pitch-mode 1))   ; Use variable-pitch fonts for better readability
(add-hook 'mu4e-view-mode-hook #'my-mu4e-view-mode-hook)

;; Make links more visible
(custom-set-faces!
  '(link :foreground "#51afef" :underline t)
  '(shr-link :foreground "#51afef" :underline t))

;; Set a nice dark theme for the headers view
(defun my-mu4e-headers-mode-hook ()
  (setq-local line-spacing 3)
  (hl-line-mode 1))
(add-hook 'mu4e-headers-mode-hook #'my-mu4e-headers-mode-hook)

(defun mu4e-pretty-mbsync-process-filter (proc msg)
  (ignore-errors
    (with-current-buffer (process-buffer proc)
      (let ((inhibit-read-only t))
        (delete-region (point-min) (point-max))
        (insert (car (reverse (split-string msg "\r"))))
        (when (re-search-backward "\\(C:\\).*\\(B:\\).*\\(M:\\).*\\(S:\\)")
          (add-face-text-property
           (match-beginning 1) (match-end 1) 'font-lock-keyword-face)
          (add-face-text-property
           (match-beginning 2) (match-end 2) 'font-lock-function-name-face)
          (add-face-text-property
           (match-beginning 3) (match-end 3) 'font-lock-builtin-face)
          (add-face-text-property
           (match-beginning 4) (match-end 4) 'font-lock-type-face))))))

(advice-add
 'mu4e~get-mail-process-filter
 :override #'mu4e-pretty-mbsync-process-filter)

;; Agenda
(setq org-journal-enable-agenda-integration t)

(after! org
  (require 'org-timed-alerts)
  (setq org-timed-alerts-default-alert-props
        '(:style alerter-org
          :title "Agenda notification"
          :persistent t
          :data (lambda ()
                  (save-excursion
                    ;; Move to the current Org entry's heading
                    (org-back-to-heading)
                    ;; Extract LOCATION property from :PROPERTIES:
                    (org-entry-get nil "LOCATION")))))
  (setq org-timed-alerts-warning-string "in %warning-time minutes\n\n Event: %headline\n START TIME: %alert-time")
  (setq org-timed-alerts-final-alert-string "Event: %headline\n\n is about to start")
  (setq org-timed-alerts-alert-command #'alert)
  (setq org-timed-alerts-warning-times '(-60 -10 -5 -1))
  (add-hook 'org-mode-hook #'org-timed-alerts-mode))

(alert-define-style 'alerter-org :title "Org Alerter"
                    :notifier
                    (lambda (info)
                      (let* ((message (plist-get info :message))
                             (title (plist-get info :title))
                             (location (plist-get info :data))
                             ;; (icon "~/.config/emacs/icons/org-alert.png") ; Replace with your icon
                             ;; Build the alerter command
                             (base-cmd (format "alerter -title %s -message %s -sender ch.protonmail.desktop -actions Open -closeLabel Close -sound %s -group org-notifications -timeout 30"
                                               (shell-quote-argument title)
                                               (shell-quote-argument message)
                                               (shell-quote-argument "default")
                                               ;; (shell-quote-argument icon)
                                               ))
                             ;; Add LOCATION handling
                             ;; (full-cmd (if location
                             ;;               (format "%s && open -g %s" base-cmd (shell-quote-argument location))
                             ;;             base-cmd)))
                             (full-cmd (if location
                                           (format "RESPONSE=$(%s); case $RESPONSE in Open|@CONTENTCLICKED) open %s;; esac"
                                                   base-cmd
                                                   (shell-quote-argument location))
                                         base-cmd)))
                        ;; Execute the command
                        (start-process-shell-command "org-alerter" nil full-cmd)))
                    :remover (lambda (info)))


(defvar my-org-timed-alerts-set-all-timers-timer nil)
(defun my-org-timed-alerts-set-all-timers ()
  "Set all timers on idle."
  (when (timerp my-org-timed-alerts-set-all-timers-timer)
    (cancel-timer my-org-timed-alerts-set-all-timers-timer))
  (setq my-org-timed-alerts-set-all-timers-timer
        (run-with-idle-timer 10 nil #'org-timed-alerts-set-all-timers)))
(add-hook 'org-agenda-mode-hook #'my-org-timed-alerts-set-all-timers)


;; (setq org-capture-templates
;;       '(("m" "Meeting" entry (file+headline "~/org/meetings.org" "Calendar")
;;          "* %^{meeting date}T Meeting with %^{meeting with} (%\\2) %?
;;    :PROPERTIES:
;;    :MEETWITH: %\\1
;;    :DESCRIPTION: %\\3
;;    :LOCATION: %^{meeting url}
;;    :END:

;;    Created on %U
;;    Description: %^{description}", :jump-to-captured t :empty-lines 1)))

;; Company config
(setq company-minimum-prefix-length 1)
(setq company-idle-delay 0.1)

;; Corfu config
(setq-local corfu-auto        t
            corfu-auto-delay  0 ;; TOO SMALL - NOT RECOMMENDED
            corfu-auto-prefix 1 ;; TOO SMALL - NOT RECOMMENDED
            completion-cycle-threshold 3)



;; General config
(setq epa-pinentry-mode 'loopback)

(setq confirm-kill-emacs nil
      confirm-kill-processes nil
      ns-confirm-quit nil)

;; Close frame without confirmation
(defun my/close-frame-without-confirmation ()
  "Close the current frame without confirmation or killing the daemon."
  (interactive)
  (if (daemonp)
      (delete-frame) ; Close the frame only
    (save-buffers-kill-emacs))) ; Regular behavior for non-daemon Emacs

;; Bind CMD+Q to close frame
(when (eq system-type 'darwin)
  (global-set-key (kbd "s-q") #'my/close-frame-without-confirmation))

;; macOS-specific fix for CMD+Q
;; (when (eq system-type 'darwin)
;;   (setq ns-confirm-quit nil)
;;   (defun force-quit ()
;;     (interactive)
;;     (kill-emacs))
;;   (global-set-key (kbd "s-q") #'force-quit))


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

;; EAF
;; (add-to-list 'load-path "/Users/jorgerojas/.config/.emacs.d/site-lisp/emacs-application-framework/")

;; (require 'eaf)
;; (require 'eaf-browser)
;; (require 'eaf-pdf-viewer)

;; Encryption
;; (setq org-journal-enable-encryption t)
;; (setq org-journal-encrypt-journal t)



;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "Jorge Rojas"
;;       user-mail-address "jorgeluisrojasb@gmail.com")

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

;; Org Agenda Customization
(after! org-agenda
  ;; Use nice icons for the agenda
  (setq org-agenda-category-icon-alist
        `(("TODO" ,(list (all-the-icons-faicon "check-square-o" :v-adjust 0.02)) nil nil :ascent center)
          ("MEETING" ,(list (all-the-icons-faicon "users" :v-adjust 0.02)) nil nil :ascent center)
          ("IDEA" ,(list (all-the-icons-faicon "lightbulb-o" :v-adjust 0.02)) nil nil :ascent center)
          ("PROJ" ,(list (all-the-icons-octicon "repo" :v-adjust 0.02)) nil nil :ascent center)
          ("INBOX" ,(list (all-the-icons-faicon "inbox" :v-adjust 0.02)) nil nil :ascent center)
          ("EMAIL" ,(list (all-the-icons-faicon "envelope" :v-adjust 0.02)) nil nil :ascent center)
          (".*" ,(list (all-the-icons-faicon "calendar" :v-adjust 0.02)) nil nil :ascent center)))

  ;; Set agenda appearance
  (setq org-agenda-block-separator (string-to-char " ")
        org-agenda-time-grid '((daily today require-timed)
                               (800 1000 1200 1400 1600 1800 2000)
                               " ┄┄┄┄┄ " "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄")
        org-agenda-current-time-string "⭠ NOW ━━━━━━━━━━━━━━"
        org-agenda-time-grid-use-ampm t)

  ;; Customize agenda format with moderate padding
  (setq org-agenda-prefix-format
        '((agenda . " %i %-12:c%?-12t% s")  ; Moderate spacing for agenda items
          (todo . " %i %-12:c")
          (tags . " %i %-12:c")
          (search . " %i %-12:c")))

  ;; Set nice bullets and checkboxes
  (setq org-agenda-bullet-list '("⚫" "⚪" "⚫" "⚪")
        org-agenda-todo-keyword-format "%-12s"
        org-agenda-tags-column 0)

  ;; Add spacing between agenda items (not days)
  (setq org-agenda-format-date (lambda (date) 
                                 (concat "\n" (make-string 79 9472) "\n"  ; Reduced newlines around date
                                         (org-agenda-format-date-aligned date)))
        org-agenda-show-all-dates t)

  ;; Add moderate line spacing to agenda items
  (add-hook 'org-agenda-mode-hook (lambda () (setq-local line-spacing 0.2)))  ; Reduced line spacing

  ;; Custom agenda colors with smaller fonts
  (custom-set-faces!
    '(org-agenda-date :height 1.0)           ; Reduced from 1.1
    '(org-agenda-date-today :height 1.0 :slant italic)  ; Reduced from 1.1
    '(org-agenda-date-weekend :foreground "#a9a1e1" :height 1.0)  ; Reduced from 1.1
    '(org-agenda-structure :height 1.1)      ; Reduced from 1.2
    '(org-agenda-done :foreground "#98be65")
    '(org-scheduled :foreground "#98be65")
    '(org-scheduled-today :foreground "#98be65")
    '(org-scheduled-previously :foreground "#ff6c6b")
    '(org-upcoming-deadline :foreground "#da8548")
    '(org-deadline-announce :foreground "#ff6c6b")
    '(org-time-grid :foreground "#a9a1e1")
    '(org-agenda-current-time :foreground "#51afef" :weight bold :height 1.0)))  ; Reduced from 1.1

;; Define custom agenda views
(setq org-agenda-custom-commands
      '(("n" "Dashboard"
         ((agenda "" ((org-agenda-span 'week)
                      (org-agenda-start-day nil)
                      (org-agenda-start-on-weekday 1)
                      (org-agenda-start-with-log-mode nil)
                      (org-agenda-log-mode-items '(closed clock state))
                      (org-agenda-show-log nil)
                      (org-agenda-show-all-dates t)
                      (org-agenda-time-grid '((weekly today require-timed)
                                              (800 1000 1200 1400 1600 1800 2000)
                                              " ┄┄┄┄┄ " "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"))
                      (org-agenda-current-time-string "⭠ NOW ━━━━━━━━━━━━━━")))
          (todo "TODO"
                ((org-agenda-overriding-header "To Do")
                 (org-agenda-files org-agenda-files)))
          (todo "WAITING"
                ((org-agenda-overriding-header "Waiting")
                 (org-agenda-files org-agenda-files)))))
        ("w" "Weekly Review"
         ((agenda "" ((org-agenda-span 'week)
                      (org-agenda-start-day nil)
                      (org-agenda-start-on-weekday 1)
                      (org-agenda-start-with-log-mode nil)
                      (org-agenda-show-all-dates t)
                      (org-agenda-format-date "%A %d %B %Y")
                      (org-agenda-prefix-format '((agenda . "  %-12:c%?-12t %s")))
                      (org-agenda-current-time-string "⭠ NOW ━━━━━━━━━━━━━━")
                      (org-agenda-time-grid '((weekly today require-timed)
                                              (800 1000 1200 1400 1600 1800 2000)
                                              " ┄┄┄┄┄ " "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"))))))))

;; Make agenda start with week view by default
(setq org-agenda-span 'week
      org-agenda-start-day nil
      org-agenda-start-on-weekday 1
      org-agenda-start-with-log-mode nil
      org-agenda-show-all-dates t
      org-agenda-show-future-repeats 'next
      org-agenda-show-inherited-tags t
      org-agenda-window-setup 'current-window)
