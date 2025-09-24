📱 iOS E2EE Messaging App (SwiftUI + Swift)
Welcome to the End-to-End Encrypted Messaging SDK for iOS. This project implements a secure, modular, and real-time messaging system with end-to-end encryption and live communication features.

GroupMessage:
https://github.com/user-attachments/assets/761e8660-c375-4836-bfdf-53d8d8697245

Demo:

https://github.com/user-attachments/assets/b7c4215a-dd9b-4064-8756-46c1929f5813


🎯 Project Overview
The project consists of two main components:
1. A Node.js-based chat server with WebSocket support
2. An iOS messaging app built with SwiftUI

✅ Core Features
1. 🧱 Server Architecture
- Express.js server with Socket.IO for real-time communication
- SQLite database for message and user storage
- RESTful API endpoints for user management and message history
- WebSocket implementation for real-time messaging

2. 📱 iOS App Architecture
- SwiftUI-based UI implementation
- Clean architecture with separate Views, Services, and Utils layers
- Real-time messaging using WebSocket
- End-to-end encryption for messages

3. 🔐 Security Features
- Public key exchange system for secure communication
- Session-based salt generation for message encryption
- Secure key storage and management
- End-to-end encrypted message transmission

4. 📡 Real-Time Features
- WebSocket-based real-time messaging
- User presence tracking
- Message delivery status
- Chat history with pagination

🔹 Technical Implementation Details

Server Side:
- Node.js with Express.js
- Socket.IO for WebSocket communication
- SQLite database for data persistence
- RESTful API endpoints:
  - User management (/users)
  - Message history (/messages)
  - Key exchange (/keys)
  - Session management (/session)

iOS App:
- SwiftUI for modern UI implementation
- MVVM architecture pattern
- WebSocket client for real-time communication
- Local storage for message history
- End-to-end encryption implementation

📚 API Documentation

1. User Management
- GET /users - List all users
- POST /users - Create or login user
- GET /users/chatted-with/:userId - Get users with chat history

2. Messaging
- GET /messages/:userA/:userB - Get chat history between users
- WebSocket events:
  - 'register' - User registration
  - 'send-message' - Send encrypted message
  - 'receive-message' - Receive encrypted message

3. Security
- POST /keys - Store user's public key
- GET /keys/:username - Retrieve user's public key
- POST /session - Create new chat session
- GET /session - Retrieve existing session

🔧 Setup Instructions

1. Server Setup
```bash
cd ChatServer
npm install
npm start
```

2. iOS App Setup
- Open MessagingApp.xcodeproj in Xcode
- Build and run the project

⭐ Additional Notes
- The project uses modern Swift features and SwiftUI for the iOS app
- Real-time communication is handled through WebSocket
- End-to-end encryption is implemented for secure messaging
- The server uses SQLite for data persistence
- The iOS app follows MVVM architecture pattern
