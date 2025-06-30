const express = require("express");
const router = express.Router();
// const db = require("../db/index");
const upload = require("../storage/storage");
const path = require('path');
const fs = require('fs');

router.post('/upload', upload.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file uploaded' });

  res.status(200).json({
    message: 'Upload successful',
    filename: req.file.filename,
    path: `/uploads/${req.file.filename}`
  });
});

router.post("/upload/raw/:filename", (req, res) => {
  const filename = req.params.filename;
  const uploadDir = path.join(__dirname, "../storage/uploads");
  const filePath = path.join(uploadDir, filename);

  fs.mkdirSync(uploadDir, { recursive: true });
  console.log("Start");

  const writeStream = fs.createWriteStream(filePath);

  req.pipe(writeStream);

  writeStream.on("finish", () => {
    console.log("✅ File upload complete");
    res.status(200).json({ message: "✅ Raw stream upload complete" });
  });

  writeStream.on("error", (err) => {
    console.error("❌ Write stream error", err);
    res.status(500).json({ error: "Write failed" });
  });

  req.on("aborted", () => {
    console.warn("⚠️ Client aborted upload");
    writeStream.destroy(); // Cleanup
  });

  req.on("close", () => {
    console.warn("⚠️ Request closed");
    // You can also destroy the stream here if needed
    writeStream.destroy(); // Cleanup
  });

  req.on("error", (err) => {
    console.error("❌ Request error", err);
    writeStream.destroy(); // Cleanup
  });
});

module.exports = router;

