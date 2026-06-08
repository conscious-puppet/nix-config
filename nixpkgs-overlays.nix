{ inputs, system, ... }: [
  (final: prev: {
    zathura = inputs.nixpkgs-25-11.legacyPackages.${system}.zathura;
    iosevka = inputs.nixpkgs-25-11.legacyPackages.${system}.iosevka;
    nerd-fonts = prev.nerd-fonts // {
      iosevka = inputs.nixpkgs-25-11.legacyPackages.${system}.nerd-fonts.iosevka;
    };

    vimPlugins = prev.vimPlugins // {
      nvim-calltree = prev.vimUtils.buildVimPlugin {
        name = "calltree";
        src = inputs.nvim-calltree;
      };
      neophyte-nvim = prev.vimUtils.buildVimPlugin {
        name = "neophyte";
        src = inputs.neophyte-nvim;
      };
    };
  })
]
