{ inputs, system, ... }: [
  (final: prev: {
    zathura = inputs.nixpkgs-25-11.legacyPackages.${system}.zathura;
    iosevka = inputs.nixpkgs-25-11.legacyPackages.${system}.iosevka;
    nerd-fonts = prev.nerd-fonts // {
      iosevka = inputs.nixpkgs-25-11.legacyPackages.${system}.nerd-fonts.iosevka;
    };
  })
]
