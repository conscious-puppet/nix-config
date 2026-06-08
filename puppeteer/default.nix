{ self, inputs, ... }:
let
  username = "puppet";
  hostname = "puppeteer";
  system = "aarch64-darwin";
  import-args = { _module.args = { inherit username hostname system; }; };
  nixpkgs-overlays = { nixpkgs.overlays = import ../nixpkgs-overlays.nix { inherit inputs system; }; };
in
{
  imports = [
    ./configuration.nix
    ./home-manager
    import-args
  ];
  flake = {
    darwinConfigurations.${hostname} = inputs.nix-darwin.lib.darwinSystem {
      modules = [
        nixpkgs-overlays
        inputs.mac-app-util.darwinModules.default
        self.puppeteer-configuration
        self.puppeteer-home-manager
      ];

    };
  };
}
