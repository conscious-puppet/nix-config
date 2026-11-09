{ self
, inputs
, username
, hostname
, system
, ...
}:
{
  flake.puppeteer-homebrew = { pkgs, ... }: {
    homebrew = {
      enable = true;
      taps = [
        # brew is managed by nix-homebrew which pins homebrew/cask as a
        # read-only tap and sets HOMEBREW_NO_INSTALL_FROM_API=1, so
        # `brew bundle --cleanup` must not try to untap it
        "homebrew/cask"
      ];
      brews = [
        # "winetricks" # game
        # "cabextract" # game
        # "sevenzip" # needed by winetricks
        # "zenity" # game
      ];
      casks = [
        "brave-browser"
        "google-chrome"
        # "bitwarden" # does not work
        # "hyperkey"
        "karabiner-elements"
        # "heroic" # game
        # "mythic" # game
        "epic-games"
        "steam"
      ];
      onActivation = {
        autoUpdate = true;
        upgrade = true;
        cleanup = "uninstall";
      };
    };
  };
}
