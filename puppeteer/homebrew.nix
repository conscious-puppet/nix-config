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
      brews = [
        "winetricks" # game
        "cabextract" # game
        "sevenzip" # needed by winetricks
        "zenity" # game
      ];
      casks = [
        "brave-browser"
        "bitwarden"
        "hyperkey"
        "heroic" # game
      ];
      onActivation.cleanup = "uninstall";
    };
  };
}
