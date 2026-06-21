{ username, ... }:
{
  flake.puppeteer-vaultwarden = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.vaultwarden
      pkgs.tailscale
    ];

    launchd.daemons.vaultwarden = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.vaultwarden}/bin/vaultwarden"
        ];

        EnvironmentVariables = {
          DATA_FOLDER = "/Users/${username}/.vaultwarden";
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = "8222";
          SIGNUPS_ALLOWED = "false";
          WEB_VAULT_FOLDER = "${pkgs.vaultwarden.webvault}/share/vaultwarden/vault";
        };

        KeepAlive = true;
        RunAtLoad = true;

        StandardOutPath = "/tmp/vaultwarden.log";
        StandardErrorPath = "/tmp/vaultwarden.err";
      };
    };

    launchd.daemons.tailscale-vaultwarden = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.tailscale}/bin/tailscale"
          "serve"
          "--yes"
          "http://127.0.0.1:8222"
        ];

        KeepAlive = true;
        RunAtLoad = true;

        StandardOutPath = "/tmp/tailscale-vaultwarden.log";
        StandardErrorPath = "/tmp/tailscale-vaultwarden.err";
      };
    };
  };
}
