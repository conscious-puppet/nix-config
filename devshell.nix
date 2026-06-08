{
  perSystem = { self', inputs', pkgs, system, config, ... }: {

    devShells.default = pkgs.mkShell {
      inputsFrom = [
        config.treefmt.build.devShell
      ];

      packages = with pkgs; [
        just
        nixd # Nix language server
      ];
    };
  };
}

