

const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure uploads folder exists
const uploadRoot = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadRoot)) fs.mkdirSync(uploadRoot);

// Configure storage
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        let typeFolder = 'other';
        console.log(`file: ${file.mimetype}`)
        if (file.mimetype.startsWith('video/')) typeFolder = 'video';
        else if (file.mimetype.startsWith('audio/')) typeFolder = 'audio';
        else if (file.mimetype.startsWith('image/')) typeFolder = 'image';

        const targetDir = path.join(uploadRoot, typeFolder);
        if (!fs.existsSync(targetDir)) fs.mkdirSync(targetDir, { recursive: true });

        cb(null, targetDir);
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname)); // Keep original extension
    }
});

const upload = multer({ storage: storage });

module.exports = upload;