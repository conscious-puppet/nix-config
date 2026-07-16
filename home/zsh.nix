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
      t = "tmux -u attach || tmux -u new";
      zt = "tmux -L zk -u attach || tmux -L zk -u new -c ~/notes";
    };
    autosuggestion.enable = true;
    siteFunctions = {
      killport = ''
        kill -9 $(lsof -it:$1)
      '';
      f = ''
        local dir
        dir=$(
          cd &&
            fd -0 -I --type d --hidden \
              --exclude .git \
              --exclude node_module \
              --exclude .cache \
              --exclude .npm \
              --exclude .mozilla \
              --exclude .meteor \
              --exclude .nv \
              --exclude .vscode \
              --exclude .cargo \
              --exclude .direnv \
              --follow --search-path $HOME/work \
              --search-path $HOME/.config \
              --search-path $HOME/dev |
            fzf --read0
        ) && cd $dir
      '';
      p = ''
        local dir
        local pdir=$(pwd)
        dir=$(
          cd &&
            fd -0 -I --type d --hidden \
              --exclude .git \
              --exclude node_module \
              --exclude .cache \
              --exclude .npm \
              --exclude .mozilla \
              --exclude .meteor \
              --exclude .nv \
              --exclude .vscode \
              --exclude .cargo \
              --exclude .direnv \
              --follow --search-path $HOME/work \
              --search-path $HOME/.config \
              --search-path $HOME/dev |
            fzf --read0
        ) && cd $dir
        local sessionname="$(basename -- $dir)"
        tmux -u new-session -A -s $sessionname
        cd $pdir
      '';
    };
    initContent = ''
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' menu select
      zmodload zsh/complist
      compinit
      _comp_options+=(globdots)               # Include hidden files.

      # backward search
      bindkey "^R" history-incremental-search-backward
    '';
    envExtra = ''
      PATH="/usr/local/sbin:$PATH"
      PATH="/opt/homebrew/bin:$PATH"
      PATH="$HOME/.ghcup/bin:$PATH"
      PATH="$HOME/.local/bin:$PATH"
      PATH="/usr/local/opt/llvm@12/bin:$PATH"
      PATH="$HOME/.nix-profile/bin:$PATH"

      export PATH
      export EDITOR='nvim'
      export VISUAL='nvim'
      # Make Nix and home-manager installed things available in PATH.
      # export PATH=/run/current-system/sw/bin/:/nix/var/nix/profiles/default/bin:/etc/profiles/per-user/$USER/bin:$PATH
    '';
  };
}
