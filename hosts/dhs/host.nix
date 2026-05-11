{
  hostname = "dhs";
  hostSystem = "x86_64-linux";
  staticIP = "192.168.178.3";

  dnsServers = [
    "1.1.1.1"
    "8.8.8.8"
    "9.9.9.9"
  ];

  squ = {
    uid = 10000;
    gid = 10000;
  };

  ports = import ./ports.nix;
}
