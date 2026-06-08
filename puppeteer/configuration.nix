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
      dock.autohide = true;

    };
    system.keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };
}
