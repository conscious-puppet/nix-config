(load-theme 'solarized-dark t)

;; start in full screen
(toggle-frame-fullscreen)

;; remaps list-buffers to ibuffer (more feature-rich)
(global-set-key [remap list-buffers] 'ibuffer)

;; remaps window cycle
(global-set-key (kbd "M-o") 'other-window)

;; remaps frame cycle
(global-set-key (kbd "C-`") 'other-frame)

;; enable (line no,col no) in the mode line
(setq line-number-mode t)
(setq column-number-mode t)

(when (eq system-type 'darwin)
  ;; Map Left Command to Control
  (setq mac-command-modifier 'control)
  (setq ns-command-modifier 'control)

  ;; Map Right Command to Meta
  (setq mac-right-command-modifier 'meta)
  (setq ns-right-command-modifier 'meta)
  (setq mac-option-modifier 'super))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(fido-mode t)
 '(fido-vertical-mode t)
 '(icomplete-in-buffer t)
 '(menu-bar-mode nil)
 '(ring-bell-function 'ignore)
 '(scroll-bar-mode nil)
 '(tool-bar-mode nil)
 '(winner-mode t))


(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:inherit nil :extend nil :stipple nil :background "#002b36" :foreground "#839496" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight regular :height 240 :width normal :foundry "nil" :family "Iosevka")))))
