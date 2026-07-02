const express = require('express');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 3000;
const publicDir = path.join(__dirname);
const uploadDir = path.join(__dirname, 'uploads');

fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}-${file.originalname}`)
});

const upload = multer({ storage });

app.use(cors());
app.use(express.json());
app.use(express.static(publicDir));

app.post('/api/transfer', upload.array('files'), (req, res) => {
  if (!req.files || !req.files.length) {
    return res.status(400).json({ message: 'No files were uploaded.' });
  }

  const destination = req.body.destination || 'Unknown device';
  const files = req.files.map((file) => ({
    originalName: file.originalname,
    size: file.size,
    path: `/uploads/${path.basename(file.path)}`
  }));

  res.json({
    status: 'completed',
    destination,
    files,
    transferredAt: new Date().toISOString()
  });
});

app.get('/api/uploads', (req, res) => {
  fs.readdir(uploadDir, (err, files) => {
    if (err) {
      return res.status(500).json({ message: 'Unable to read upload directory.' });
    }
    const fileList = files.map((file) => ({
      name: file,
      url: `/uploads/${file}`,
      size: fs.statSync(path.join(uploadDir, file)).size
    }));
    res.json(fileList);
  });
});

app.use('/uploads', express.static(uploadDir));

app.use((req, res) => {
  res.status(404).sendFile(path.join(publicDir, 'index.html'));
});

app.listen(port, () => {
  console.log(`Paxori server running at http://localhost:${port}`);
});
