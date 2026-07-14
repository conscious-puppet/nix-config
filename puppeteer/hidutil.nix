{
  # NOTE: this is disabled in favour of karabiner-elements
  # sysmtem.keyboard did not have all the customization
  # https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-system.keyboard.enableKeyMapping
  flake.puppeteer-hidutil =
    let
      # caps -> esc
      # esc -> caps
      hid = {
        # https://hidutil-generator.netlify.app/
        leftCommand = 30064771299;
        leftOption = 30064771298;
        leftControl = 30064771296;
        rightCommand = 30064771303;
        rightOption = 30064771302;
        capsLock = 30064771129;
        escape = 30064771113;
      };
      mkMapping = src: dst: {
        HIDKeyboardModifierMappingSrc = src;
        HIDKeyboardModifierMappingDst = dst;
      };
      userKeyMapping = {
        UserKeyMapping = [
          # (mkMapping hid.capsLock hid.escape)
          # (mkMapping hid.escape hid.capsLock)

          # remapping left cmd -> left ctrl and right cmd -> right option
          # was not emitting the ctrl+option+n
          # (mkMapping hid.leftControl hid.leftOption)
          # (mkMapping hid.leftOption hid.leftCommand)
          # (mkMapping hid.leftCommand hid.leftControl)
          # (mkMapping hid.rightCommand hid.rightOption)
          # (mkMapping hid.rightOption hid.rightCommand)
        ];
      };
    in
    {
      launchd.user.agents.hidutil = {
        serviceConfig = {
          ProgramArguments = [
            "/usr/bin/hidutil"
            "property"
            "--set"
            (builtins.toJSON userKeyMapping)
          ];
          RunAtLoad = true;
        };
      };
    };
}
