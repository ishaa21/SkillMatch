// AUTH CONTROLLER – FIXED & CLEANED VERSION

const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Student = require('../models/Student');
const Company = require('../models/Company');

// =======================
// JWT Helper
// =======================
const generateToken = (id, role) => {
    return jwt.sign(
        { id, role },
        process.env.JWT_SECRET || 'secret123',
        { expiresIn: '30d' }
    );
};

// =======================
// REGISTER
// =======================
exports.register = async (req, res) => {
    const { email, password, role, ...profileData } = req.body;

    try {
        if (!email || !password || !role) {
            return res.status(400).json({ message: 'Email, password and role are required' });
        }

        if (role === 'admin') {
            return res.status(403).json({ message: 'Admin registration not allowed' });
        }

        const userExists = await User.findOne({ email });
        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const user = await User.create({
            email,
            password: hashedPassword,
            role,
            isVerified: true
        });

        // Create profile safely (Validation handled by Mongoose Schema defaults where possible)
        if (role === 'student') {
            await Student.create({
                user: user._id,
                fullName: profileData.fullName || 'New Student',
                skills: [],
                education: '',
                experience: []
            });
        }

        if (role === 'company') {
            await Company.create({
                user: user._id,
                companyName: profileData.companyName || 'New Company',
                industry: profileData.industry || 'Not specified',
                location: profileData.location || 'Not specified',
                isApproved: false
            });
        }

        res.status(201).json({
            _id: user._id,
            email: user.email,
            role: user.role,
            token: generateToken(user._id, user.role)
        });

    } catch (error) {
        console.error('REGISTER ERROR:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

// =======================
// LOGIN (FIXED)
// =======================
exports.login = async (req, res) => {
    const { email, password } = req.body;

    try {
        if (!email || !password) {
            return res.status(400).json({ message: 'Email and password required' });
        }

        // Explicitly fetch password since it might be unselected by default in some setups
        const user = await User.findOne({ email }).select('+password');

        if (!user) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        if (!user.password) {
            // User registered via OAuth (Google/LinkedIn) and has no password
            return res.status(400).json({
                message: 'This account uses a different login method (Google/LinkedIn)'
            });
        }

        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        res.json({
            _id: user._id,
            email: user.email,
            role: user.role,
            token: generateToken(user._id, user.role)
        });

    } catch (error) {
        console.error('LOGIN ERROR:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

// =======================
// GET CURRENT USER
// =======================
exports.getMe = async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('-password');
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        let profile = null;
        if (user.role === 'student') {
            profile = await Student.findOne({ user: user._id });
        }
        if (user.role === 'company') {
            profile = await Company.findOne({ user: user._id });
        }

        res.json({ user, profile });

    } catch (error) {
        console.error('GET ME ERROR:', error);
        res.status(500).json({ message: 'Server error' });
    }
};
