{ self, inputs, system, username, ... }: {
  flake.puppeteer-home-manager = {
    imports = [ inputs.home-manager.darwinModules.home-manager ];
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = { inherit inputs system; };
    home-manager.users.${username} = {
      imports = [ ../../home ./packages.nix ];
      home.username = username;
      home.homeDirectory = "/Users/${username}";
      home.stateVersion = "25.05";
    };
    home-manager.sharedModules = [
      inputs.mac-app-util.homeManagerModules.default
    ];

  };
}
