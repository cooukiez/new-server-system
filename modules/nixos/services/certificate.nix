/*
  modules/nixos/services/certificate.nix

  part of der-home-server
  created 2026-04-10
*/

{
  environment.etc."certs/ca.cnf" = {
    text = ''
      [req]
      default_bits       = 4096
      prompt             = no
      default_md         = sha256
      distinguished_name = dn
      x509_extensions    = v3_ca

      [dn]
      C  = US
      ST = Local
      L  = Local
      O  = Home Network Authority
      CN = Home Root CA

      [v3_ca]
      subjectKeyIdentifier   = hash
      authorityKeyIdentifier = keyid:always,issuer
      basicConstraints       = critical, CA:true
      keyUsage               = critical, digitalSignature, cRLSign, keyCertSign
    '';
  };

  environment.etc."certs/home.lan.cnf" = {
    text = ''
      [req]
      default_bits       = 2048
      prompt             = no
      default_md         = sha256
      distinguished_name = dn
      req_extensions     = req_ext

      [dn]
      C  = US
      ST = Local
      L  = Local
      O  = Home Network Services
      CN = home.lan

      [req_ext]
      subjectAltName = @alt_names

      [v3_ext]
      authorityKeyIdentifier = keyid,issuer
      basicConstraints       = CA:FALSE
      keyUsage               = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
      subjectAltName         = @alt_names

      [alt_names]
      DNS.1 = home.lan
      DNS.2 = *.home.lan
    '';
  };

  /*
    cd /etc/certs &&

    sudo openssl genrsa -out ca.key 4096 &&
    sudo openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt -config ca.cnf &&

    sudo openssl genrsa -out home.lan.key 2048 &&
    sudo openssl req -new -key home.lan.key -out home.lan.csr -config home.lan.cnf &&
    sudo openssl x509 -req -in home.lan.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
      -out home.lan.crt -days 825 -sha256 -extfile home.lan.cnf -extensions v3_ext
  */
}
