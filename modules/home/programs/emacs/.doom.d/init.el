;;; init.el -*- lexical-binding: t; -*-

(doom!
 :ui
 ligatures
 (popup +all +defaults)
 (window-select +numbers)
 doom
 doom-dashboard
 hl-todo
 minimap
 modeline
 nav-flash
 ophints
 tabs
 indent-guides
 (vc-gutter +pretty)
 vi-tilde-fringe
 workspaces
 window-select

 :editor
 evil
 fold
 (format +onsave)
 (parinfer +rust)
 rotate-text
 word-wrap

 :config
 (default +bindings +smartparens +gnupg)

 :emacs
 (dired +icons)
 (ibuffer +icons)
 (undo +tree)

 :completion
 (company +childframe)
 (ivy +childframe +fuzzy +icons +prescient)

 :checkers
 (spell +aspell)
 grammar
 (syntax +childframe)

 :term
 vterm

 :tools
 direnv
 (docker +lsp)
 (lsp +peek)
 (magit +forge)
 terraform
 tree-sitter
 (eval +overlay)

 :os
 (:if IS-MAC macos)
 (tty +osc)

 :app
 everywhere

 :email

 :lang
 (markdown +grip)
 (python +lsp +pyright (:if IS-MAC +pyenv))
 (rust +lsp)
 (sh +lsp)
 emacs-lisp
 json
 (nix +tree-sitter)
 yaml)
