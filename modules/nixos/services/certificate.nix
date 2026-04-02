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
}