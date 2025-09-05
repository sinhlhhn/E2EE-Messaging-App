const express = require("express");
const router = express.Router();
// const db = require("../db/index");
const path = require('path');
const fs = require('fs');

router.get('/download/:fileType/:userId/:filePath', (req, res) => {
  const { fileType, userId, filePath } = req.params;

  const safeRoot = path.join(__dirname, "../storage/uploads");
  const targetPath = path.join(safeRoot, fileType, userId, filePath);

  // Security check: ensure the resolved path stays inside uploads directory
  if (!targetPath.startsWith(safeRoot)) {
    console.log(`❌ targetPath ${targetPath}`);
    return res.status(400).json({ error: "Invalid file path" });
  }

  console.log(`File path ${targetPath}`);

  fs.access(targetPath, fs.constants.F_OK, (err) => {
    if (err) {
      console.log(`❌ File note found at path ${targetPath}`);
      return res.status(404).json({ error: "File not found" });
    }

    // ✅ Log the download
    const clientIP = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    const timestamp = new Date().toISOString();
    console.log(`📥 File download: ${targetPath} by ${clientIP} at ${timestamp}`);

    res.download(targetPath, path.basename(targetPath), (err) => {
      if (err) {
        console.error("❌ File download error", err);
        res.status(500).json({ error: "Failed to download file" });
      }
    });
  });
});

module.exports = router;