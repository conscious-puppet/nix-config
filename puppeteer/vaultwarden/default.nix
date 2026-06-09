{ username, ... }:
let
  caCnf = pkgs: pkgs.writeText "vaultwarden-ca.cnf" ''
    [req]
    distinguished_name = req_distinguished_name
    x509_extensions = v3_ca
    prompt = no

    [req_distinguished_name]
    C = DE
    O = puppeteer
    CN = puppeteer-local-ca

    [v3_ca]
    basicConstraints = critical, CA:TRUE
    keyUsage = critical, keyCertSign, cRLSign
    subjectKeyIdentifier = hash
    authorityKeyIdentifier = keyid:always,issuer:always
  '';

  serverCnfTemplate = pkgs: pkgs.writeText "vaultwarden-server.cnf" ''
    [req]
    distinguished_name = req_distinguished_name
    req_extensions = v3_req
    prompt = no

    [req_distinguished_name]
    CN = puppeteer.local

    [v3_req]
    basicConstraints = CA:FALSE
    keyUsage = keyEncipherment, digitalSignature
    extendedKeyUsage = serverAuth
    subjectAltName = @alt_names

    [alt_names]
    DNS.1 = puppeteer.local
    DNS.2 = puppeteer
    IP.1 = 127.0.0.1
  '';

  # Wrapper that generates certs before starting vaultwarden
  vaultwardenWithCerts = pkgs: pkgs.writeShellScript "vaultwarden-with-certs" ''
    set -euo pipefail

    SSL_DIR="/Users/${username}/.vaultwarden/ssl"

    if [[ ! -f "''${SSL_DIR}/server-chain.pem" ]]; then
      echo "vaultwarden: generating self-signed TLS certificates..."
      mkdir -p "''${SSL_DIR}"

      IP=$(/usr/sbin/ipconfig getifaddr en0 2>/dev/null || /usr/sbin/ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")

      # Generate CA with proper CA extensions
      ${pkgs.openssl}/bin/openssl req -x509 -sha256 -days 3650 -nodes \
        -newkey rsa:4096 \
        -config ${caCnf pkgs} \
        -keyout "''${SSL_DIR}/ca-key.pem" \
        -out "''${SSL_DIR}/ca-cert.pem"

      # Build server CSR config from template + dynamic IP
      CSR_CONFIG="/tmp/vaultwarden-san.cnf"
      ${pkgs.coreutils}/bin/cp ${serverCnfTemplate pkgs} "''${CSR_CONFIG}"
      echo "IP.2 = ''${IP}" >> "''${CSR_CONFIG}"

      # Generate server key and CSR
      ${pkgs.openssl}/bin/openssl req -new -nodes -newkey rsa:2048 \
        -config "''${CSR_CONFIG}" \
        -keyout "''${SSL_DIR}/server-key.pem" \
        -out /tmp/server-csr.pem

      # Sign server cert with CA
      ${pkgs.openssl}/bin/openssl x509 -req -sha256 -days 3650 \
        -in /tmp/server-csr.pem \
        -CA "''${SSL_DIR}/ca-cert.pem" \
        -CAkey "''${SSL_DIR}/ca-key.pem" \
        -CAcreateserial \
        -extfile "''${CSR_CONFIG}" -extensions v3_req \
        -out "''${SSL_DIR}/server-cert.pem"

      # Create full chain
      cat "''${SSL_DIR}/server-cert.pem" "''${SSL_DIR}/ca-cert.pem" > "''${SSL_DIR}/server-chain.pem"

      # Cleanup
      rm -f /tmp/server-csr.pem "''${CSR_CONFIG}" /tmp/*.srl 2>/dev/null || true

      # Permissions
      chmod 600 "''${SSL_DIR}"/*-key.pem
      chmod 644 "''${SSL_DIR}"/server-cert.pem "''${SSL_DIR}"/ca-cert.pem "''${SSL_DIR}"/server-chain.pem

      echo "vaultwarden: certificates generated in ''${SSL_DIR}"
      echo "vaultwarden: install ''${SSL_DIR}/ca-cert.pem on your phone to avoid TLS warnings"
    fi

    exec ${pkgs.vaultwarden}/bin/vaultwarden
  '';
in
{
  flake.puppeteer-vaultwarden = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.vaultwarden
    ];

    launchd.daemons.vaultwarden = {
      serviceConfig = {
        ProgramArguments = [
          (toString (vaultwardenWithCerts pkgs))
        ];

        EnvironmentVariables = {
          DATA_FOLDER = "/Users/${username}/.vaultwarden";
          ROCKET_ADDRESS = "0.0.0.0";
          ROCKET_PORT = "8222";
          ROCKET_TLS = ''{certs="/Users/${username}/.vaultwarden/ssl/server-chain.pem",key="/Users/${username}/.vaultwarden/ssl/server-key.pem"}'';
          SIGNUPS_ALLOWED = "true";
          WEB_VAULT_FOLDER = "${pkgs.vaultwarden.webvault}/share/vaultwarden/vault";
        };

        KeepAlive = true;
        RunAtLoad = true;

        StandardOutPath = "/tmp/vaultwarden.log";
        StandardErrorPath = "/tmp/vaultwarden.err";
      };
    };
  };
}
