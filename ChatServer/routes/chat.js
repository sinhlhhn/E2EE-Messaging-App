const express = require("express");
const router = express.Router();
const db = require("../db/index");

// cryptor
const crypto = require("crypto");

function generateSalt(byteLength = 32) {
  return crypto.randomBytes(byteLength).toString("base64");
}

// GET /users
router.get("/users", (req, res) => {
  try {
    const stmt = db.prepare("SELECT id, username FROM users");
    const users = stmt.all();
    res.json({ users });
    //   console.log('GET user: ', users);
  } catch (err) {
    console.error("Error fetching users:", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// GET /users/chatted-with/:userId
router.get("/users/chatted-with/:userId", (req, res) => {
  const userId = req.params.userId;

  try {
    const stmt = db.prepare(`
        SELECT u.id, u.username
  FROM (
    SELECT DISTINCT
      CASE
        WHEN sender_id = @userId THEN receiver_id
        ELSE sender_id
      END AS chatted_user_id
    FROM messages
    WHERE sender_id = @userId OR receiver_id = @userId
  ) AS chat_users
  JOIN users u ON u.id = chat_users.chatted_user_id;
      `);

    const rows = stmt.all({ userId });
    const users = rows.map(row => row.chatted_user_id);

    res.json({ users });
  } catch (err) {
    console.error("Error fetching chat users:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

// 🔹 Create or log in a user
router.post('/users', (req, res) => {
  const { username } = req.body;
  if (!username) return res.status(400).json({ error: 'Username required' });

  const find = db.prepare('SELECT * FROM users WHERE username = ?');
  let user = find.get(username);

  if (!user) {
    const insert = db.prepare('INSERT INTO users (username) VALUES (?)');
    const info = insert.run(username);
    user = { id: info.lastInsertRowid, username };
  }

  res.json(user);
});

// 🔹 Fetch messages between two users
router.get('/messages/:userA/:userB', (req, res) => {
  const { userA, userB } = req.params;
  console.log('GET query: ', req.query);
  const before = parseInt(req.query.before) || Number.MAX_SAFE_INTEGER;
  const limit = parseInt(req.query.limit) || 10;

  console.log('GET before: ', before);
  console.log('GET limit: ', limit);

  const getUserId = db.prepare('SELECT id FROM users WHERE username = ?');
  const a = getUserId.get(userA);
  const b = getUserId.get(userB);
  if (!a || !b) return res.status(404).json({ error: 'User not found' });

  const stmt = db.prepare(`
    SELECT messages.id, users.username AS sender, messages.receiverId, messages.text, messages.createdAt
    FROM messages
    JOIN users ON users.id = messages.senderId
    WHERE
      ((senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?))
      AND messages.id < ?
    ORDER BY messages.id DESC
    LIMIT ?
  `);

  const messages = stmt.all(a.id, b.id, b.id, a.id, before, limit);
  res.json(messages.reverse());
  console.log('GET message: ', messages);
});

// POST /keys
router.post("/keys", (req, res) => {
  const { username, publicKey } = req.body;

  if (!username || !publicKey) {
    return res.status(400).json({ error: "Missing username or publicKey" });
  }

  const user = db.prepare("SELECT id FROM users WHERE username = ?").get(username);
  if (!user) {
    return res.status(404).json({ error: "User not found" });
  }

  // Insert or update the user's public key
  db.prepare(`
    INSERT INTO secure_keys (ownerId, encryptKey)
    VALUES (?, ?)
    ON CONFLICT(ownerId) DO UPDATE SET encryptKey = excluded.encryptKey
  `).run(user.id, publicKey);

  const result = res.json({ success: true });
  // console.log('POST key: ', result);
});

// GET /keys/:username
router.get("/keys/:username", (req, res) => {
  const { username } = req.params;

  const user = db.prepare("SELECT id FROM users WHERE username = ?").get(username);
  if (!user) {
    return res.status(404).json({ error: "User not found" });
  }

  const keyRow = db.prepare("SELECT encryptKey FROM secure_keys WHERE ownerId = ?").get(user.id);
  if (!keyRow) {
    return res.status(404).json({ error: "Public key not found for user" });
  }

  res.json({ publicKey: keyRow.encryptKey });
});

// POST /session
router.post("/session", (req, res) => {
  const { senderUsername, receiverUsername } = req.body;

  const sender = db.prepare("SELECT id FROM users WHERE username = ?").get(senderUsername);
  const receiver = db.prepare("SELECT id FROM users WHERE username = ?").get(receiverUsername);

  if (!sender || !receiver) {
    return res.status(404).json({ error: "Invalid usernames" });
  }

  // Normalize user order to ensure consistency
  const userId1 = Math.min(sender.id, receiver.id);
  const userId2 = Math.max(sender.id, receiver.id);

  // Check for existing salt
  const existing = db.prepare(`
    SELECT salt FROM message_keys
    WHERE senderId = ? AND receiverId = ?
    ORDER BY createdAt DESC LIMIT 1
  `).get(userId1, userId2);

  if (existing) {
    return res.json({ salt: existing.salt });
  }

  // Generate and store new salt
  const salt = generateSalt();
  db.prepare(`
    INSERT INTO message_keys (senderId, receiverId, salt)
    VALUES (?, ?, ?)
  `).run(userId1, userId2, salt);

  res.json({ salt });
  console.log('POST salt: ', salt);
});

// GET /session?sender=S&receiver=A
router.get("/session", (req, res) => {
  const { sender, receiver } = req.query;

  const s = db.prepare("SELECT id FROM users WHERE username = ?").get(sender);
  const r = db.prepare("SELECT id FROM users WHERE username = ?").get(receiver);

  if (!s || !r) {
    return res.status(404).json({ error: "Invalid usernames" });
  }

  const session = db.prepare(`
    SELECT salt FROM message_keys
    WHERE senderId = ? AND receiverId = ?
    ORDER BY createdAt DESC LIMIT 1
  `).get(s.id, r.id);

  if (!session) {
    return res.status(404).json({ error: "Session not found" });
  }

  res.json({ salt: session.salt });
});


module.exports = router;