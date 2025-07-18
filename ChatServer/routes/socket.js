

const db = require("../db/index");
let connectedUsers = new Map(); // username -> socket

// 🔹 Socket.IO messaging
function initializeSocket(server) {
    const { Server } = require('socket.io');
    const io = new Server(server);

    connectedUsers = new Map();
    io.on('connection', (socket) => {
        console.log('A user connected:', socket.id);

        socket.on('register', (username) => {
            console.log(`User registered: ${username}`);
            connectedUsers.set(username, socket);
            socket.emit('register');
        });

        socket.on('send-message', ({ sender, receiver, text, mediaUrl, mediaType }) => {
            console.log('💌 send-message start');
            if (!sender || !receiver || (!text && !mediaUrl)) {
                console.error("send-message error:", { sender, receiver, text, mediaUrl });
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
            const insert = db.prepare(`
                INSERT INTO messages (senderId, receiverId, text, mediaUrl, mediaType)
                VALUES (?, ?, ?, ?, ?)
            `);
            const result = insert.run(senderRow.id, receiverRow.id, text || null, mediaUrl || null, mediaType || null);
            const messageId = result.lastInsertRowid;

            // Emit to receiver if online
            const receiverSocket = connectedUsers.get(receiver);
            if (receiverSocket) {
                receiverSocket.emit('receive-message', {
                    from: sender,
                    text,
                    mediaUrl,
                    mediaType,
                    messageId,
                });
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
}


module.exports = { initializeSocket, connectedUsers };