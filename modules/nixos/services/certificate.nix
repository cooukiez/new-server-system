/*
  modules/nixos/services/certificate.nix

  part of der-home-server
  created 2026-04-03
*/

{
  environment.etc."cert/req.conf" = {
    text = ''
      [req]
      distinguished_name = req_distinguished_name
      x509_extensions = v3_req
      prompt = no

      [req_distinguished_name]
      CN = home.lan

      [v3_req]
      subjectAltName = @alt_names

      [alt_names]
      DNS.1 = home.lan
      DNS.2 = *.home.lan
    '';
  };

  /*
    cd /etc/cert &&
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
    -keyout home.lan.key \
    -out home.lan.crt \
    -config req.conf -extensions v3_req
  */
}
