const express = require("express");
const router = express.Router();
const upload = require("../storage/storage");
const path = require('path');
const fs = require('fs');
const authenticateToken = require('../middlewares/auth');
const { v4: uuidv4 } = require('uuid');

router.use(authenticateToken);

// router.post('/upload', upload.single('media'), (req, res) => {
//   if (!req.file) {
//     console.log("No file uploaded");
//     return res.status(400).json({ error: 'No file uploaded' });
//   }

//   // Extract the subfolder from the file path to build the correct relative URL
//   const relativePath = req.file.path.split("uploads")[1]

//   res.status(200).json({
//     message: 'Upload successful',
//     filename: req.file.filename,
//     path: `/${relativePath}`
//   });
// });

router.post('/upload', upload.single('media'), (req, res) => {
  if (!req.file) {
    console.log("No file uploaded");
    return res.status(400).json({ error: 'No file uploaded' });
  }

  const ext = path.extname(req.file.originalname).toLowerCase();
  const baseName = path.basename(req.file.originalname, ext);
  const uniqueFilename = `${baseName}-${uuidv4()}${ext}`;

  const oldPath = req.file.path;
  const newPath = path.join(path.dirname(oldPath), uniqueFilename);
  fs.renameSync(oldPath, newPath);


  res.status(200).json({
    message: 'Upload successful',
    filename: uniqueFilename,
    path: `/${path.relative(path.join(__dirname, '../storage/uploads'), newPath)}`,
    originalName: baseName
  });
});

router.post("/upload/raw/:filename", authenticateToken, (req, res) => {
  console.log("Start upload...");
  const originalName = req.params.filename;
  const ext = path.extname(originalName).toLowerCase();
  const baseName = path.basename(originalName, ext);
  const filename = `${baseName}-${uuidv4()}${ext}`;
  const userId = req.user.sub;

  if (!userId) {
    console.log("Missing userId query param", req.user);
    return res.status(400).json({ error: "Missing userId query param" });
  }

  let mediaType = 'file';
  if (['.jpg', '.jpeg', '.png', '.gif'].includes(ext)) mediaType = 'image';
  else if (['.mp4', '.mov', '.avi'].includes(ext)) mediaType = 'video';
  else if (['.m4a', '.mp3', '.aac'].includes(ext)) mediaType = 'audio';

  const uploadDir = path.join(__dirname, `../storage/uploads/${mediaType}/${userId}`);

  const filePath = path.join(uploadDir, filename);

  fs.mkdirSync(uploadDir, { recursive: true });
  console.log("Start");

  const writeStream = fs.createWriteStream(filePath);

  req.pipe(writeStream);

  writeStream.on("finish", () => {
    console.log("✅ File upload complete");
    res.status(200).json({
      message: "✅ Raw stream upload complete",
      path: `/${mediaType}/${userId}/${filename}`,
      originalName: originalName
    });
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
  });

  req.on("error", (err) => {
    console.error("❌ Request error", err);
    writeStream.destroy(); // Cleanup
  });
});

module.exports = router;
