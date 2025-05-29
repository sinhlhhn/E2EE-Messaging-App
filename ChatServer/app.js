
const express = require("express");
const chatRoutes = require("./routes/chat");
const db = require("./db/index");

const app = express();
app.use(express.json());

// Mount at base path
app.use("/", chatRoutes);

const http = require('http');
const { Server } = require('socket.io');

const server = http.createServer(app);
const io = new Server(server);

const connectedUsers = new Map(); // username -> socket

// 🔹 Socket.IO messaging
io.on('connection', (socket) => {
  console.log('A user connected:', socket.id);

  socket.on('register', (username) => {
    console.log(`User registered: ${username}`);
    connectedUsers.set(username, socket);
    socket.emit('register');
  });

  socket.on('send-message', ({ sender, receiver, text }) => {
    console.log('💌 send-message start');
    if (!sender || !receiver || !text) {
      console.error("send-message error:", { sender, receiver, text });
      return;
    }
    const getUserId = db.prepare('SELECT id FROM users WHERE username = ?');
    const senderRow = getUserId.get(sender);
    const receiverRow = getUserId.get(receiver);
    if (!senderRow || !receiverRow) {
      console.error("send-message user not found:", { senderRow, receiverRow });
      return;
    }

    // Store message in DB
    const insert = db.prepare('INSERT INTO messages (senderId, receiverId, text) VALUES (?, ?, ?)');
    const result = insert.run(senderRow.id, receiverRow.id, text);
    const messageId = result.lastInsertRowid;

    // Emit to receiver if online
    const receiverSocket = connectedUsers.get(receiver);
    if (receiverSocket) {
      receiverSocket.emit('receive-message', { from: sender, text, messageId });
      console.log('💌 send-message completed');
    } else {
      console.error('send-message cannot find receiver', connectedUsers);
    }
  });

  socket.on('disconnect', () => {
    for (const [username, s] of connectedUsers.entries()) {
      if (s === socket) {
        connectedUsers.delete(username);
        break;
      }
    }
    console.log('User disconnected:', socket.id);
  });
});

server.listen(3000, () => {
  console.log('Server listening on http://localhost:3000');
});