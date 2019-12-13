{ pkgs ? import <nixpkgs> {},
  emacs ? (import (pkgs.fetchFromGitHub {
    owner = "purcell";
    repo = "nix-emacs-ci";
    rev = "53e8f05a66addd520e1feec23eabd6a8a86ee47f";
    # date = 2019-12-12T10:37:15+13:00;
    sha256 = "0v524dsckbhn0y3ywj7dd1a74p6mi7gqz7xdpkzy3l8c2pvpy1sy";
  })).emacs-25-2
}:
let
  check-package = import (builtins.fetchTarball "https://github.com/akirak/emacs-package-checker/archive/v1.tar.gz");
in check-package {
  inherit emacs pkgs;
  name = "nix-env-install";
  src = ./.;
  targetFiles = ["nix-env-install.el"];
  emacsPackages = epkgs: (with epkgs.melpaPackages; [
  ]);
}
