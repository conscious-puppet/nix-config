{
  programs.zsh = {
    shellAliases = {
      gt = "tmux -L ghc9 -u attach || tmux -L ghc9 -u new";
    };
    siteFunctions = {
      tailscaled-start = ''
        # tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055

        # 1. Create a directory for tailscale files
        mkdir -p ~/.tailscale

        # 2. Start the daemon in userspace mode with custom paths
        tailscaled \
          --tun=userspace-networking \
          --socket=$HOME/.tailscale/tailscaled.sock \
          --state=$HOME/.tailscale/tailscaled.state \
          --socks5-server=localhost:1055
      '';
      tailscale-auth = ''
        # tailscale up --accept-dns=false
        tailscale --socket=$HOME/.tailscale/tailscaled.sock up --accept-dns=false
      '';
      tailscale-status = ''
        tailscale --socket=$HOME/.tailscale/tailscaled.sock status
      '';
      gp = ''
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
        tmux -L ghc9 -u new-session -A -s $sessionname
        cd $pdir
      '';
    };
  };
}
