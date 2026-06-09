{ inputs, ... }:
let
  username = "abhishek.singh1";
in
{
  perSystem = { inputs', pkgs, ... }: {
    legacyPackages.homeConfigurations."abhishek.singh1" =
      inputs.home-manager.lib.homeManagerConfiguration
        {
          inherit pkgs;
          modules = [
            inputs.mac-app-util.homeManagerModules.default
            ../home
            ./home-manager.nix
            ./zsh.nix
          ];
          extraSpecialArgs = { inherit inputs username; };
        };

    apps.work.program = "${inputs'.home-manager.packages.default}/bin/home-manager";
  };
}
