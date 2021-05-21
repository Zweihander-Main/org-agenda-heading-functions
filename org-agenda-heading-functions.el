;;; org-agenda-heading-functions.el --- WIP-*-lexical-binding:t-*-

;; Copyright (C) 2021, Zweihänder <zweidev@zweihander.me>
;;
;; Author: Zweihänder
;; Keywords: org-mode, org-agenda
;; Homepage: https://github.com/Zweihander-Main/org-agenda-heading-functions
;; Version: 0.0.1

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as published
;; by the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; WIP
;;
;;; Code:

(require 'org)
(require 'org-agenda)
(require 'org-statistics-cookie-helpers)

(defgroup org-agenda-heading-functions nil
  "Customization for 'org-agenda-heading-functions' package."
  :group 'org
  :prefix "org-agenda-heading-functions-")

(defvar org-agenda-heading-functions-saved-effort "1:00"
  "Current saved effort for agenda items.")

(defun org-agenda-heading-functions--redo-all-agenda-buffers ()
  "Refresh/redo all org-agenda buffers."
  (interactive)
  (let ((visible-buffers
         (if (fboundp 'doom-visible-buffers)
             (doom-visible-buffers) ; Doom vers if available
           (delete-dups (mapcar #'window-buffer (window-list)))))
        buffer)
    (dolist (buffer visible-buffers)
      (with-current-buffer buffer
        (when (derived-mode-p 'org-agenda-mode)
          (org-agenda-redo))))))

;;;###autoload
(defun org-agenda-heading-functions-set-saved-effort (effort)
  "Set the EFFORT property for the current headline."
  (interactive
   (list (read-string
          (format "Effort [%s]: " org-agenda-heading-functions-saved-effort)
          nil
          nil
          org-agenda-heading-functions-saved-effort)))
  (setq org-agenda-heading-functions-saved-effort effort)
  (org-agenda-check-no-diary)
  (let* ((hdmarker (or (org-get-at-bol 'org-hd-marker)
                       (org-agenda-error)))
         (buffer (marker-buffer hdmarker))
         (pos (marker-position hdmarker))
         (inhibit-read-only t)
         newhead)
    (org-with-remote-undo buffer
      (with-current-buffer buffer
        (widen)
        (goto-char pos)
        (org-show-context 'agenda)
        (funcall-interactively
         'org-set-effort
         nil
         org-agenda-heading-functions-saved-effort)
        (end-of-line 1)
        (setq newhead (org-get-heading)))
      (org-agenda-change-all-lines newhead hdmarker))))

;;;###autoload
(defun org-agenda-heading-functions-edit-headline ()
  "Perform org-edit-headline on current agenda item."
  (interactive)
  (org-agenda-check-no-diary)
  (let* ((hdmarker (or (org-get-at-bol 'org-hd-marker)
                       (org-agenda-error)))
         (buffer (marker-buffer hdmarker))
         (pos (marker-position hdmarker))
         (inhibit-read-only t)
         newhead)
    (org-with-remote-undo buffer
      (with-current-buffer buffer
        (widen)
        (goto-char pos)
        (org-show-context 'agenda)
        (call-interactively #'org-edit-headline)
        (end-of-line 1)
        (setq newhead (org-get-heading)))
      (org-agenda-change-all-lines newhead hdmarker)
      (beginning-of-line 1))))

;;;###autoload
(defun org-agenda-heading-functions-break-into-child (child)
  "Create CHILD heading under current heading with the same properties and
custom effort."
  (interactive
   (list (read-string "Child task: " nil nil nil)))
  (org-agenda-check-no-diary)
  (let* ((hdmarker (or (org-get-at-bol 'org-hd-marker)
                       (org-agenda-error)))
         (buffer (marker-buffer hdmarker))
         (pos (marker-position hdmarker))
         (inhibit-read-only t)
         cur-tags cur-line cur-priority cur-stats-cookies)
    (org-with-remote-undo buffer
      (with-current-buffer buffer
        (widen)
        (goto-char pos)
        (org-show-context 'agenda)
        (setq cur-line (thing-at-point 'line t))
        (if (string-match org-priority-regexp cur-line)
            (setq cur-priority (match-string 2 cur-line)))
        (setq cur-tags (org-get-tags-string))
        (setq cur-stats-cookies (org-statistics-cookie-helpers-find-cookies))
        (if (eq cur-stats-cookies 'nil)
            (org-statistics-cookie-helpers-insert-cookies))
        (if (fboundp '+org/insert-item-below)
            (call-interactively #'+org/insert-item-below) ; Doom ver if available
          (call-interactively #'org-insert-item)) ; Non-Doom if not
        (call-interactively #'org-demote-subtree)
        (funcall-interactively 'org-edit-headline child)
        (funcall-interactively 'org-set-tags-to cur-tags)
        (if cur-priority
            (funcall-interactively 'org-priority (string-to-char cur-priority)))
        (org-update-parent-todo-statistics)
        (end-of-line 1))
      (beginning-of-line 1)))
  (org-agenda-heading-functions--redo-all-agenda-buffers)
  (let (txt-at-point)
    (save-excursion
      (goto-char (point-min))
      (goto-char (next-single-property-change (point) 'org-hd-marker))
      (and (search-forward child nil t)
           (setq txt-at-point
                 (get-text-property (match-beginning 0) 'txt)))
      (if (get-char-property (point) 'invisible)
          (beginning-of-line 2)
        (when (string-match-p child txt-at-point)
          (call-interactively 'org-agenda-heading-functions-set-saved-effort))))))

(provide 'org-agenda-heading-functions)

;; Local Variables:
;; coding: utf-8
;; End:

;;; org-agenda-heading-functions.el ends here
