(after! doom-themes
  (setq doom-theme 'doom-vibrant)
  (setq doom-font (font-spec :family "Monaspace Argon"))
  (set-frame-parameter nil 'alpha-background 90)
  (add-to-list 'default-frame-alist '(alpha-background . 90)))

(after! which-key
  (setq which-key-idle-delay 0.15)
  (setq which-key-idle-secondary-delay 0.15))

(after! nix-mode
  (setq nix-nixfmt-bin "nixpkgs-fmt"))

(after! '(direnv lsp)
  (advice-add 'lsp :before #'envrc--update-env)
  (setq lsp-enable-completion-at-point t))

;; (after! haskell
;;   (setq-hook! 'haskell-mode-hook +format-with 'ormolu))

;; (use-package! graphql-mode
;;  :mode ("\\.gql\\'" "\\.graphql\\'")
;;  :config (setq-hook! 'graphql-mode-hook tab-width graphql-indent-level))

(after! exec-path-from-shell
  (when (memq window-system '(mac ns x)))
  (exec-path-from-shell-initialize))

;; (after! '(nix lsp)
;;   (add-to-list 'lsp-language-id-configuration '(nix-mode . "nix"))
;;   (lsp-register-client
;;    (make-lsp-client :new-connection (lsp-stdio-connection '("rnix-lsp"))
;;                     :major-modes '(nix-mode)
;;                     :server-id 'nix)))

(after! projectile
  (setq projectile-project-search-path '(("~/development/" . 2)
                                         ("~/Development/" . 2)
                                         ("~/dev/" . 3)
                                         ("~/env" . 1))))


(after! lsp
  (setq lsp-file-watch-ignored '(
                                 "[/\\\\]\\.direnv$"
                                        ; SCM
                                 "[/\\\\]\\.git$")))

;; (use-package! protobuf-mode
;;   :mode ("\\.proto\\'"))

(use-package! difftastic
  :after magit
  :bind (:map magit-blame-read-only-mode-map
              ("D" . difftastic-magit-diff)
              ("S" . difftastic-magit-show))
  :config
    '(transient-append-suffix 'magit-diff '(-1 -1)
       [("D" "Difftastic diff (dwim)" difftastic-magit-diff)
        ("S" "Difftastic show" difftastic-magit-show)]))

(use-package! drag-stuff
   :defer t
   :config
  (map! "<M-up>"    #'drag-stuff-up
        "<M-down>"  #'drag-stuff-down
        "<M-left>"  #'drag-stuff-left
        "<M-right>" #'drag-stuff-right))
