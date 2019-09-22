(require 'nix-env-install)
(setq nix-env-install-after-npm-function (lambda () (kill-emacs)))
(nix-env-install-npm '("bash-language-server" "typescript-language-server"))
