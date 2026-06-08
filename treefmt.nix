{
  perSystem = {

    treefmt.config = {
      projectRootFile = "flake.nix";
      programs = {
        nixpkgs-fmt.enable = true;
        stylua = {
          enable = true;
          settings.indent_type = "Spaces";
          settings.indent_width = 2;
        };
      };
    };
  };
}

