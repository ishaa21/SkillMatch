const jwt = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
    let token;

    if (
        req.headers.authorization &&
        req.headers.authorization.startsWith('Bearer')
    ) {
        try {
            // Get token from header
            token = req.headers.authorization.split(' ')[1];

            // Verify token (use fallback secret to prevent crashes)
            const secret = process.env.JWT_SECRET || 'secret123';
            const decoded = jwt.verify(token, secret);

            // Get user from the token
            req.user = await User.findById(decoded.id).select('-password');

            if (!req.user) {
                return res.status(401).json({ message: 'User not found or deleted' });
            }

            next();
        } catch (error) {
            console.error('Auth Middleware Error:', error.message);
            // Distinguish specific JWT errors
            if (error.name === 'TokenExpiredError') {
                return res.status(401).json({ message: 'Session expired, please login again' });
            }
            if (error.name === 'JsonWebTokenError') {
                return res.status(401).json({ message: 'Invalid token' });
            }
            res.status(401).json({ message: 'Not authorized' });
        }
    }

    if (!token) {
        if (!res.headersSent) {
            res.status(401).json({ message: 'Not authorized, no token' });
        }
    }
};

const authorize = (...roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ message: 'Not authorized' });
        }
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({
                message: `User role ${req.user.role} is not authorized to access this route`
            });
        }
        next();
    };
};

module.exports = { protect, authorize };
