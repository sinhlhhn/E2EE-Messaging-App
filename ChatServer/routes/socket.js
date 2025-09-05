

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

        socket.on('send-message', ({ sender, receiver, text, mediaUrl, mediaType, originalName, groupId }) => {
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
                INSERT INTO messages (senderId, receiverId, text, mediaUrl, mediaType, originalName, groupId)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            `);
            const result = insert.run(senderRow.id, receiverRow.id, text || null, mediaUrl || null, mediaType || null, originalName || null, groupId || null);
            const messageId = result.lastInsertRowid;
            // Emit to receiver if online
            const receiverSocket = connectedUsers.get(receiver);
            if (receiverSocket) {
                const payload = {
                    from: sender,
                    text,
                    mediaUrl,
                    mediaType,
                    messageId,
                    originalName,
                    groupId
                };

                receiverSocket.emit('receive-message', payload);
                console.log("💌 Emitting to receiverSocket with data:", payload);
            } else {
                console.error('send-message cannot find receiver', connectedUsers);
            }
        });

        socket.on('send-images', ({ sender, receiver, text, mediaUrls, mediaType, originalNames, groupId }) => {
            console.log('💌 send-images start');
            if (!sender || !receiver || !Array.isArray(mediaUrls) || !Array.isArray(originalNames) || mediaUrls.length !== originalNames.length || mediaUrls.length === 0) {
                console.error("send-images error:", { sender, receiver, text, mediaUrls, originalNames });
                return;
            }
            const getUserId = db.prepare('SELECT id FROM users WHERE username = ?');
            const senderRow = getUserId.get(sender);
            const receiverRow = getUserId.get(receiver);
            if (!senderRow || !receiverRow) {
                console.error("send-images user not found:", { senderRow, receiverRow });
                return;
            }

            // Store each image message in DB and collect payloads
            const insert = db.prepare(`
                INSERT INTO messages (senderId, receiverId, text, mediaUrl, mediaType, originalName, groupId)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            `);
            const messages = [];
            for (let i = 0; i < mediaUrls.length; i++) {
                const mediaUrl = mediaUrls[i];
                const originalName = originalNames[i];
                const result = insert.run(
                    senderRow.id,
                    receiverRow.id,
                    text || null,
                    mediaUrl || null,
                    mediaType || null,
                    originalName || null,
                    groupId || null
                );
                const messageId = result.lastInsertRowid;
                messages.push({
                    text,
                    mediaUrl,
                    mediaType,
                    messageId,
                    originalName
                });
            }
            // Emit to receiver if online
            const receiverSocket = connectedUsers.get(receiver);
            if (receiverSocket) {
                receiverSocket.emit('receive-images', {
                    from: sender,
                    groupId,
                    messages
                });
                console.log("💌 Emitting to receiverSocket with images:", { groupId, messages });
            } else {
                console.error('send-images cannot find receiver', connectedUsers);
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