// AUTH CONTROLLER – PRODUCTION READY VERSION

const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Student = require('../models/Student');
const Company = require('../models/Company');

// =======================
// JWT Helper
// =======================
const generateToken = (id, role) => {
    // Ensure we have a secret. Fallback to 'secret123' if env missing (prevents crash).
    const secret = process.env.JWT_SECRET || 'secret123';
    return jwt.sign({ id, role }, secret, { expiresIn: '30d' });
};

// =======================
// REGISTER
// =======================
exports.register = async (req, res) => {
    console.log('Register Request:', req.body);
    const { email, password, role, ...profileData } = req.body;

    // 1. Validate Input
    if (!email || !password || !role) {
        return res.status(400).json({ message: 'Email, password, and role are required' });
    }

    if (role === 'admin') {
        return res.status(403).json({ message: 'Admin registration not allowed via public API' });
    }

    try {
        // 2. Check Exists
        const userExists = await User.findOne({ email });
        if (userExists) {
            return res.status(400).json({ message: 'User with this email already exists' });
        }

        // 3. Hash Password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // 4. Create User
        const user = await User.create({
            email,
            password: hashedPassword,
            role,
            isVerified: true
        });

        // 5. Create Role-Specific Profile
        try {
            if (role === 'student') {
                await Student.create({
                    user: user._id,
                    fullName: profileData.fullName || 'New Student',
                    skills: [],
                    education: '',
                    experience: []
                });
            } else if (role === 'company') {
                await Company.create({
                    user: user._id,
                    companyName: profileData.companyName || 'New Company',
                    industry: profileData.industry || 'Not specified',
                    location: profileData.location || 'Not specified',
                    isApproved: false
                });
            }
        } catch (profileError) {
            console.error('Profile Creation Failed. Rolling back User.', profileError);
            // Rollback user creation to prevent orphans
            await User.findByIdAndDelete(user._id);
            return res.status(500).json({ message: 'Failed to create user profile. Please try again.' });
        }

        // 6. Respond
        res.status(201).json({
            _id: user._id,
            email: user.email,
            role: user.role,
            token: generateToken(user._id, user.role),
            message: 'Registration successful'
        });

    } catch (error) {
        console.error('REGISTER ERROR:', error);
        res.status(500).json({
            message: 'Server error during registration',
            error: process.env.NODE_ENV === 'development' ? error.stack : undefined
        });
    }
};

// =======================
// LOGIN (ROBUST)
// =======================
exports.login = async (req, res) => {
    // console.log('Login Request:', req.body); // Uncomment for debug
    const { email, password } = req.body;

    try {
        // 1. Validate Input
        if (!email || !password) {
            return res.status(400).json({ message: 'Email and password are required' });
        }

        // 2. Find User & Explicitly Select Password
        // Use +password because `select: false` might be set in schema
        const user = await User.findOne({ email }).select('+password');

        if (!user) {
            // Generic message for security
            return res.status(401).json({ message: 'Invalid email or password' });
        }

        // 3. Check Protocol (OAuth vs Password)
        if (!user.password) {
            return res.status(400).json({
                message: 'This account uses a login provider (Google/LinkedIn). Please login with that method.'
            });
        }

        // 4. Compare Password
        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid email or password' });
        }

        // 5. Respond with Token
        res.json({
            _id: user._id,
            email: user.email,
            role: user.role,
            token: generateToken(user._id, user.role)
        });

    } catch (error) {
        console.error('LOGIN FLIGHT ERROR:', error);
        res.status(500).json({
            message: 'Server error during login',
            error: process.env.NODE_ENV === 'development' ? error.stack : undefined
        });
    }
};

// =======================
// GET CURRENT USER
// =======================
exports.getMe = async (req, res) => {
    try {
        // User is already attached to req by 'protect' middleware
        const user = await User.findById(req.user.id).select('-password');

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        let profile = null;
        if (user.role === 'student') {
            profile = await Student.findOne({ user: user._id });
        } else if (user.role === 'company') {
            profile = await Company.findOne({ user: user._id });
        }

        res.json({
            user,
            profile
        });

    } catch (error) {
        console.error('GET ME ERROR:', error);
        res.status(500).json({ message: 'Server error fetching profile' });
    }
};
