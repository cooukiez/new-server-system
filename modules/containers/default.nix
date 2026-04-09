/*
  modules/containers/default.nix

  part of der-home-server
  created 2026-04-08
*/

{
  config,
  ...
}:
let
  ports = {
    #
    # core
    #

    # auth
    authelia = 9091;

    # database
    postgres = 5432;

    # dns
    dns = 53;
    adguard = 3000;

    # monitor
    grafana = 3005;
    prometheus = 9090;

    # reverse proxy
    caddy_http = 80;
    caddy_https = 443;

    #
    # services
    #

    # immich
    immich = 2283;
  };
in
{
  imports = [
    ./services/immich.nix

    ./auth.nix
    ./database.nix
    ./dns.nix
    ./monitor.nix
    ./reverse-proxy.nix
    ./users.nix
  ];

  _module.args = { inherit ports; };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      networks = {
        internal.networkConfig.subnets = [ "10.1.1.1/24" ];
      };
    };
}
