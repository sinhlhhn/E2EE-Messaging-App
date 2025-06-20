# SSL Pinning

Can work with any format like PEM or DER.
By default, openssl generates private keys in PEM. If we want to use DER format, we need to convert it.
1. How to generate private key, certificate, public key: RSA algorithm
- private key: `openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048` or `openssl genpkey -algorithm RSA -out private.key -pkeyopt rsa_keygen_bits:2048`
- self-signed certificate: `openssl req -new -x509 -key private_key.pem -out certificate.pem -days 365 \-subj "/C=US/ST=CA/L=San Francisco/O=Example Corp/CN=localhost"` or `openssl req -new -x509 -key private.key -out certificate.cer -days 365 \-subj "/C=US/ST=CA/L=San Francisco/O=My Company/CN=localhost"`
- extract public key from certificate: `openssl x509 -in certificate.pem -pubkey -noout > public_key.pem`
- hash public key and base64: `openssl pkey -pubin -in public_key.pem -outform DER \
| openssl dgst -sha256 -binary \
| base64`

2. How to generate private key, certificate, public key: EC cryptography
- privatekey: openssl ecparam -genkey -name prime256v1 -out ecc-key.pem
- self-signed certificate: openssl req -new -x509 -key ecc-key.pem -out ecc-cert.pem -days 365 -subj "/CN=localhost"
- extract public key from certificate: openssl x509 -in ecc-cert.pem -pubkey -noout > ecc_public_key.pem
 - hash public key and base64: openssl pkey -pubin -in ecc_public_key.pem -outform DER \
| openssl dgst -sha256 -binary \
| base64

*NOTE: we have to use P256.Signing.PublicKey(x963Representation:) to parse the public key from URLAuthenticationChallenge


