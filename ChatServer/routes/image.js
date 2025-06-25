const express = require("express");
const router = express.Router();
const db = require("../db/index");
const upload = require("../storage/storage");

router.post('/upload', upload.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file uploaded' });

  res.status(200).json({
    message: 'Upload successful',
    filename: req.file.filename,
    path: `/uploads/${req.file.filename}`
  });
});

module.exports = router;