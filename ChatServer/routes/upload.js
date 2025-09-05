const express = require("express");
const router = express.Router();
const upload = require("../storage/storage");
const path = require('path');
const fs = require('fs');
const authenticateToken = require('../middlewares/auth');
const { v4: uuidv4 } = require('uuid');

router.use(authenticateToken);

router.post('/upload', authenticateToken, upload.array('media', 10), (req, res) => {
  const mediaType = req.body.mediaType;
  const userId = req.user?.sub;
  const groupId = req.body.groupId || uuidv4(); // client can provide or server generates

  if (!req.files || req.files.length === 0) {
    return res.status(400).json({ error: 'No files uploaded' });
  }

  const paths = req.files.map(file => `/${mediaType}/${userId}/${file.filename}`);
  const originalNames = req.files.map(file => `${file.filename}`);

  res.json({
    message: 'Upload successful',
    groupId,
    paths,
    originalNames
  });
});

// router.post('/upload', authenticateToken, upload.single('media'), (req, res) => {
//   if (!req.file) {
//     console.log("No file uploaded");
//     return res.status(400).json({ error: 'No file uploaded' });
//   }

//   const mediaType = req.body.mediaType;
//   const userId = req.user?.sub;
//   const fileName = req.file.filename;

// console.log(`✅ Upload successful: /${mediaType}/${userId}/${fileName}`);

//   res.status(200).json({
//     message: 'Upload successful',
//     filename: fileName,
//     path: `/${mediaType}/${userId}/${fileName}`,
//     originalName: fileName
//   });
// });

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
