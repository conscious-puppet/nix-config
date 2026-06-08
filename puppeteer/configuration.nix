{ self, inputs, username, hostname, system, ... }: {
  flake.puppeteer-configuration = { pkgs, ... }: {
    # does not work with determinate nix. check its config
    nix.enable = false;
    nix.settings.experimental-features = "nix-command flakes";
    system.configurationRevision = self.rev or self.dirtyRev or null;
    # Used for backwards compatibility, please read the changelog before changing.
    system.stateVersion = 6;
    nixpkgs.hostPlatform = system;
    nixpkgs.config.allowUnfree = true;

    security.pam.services.sudo_local.touchIdAuth = true;

    users.users.${username} = {
      home = "/Users/${username}";
      packages = with inputs.nix-casks.packages.${system}; [
        brave-browser
        vlc
      ];
    };
  };
}
