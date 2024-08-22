# Create a Local CA and Cert for Nginx

```shell
openssl req -x509 -nodes -new -sha512 \
  -days 365 -newkey rsa:4096 -keyout ca.key \
  -out ca.pem -subj "/C=US/CN=MY-CA" \
  -addext keyUsage=keyCertSign
```

```shell
openssl x509 -outform pem -in ca.pem -out ca.crt
```

```shell
openssl req -new -nodes -newkey rsa:4096 \
  -keyout nginx.key -out nginx.csr \
  -subj "/C=US/ST=California/L=Palo Alto/O=IT/CN=nginx.127-0-0-1.nip.io"
```

Create file nginx.ext with the following:

```
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = nginx.127-0-0-1.nip.io
IP.1 = 127.0.0.1
```


```shell
openssl x509 -req -sha512 -days 365 \
  -extfile nginx.ext \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -in nginx.csr \
  -out nginx.crt
```

