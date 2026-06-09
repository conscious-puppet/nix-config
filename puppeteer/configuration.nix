{ self
, inputs
, username
, hostname
, system
, ...
}:
{
  flake.puppeteer-configuration = { pkgs, ... }: {
    # does not work with determinate nix. check its config
    nix.enable = false;
    nix.settings.experimental-features = "nix-command flakes";
    system.configurationRevision = self.rev or self.dirtyRev or null;
    # Used for backwards compatibility, please read the changelog before changing.
    system.stateVersion = 6;
    system.primaryUser = username;
    nixpkgs.hostPlatform = system;
    nixpkgs.config.allowUnfree = true;

    security.pam.services.sudo_local = {
      enable = true;
      touchIdAuth = true;
      reattach = true;
    };

    users.users.${username} = {
      name = username;
      home = "/Users/${username}";
    };

    system.defaults = {
      dock.autohide = true;
      finder = {
        _FXShowPosixPathInTitle = true; # show full path in finder title
        AppleShowAllExtensions = true; # show all file extensions
        FXEnableExtensionChangeWarning = false; # disable warning when changing file extension
        # QuitMenuItem = true; # enable quit menu item
        ShowPathbar = true; # show path bar
        # ShowStatusBar = true; # show status bar
      };

      controlcenter.BatteryShowPercentage = true;

      CustomUserPreferences = {
        "com.apple.Spotlight" = {
          EnabledPreferenceRules = [
            "Custom.relatedContents"
            "com.apple.iBooksX"
            "com.apple.iCal"
            "com.apple.AddressBook"
            "com.apple.Dictionary"
            "com.apple.mail"
            "com.apple.Notes"
            "com.apple.Photos"
            "com.apple.podcasts"
            "com.apple.reminders"
            "com.apple.shortcuts"
            "com.apple.VoiceMemos"
            "com.apple.Safari"
            "com.apple.tips"
          ];
        };
      };

    };
    system.keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    # https://github.com/nix-darwin/nix-darwin/issues/786
    # this won't uninstall it. that needs to be done manually
    system.activationScripts.extraActivation.text = ''
      softwareupdate --install-rosetta --agree-to-license
    '';
  };
}
