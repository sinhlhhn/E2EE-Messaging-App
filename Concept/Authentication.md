# Authentication

Client Flow:

This is an end-to-end encrypted (E2EE) app, so only users within a conversation can view their messages. The server only stores encrypted messages. Therefore, we need a mechanism to retrieve the private key when a user logs out and logs back in.

1. Register: create private key -> send public key to server -> create restore key from private key and password -> send backup key to server.

2. Login: fetch restore key -> use response to reconstruct private key

3. Message: fetch receiver's public key -> fetch salt shared between receiver and sender -> derive secure key to decrypt messages


