const fs = require('fs');
const path = require('path');
const Database = require('better-sqlite3');

const DB_PATH = path.resolve(__dirname, 'local.db');

// fs.unlink(DB_PATH, (err) => {
//     if (err) {
//         return console.error(err.message);
//     }
//     console.log('Database file deleted successfully.');
// });

// Check if the database file exists
const isNewDatabase = !fs.existsSync(DB_PATH);

// Open the database (creates it if it doesn't exist)
const db = new Database(DB_PATH);

if (true) {
    console.log('Creating new database and initializing tables...');
    // user
    db.prepare(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
  )
`).run();
    // message
    db.prepare(`
  CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    senderId INTEGER NOT NULL,
    receiverId INTEGER NOT NULL,
    text TEXT NOT NULL,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (senderId) REFERENCES users(id),
    FOREIGN KEY (receiverId) REFERENCES users(id)
  )
`).run();

// db.prepare(`DROP TABLE IF EXISTS secure_keys`).run();
    // secure_keys
    db.prepare(`
  CREATE TABLE IF NOT EXISTS secure_keys (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ownerId INTEGER UNIQUE NOT NULL,
    encryptKey TEXT NOT NULL,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ownerId) REFERENCES users(id)
  )
`).run();

// message_keys
db.prepare(`
  CREATE TABLE IF NOT EXISTS message_keys (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    senderId INTEGER NOT NULL,
    receiverId INTEGER NOT NULL,
    salt TEXT NOT NULL,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
  )
`).run();


    console.log('Database initialized.');
} else {
    console.log('Database already exists. Skipping initialization.');
}

const insertUser = db.prepare("INSERT OR IGNORE INTO users (username) VALUES (?)");

// Default users
insertUser.run("S");
insertUser.run("A");

module.exports = db;