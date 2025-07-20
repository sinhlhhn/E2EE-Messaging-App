

const jwt = require("jsonwebtoken");

function authenticateToken(req, res, next) {
    console.log("Checking authentication...");
    const authHeader = req.headers["authorization"];
    const token = authHeader && authHeader.split(" ")[1]; // Expect "Bearer <token>"

    if (!token) {
        console.log("Access token required");
        return res.status(401).json({ error: "Access token required" });
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) {
            console.log("Invalid or expired token");
            return res.status(403).json({ error: "Invalid or expired token" });
        }

        req.user = user; // Example: { sub: 1, username: "alice", iat: ..., exp: ... }
        console.log(`Valid user 👨‍💻`, user);
        next();
    });
}

module.exports = authenticateToken;