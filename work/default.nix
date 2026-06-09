{ inputs, ... }:
let
  username = "abhishek.singh1";
in
{
  perSystem =
    { self'
    , inputs'
    , pkgs
    , system
    , config
    , ...
    }:
    {
      legacyPackages.homeConfigurations."abhishek.singh1" =
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ../home
            ./home-manager.nix
            ./zsh.nix
          ];
          extraSpecialArgs = { inherit inputs username; };
        };

      apps.work.program = "${inputs'.home-manager.packages.default}/bin/home-manager";
    };
}
