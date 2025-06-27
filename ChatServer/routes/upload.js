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
  const filePath = path.join(__dirname, "../storage/uploads", filename);
console.log("Start");
  const writeStream = fs.createWriteStream(filePath);
  req.pipe(writeStream);

  writeStream.on("finish", () => {
    res.status(200).json({ message: "✅ Raw stream upload complete" });
  });
});

module.exports = router;

