# Edit this to install packages and modify dotfile configuration in your
# $HOME.
#
# https://nix-community.github.io/home-manager/index.html#sec-usage-configuration
{ pkgs, inputs, lib, ... }: {
  imports = [
    ./neovim
    ./rex
    ./zk
    ./opencode.nix
    ./zsh.nix
  ];

  # Nix packages to install to $HOME
  #
  # Search for packages here: https://search.nixos.org/packages
  home.packages =
    with pkgs;
    [
      git
      # fonts
      iosevka
      nerd-fonts.iosevka

      rustup
      qemu
      lldb
      btop
      nix-output-monitor # https://github.com/maralorn/nix-output-monitor
      nix-info
      cachix
      fzf
      fd # needed for fzf and the Rex project picker (project-session.lua)

      graphviz
      watch
      gnuplot
      toipe # terminal typing
      ngrok
      mdcat # cat for markdown
      slides # markdown presentation tool
      # tetex # latex tools, failing with the new repo
      # (tailscale.overrideAttrs (_: {
      #   doCheck = false;
      # })) # similar to ngrok
      ncdu # Disk usage analyzer
      nix
      # obsidian # note taking app
      asciinema # asciinema is a suite of tools for recording, replaying, and sharing terminal sessions.

      tdf # Tui-based PDF viewer

      podman
      podman-compose
    ];

  nix = {
    registry.nixpkgs.flake = inputs.nixpkgs; # https://yusef.napora.org/blog/pinning-nixpkgs-flake/
    gc.automatic = true;
  };

  # required to autoload fonts from packages installed via Home Manager
  fonts.fontconfig.enable = true;

  # Programs natively supported by home-manager.
  programs = {
    # on macOS, you probably don't need this
    bash = {
      enable = false;
      initExtra = ''
        # Make Nix and home-manager installed things available in PATH.
        export PATH=$HOME/.nix-profile/bin:/run/current-system/sw/bin/:/nix/var/nix/profiles/default/bin:/etc/profiles/per-user/$USER/bin:$PATH
      '';
    };

    # https://haskell.flake.page/direnv
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    starship.enable = true;

    # Type `z <pat>` to cd to some directory
    zoxide.enable = true;
  };
}
