const jwt = require("jsonwebtoken");
const express = require("express");
const router = express.Router();
const db = require("../db/index");
const bcrypt = require('bcrypt');
const SALT_ROUNDS = 10;

router.post("/register", async (req, res) => {
  console.log("CALL /register: ");
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ error: "Username and password required" });

  const existing = db.prepare("SELECT * FROM users WHERE username = ?").get(username);
  if (existing) return res.status(409).json({ error: "Username already exists" });

  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
  const insert = db.prepare("INSERT INTO users (username, passwordHash) VALUES (?, ?)").run(username, passwordHash);
  const userId = insert.lastInsertRowid;

  const { accessToken, refreshToken } = generateTokenPair(userId, username);

  res.json({ accessToken, refreshToken });
});

router.post("/login", async (req, res) => {
  console.log("CALL /login: ");
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ error: "Username and password required" });

  const user = db.prepare("SELECT * FROM users WHERE username = ?").get(username);
  if (!user) return res.status(404).json({ error: "User not found" });

  const passwordMatches = await bcrypt.compare(password, user.passwordHash);
  if (!passwordMatches) return res.status(401).json({ error: "Invalid password" });

  const { accessToken, refreshToken } = generateTokenPair(user.id, user.username);

  res.json({ accessToken, refreshToken });
});

router.post("/token", (req, res) => {
  console.log("CALL /token: ");
  const { token } = req.body;
  if (!token) return res.status(400).json({ error: "Missing refresh token" });

  const record = db.prepare("SELECT * FROM refresh_tokens WHERE token = ?").get(token);
  if (!record) return res.status(403).json({ error: "Invalid refresh token" });

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);

    db.prepare("DELETE FROM refresh_tokens WHERE token = ?").run(token);

    const { accessToken, refreshToken } = generateTokenPair(payload.sub, payload.username);

    res.json({ accessToken, refreshToken });

    console.log("Got new access token: ", accessToken);
  } catch (err) {
    res.status(403).json({ error: "Token expired or invalid" });
    console.log(err);
  }
});

function generateTokenPair(userId, username) {
  const accessToken = jwt.sign({ sub: userId, username }, process.env.JWT_SECRET, { expiresIn: "15m" });
  const refreshToken = jwt.sign({ sub: userId, username }, process.env.JWT_SECRET, { expiresIn: "7d" });

  // Insert with a valid interval expression
  db.prepare("INSERT INTO refresh_tokens (userId, token, expiresAt) VALUES (?, ?, datetime('now', '+7 days'))")
    .run(userId, refreshToken);

  return { accessToken, refreshToken };
}

module.exports = router;