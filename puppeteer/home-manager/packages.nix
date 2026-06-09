{ inputs, system, ... }: {
  home.packages = with inputs.nix-casks.packages.${system}; [
    brave-browser
    hyperkey
    heroic
    bitwarden
  ];
}
