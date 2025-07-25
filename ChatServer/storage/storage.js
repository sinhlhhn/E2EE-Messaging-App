
const { v4: uuidv4 } = require('uuid');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure uploads folder exists
const uploadRoot = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadRoot)) fs.mkdirSync(uploadRoot);

// Configure storage
const storage = multer.diskStorage({
    destination: async (req, file, cb) => {
      try {
        const mediaType = req.body.mediaType; // still from client
        const userId = req.user?.sub; // from authentication middleware

        if (!userId) {
          return cb(new Error('Missing userId'));
        }

        if (!mediaType) {
          return cb(new Error('Missing mediaType'));
        }

        const uploadPath = path.resolve(__dirname, `../storage/uploads/${mediaType}/${userId}`);
        if (!fs.existsSync(uploadPath)) fs.mkdirSync(uploadPath, { recursive: true });

        cb(null, uploadPath);
      } catch (err) {
        cb(err);
      }
    },
    filename: (req, file, cb) => {
      const ext = path.extname(file.originalname);
      const base = path.basename(file.originalname, ext);
      const uuid = uuidv4();
      const uniqueFileName = `${base}-${uuid}${ext}`;
      cb(null, uniqueFileName);
    },
});

const upload = multer({ storage: storage });

module.exports = upload;