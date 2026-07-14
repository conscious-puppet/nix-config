{
  self,
  inputs,
  username,
  hostname,
  system,
  ...
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
      dock = {
        autohide = true;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
      };
      NSGlobalDomain.AppleICUForce24HourTime = true;
      menuExtraClock.Show24Hour = true;
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
        "com.apple.symbolichotkeys" = {
          # defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys
          AppleSymbolicHotKeys = {
            # 60 = Select the previous input source (typically Ctrl+Space)
            "60" = {
              enabled = false;
            };
            # 61 = Select next source in Input menu (typically Ctrl+Opt+Space)
            "61" = {
              enabled = false;
            };

            # Change Spotlight Search to Option + Space
            # "64" = {
            #   enabled = true;
            #   value = {
            #     parameters = [
            #       32 # ASCII value for Space
            #       49 # Virtual key code for Space
            #       524288 # Modifier flag for Option / Alt key
            #     ];
            #     type = "standard";
            #   };
            # };

            # Disable Spotlight Cmd + Shift + Space
            "65" = {
              enabled = false;
            };
          };
        };

        # defaults read com.apple.HIToolbox
        "com.apple.HIToolbox" = {
          # sets keyboard to U.S. layout
          AppleCurrentKeyboardLayoutInputSourceID = "com.apple.keylayout.U.S.";
          AppleEnabledInputSources = [
            {
              InputSourceKind = "Keyboard Layout";
              "KeyboardLayout ID" = 0;
              "KeyboardLayout Name" = "U.S.";
            }
          ];

          AppleSelectedInputSources = [
            {
              InputSourceKind = "Keyboard Layout";
              "KeyboardLayout ID" = 0;
              "KeyboardLayout Name" = "U.S.";
            }
          ];
        };

        # defaults read com.apple.Spotlight
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

    # https://github.com/nix-darwin/nix-darwin/issues/786
    # this won't uninstall it. that needs to be done manually
    system.activationScripts.extraActivation.text = ''
      softwareupdate --install-rosetta --agree-to-license
    '';
  };
}
