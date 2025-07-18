require('dotenv').config();
const express = require("express");
const chatRoutes = require("./routes/chat");
const authRoutes = require("./routes/authentication");
const uploadRoutes = require("./routes/upload");
const downloadRoutes = require("./routes/download");

const app = express();
app.use(express.json());

// Mount at base path
app.use("/auth", authRoutes);
app.use("/api", chatRoutes);
app.use("/", uploadRoutes);
app.use("/", downloadRoutes);

const fs = require('fs');
const https = require('https');
// const http = require('http');

// Load TLS credentials securely with RSA algorithm
// const tlsOptions = {
//   key: fs.readFileSync('tls/private.key'),
//   cert: fs.readFileSync('tls/certificate.cer'),
// };

// Load TLS credentials securely with EC cryptography
const tlsOptions = {
  key: fs.readFileSync('tls/ecc-key.pem'),
  cert: fs.readFileSync('tls/ecc-cert.pem'),
};

const HOST = 'localhost';
const PORT = 3000;

// create https server
const server = https.createServer(tlsOptions, app);

// create http server
// const server = http.createServer(app);

// initialize socket with server
const { initializeSocket } = require('./routes/socket');
initializeSocket(server);

server.listen(PORT, HOST, () => {
  console.log(`✅ HTTPS server XXX listening on https://${HOST}:${PORT}`);
});