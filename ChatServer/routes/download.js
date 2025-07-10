const express = require("express");
const router = express.Router();
// const db = require("../db/index");
const path = require('path');
const fs = require('fs');

router.get('/download/:filename', (req, res) => {
  const filename = req.params.filename;
  const uploadDir = path.join(__dirname, "../storage/uploads");
  const filePath = path.join(uploadDir, filename);

    console.log(`File path ${filePath}`);

  fs.access(filePath, fs.constants.F_OK, (err) => {
    if (err) {
      return res.status(404).json({ error: "File not found" });
    }

    // ✅ Log the download
    const clientIP = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    const timestamp = new Date().toISOString();
    console.log(`📥 File download: ${filename} by ${clientIP} at ${timestamp}`);

    res.download(filePath, filename, (err) => {
      if (err) {
        console.error("❌ File download error", err);
        res.status(500).json({ error: "Failed to download file" });
      }
    });
  });
});

module.exports = router;