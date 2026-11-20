{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    shellAliases = {
      v = "nvim";
      vim = "nvim";
      ls = "ls --color=auto";
      ll = "ls -A";
      la = "ls -lA";
      lla = "ls -lah";
      brew = "arch -arm64 /opt/homebrew/bin/brew";
      ibrew = "arch -x86_64 /usr/local/bin/brew";
      sshL = "ssh -L 127.0.0.1:5601:127.0.0.1:5601 -L 127.0.0.1:8013:127.0.0.1:8013 -L 127.0.0.1:3000:127.0.0.1:3000 -L 127.0.0.1:8081:127.0.0.1:8080";
    };
    autosuggestion.enable = true;
    siteFunctions = {
      killport = ''
        kill -9 $(lsof -it:$1)
      '';
    };
    initContent = ''
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' menu select
      zmodload zsh/complist
      compinit
      _comp_options+=(globdots)               # Include hidden files.

      # vi mode
      bindkey -v
      export KEYTIMEOUT=1

      # backward search
      bindkey "^R" history-incremental-search-backward
      bindkey "^S" history-incremental-search-forward

      bindkey '^A' beginning-of-line
      bindkey -M vicmd '^A' beginning-of-line

      bindkey '^E' end-of-line
      bindkey -M vicmd '^E' end-of-line

      bindkey '^F' forward-char
      bindkey -M vicmd '^F' forward-char

      bindkey '^B' backward-char
      bindkey -M vicmd '^B' backward-char
    '';
    envExtra = ''
      PATH="/usr/local/sbin:$PATH"
      PATH="/opt/homebrew/bin:$PATH"
      PATH="$HOME/.ghcup/bin:$PATH"
      PATH="$HOME/.local/bin:$PATH"
      PATH="/usr/local/opt/llvm@12/bin:$PATH"
      PATH="$HOME/.nix-profile/bin:$PATH"

      # Rex puts its CLI on PATH in the terminals it opens
      if [ -n "$REX_BIN_DIR" ]; then
          PATH="$REX_BIN_DIR:$PATH"
      fi

      export PATH
      export EDITOR='nvim'
      export VISUAL='nvim'
      # Make Nix and home-manager installed things available in PATH.
      # export PATH=/run/current-system/sw/bin/:/nix/var/nix/profiles/default/bin:/etc/profiles/per-user/$USER/bin:$PATH
    '';
  };
}
