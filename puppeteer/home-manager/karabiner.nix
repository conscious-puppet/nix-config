{config, ...}: {
    home.file.".config/karabiner/karabiner.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix-config/puppeteer/home-manager/karabiner.json";
}
