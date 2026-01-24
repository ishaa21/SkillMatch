// AUTH CONTROLLER - MongoDB Implementation
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Student = require('../models/Student');
const Company = require('../models/Company');
const Internship = require('../models/Internship');
const Application = require('../models/Application');

const generateToken = (id, role) => {
    return jwt.sign({ id, role }, process.env.JWT_SECRET || 'secret123', {
        expiresIn: '30d',
    });
};

// Register
exports.register = async (req, res) => {
    const { email, password, role, ...profileData } = req.body;

    try {
        if (!email || !password || !role) {
            return res.status(400).json({ message: 'Please add all fields' });
        }

        // Prevent admin registration via API - admins must be created directly in database
        if (role === 'admin') {
            return res.status(403).json({ message: 'Admin registration is not allowed' });
        }

        // Check if user exists
        const userExists = await User.findOne({ email });

        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Create user
        const user = await User.create({
            email,
            password: hashedPassword,
            role
        });

        // Create profile based on role
        if (role === 'company') {
            await Company.create({
                user: user._id,
                companyName: profileData.companyName || 'New Company',
                isApproved: false // Requires Admin Verification
            });
        } else if (role === 'student') {
            await Student.create({
                user: user._id,
                fullName: profileData.fullName || 'New Student'
            });
        }

        res.status(201).json({
            _id: user._id,
            email: user.email,
            role: user.role,
            token: generateToken(user._id, user.role),
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Login
exports.login = async (req, res) => {
    const { email, password } = req.body;

    try {
        console.log(`Login attempt for: ${email}`);

        // Check for user email
        const user = await User.findOne({ email });

        if (!user) {
            console.log('User not found');
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        // Check password
        const isMatch = await bcrypt.compare(password, user.password);

        if (isMatch) {
            console.log('Password match - login successful');
            res.json({
                _id: user._id,
                email: user.email,
                role: user.role,
                token: generateToken(user._id, user.role),
            });
        } else {
            console.log('Password mismatch');
            res.status(401).json({ message: 'Invalid credentials' });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Get me
exports.getMe = async (req, res) => {
    try {
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

        res.status(200).json({ user, profile });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// ... imports at the top are fine. ensure generateToken is available or move it up out of specific strict block scope if needed.

// Send OTP (Mock implementation for demo)
exports.sendOtp = async (req, res) => {
    const { phoneNumber, role } = req.body;

    try {
        if (!phoneNumber) {
            return res.status(400).json({ message: 'Phone number is required' });
        }

        let user = await User.findOne({ phoneNumber });

        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

        if (!user) {
            // New user registration flow via Phone
            if (!role) {
                // If checking for login only and user doesn't exist
                return res.status(404).json({ message: 'User not found. Please register.' });
            }

            user = await User.create({
                phoneNumber,
                role,
                otpCode: otp,
                otpExpires,
                isVerified: false
            });

            // Initialize profile
            if (role === 'student') {
                await Student.create({ user: user._id, fullName: 'New Student' });
            } else if (role === 'company') {
                await Company.create({ user: user._id, companyName: 'New Company', isApproved: true });
            }

        } else {
            // Existing user
            user.otpCode = otp;
            user.otpExpires = otpExpires;
            await user.save();
        }

        // In a real app, send SMS here (Twilio, Firebase, etc.)
        console.log(`OTP for ${phoneNumber}: ${otp}`);

        res.status(200).json({ message: 'OTP sent successfully', devOnlyOtp: otp });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Verify OTP
exports.verifyOtp = async (req, res) => {
    const { phoneNumber, otp } = req.body;

    try {
        if (!phoneNumber || !otp) {
            return res.status(400).json({ message: 'Phone and OTP are required' });
        }

        const user = await User.findOne({ phoneNumber });

        if (!user) {
            return res.status(400).json({ message: 'User not found' });
        }

        if (user.otpCode !== otp) {
            return res.status(400).json({ message: 'Invalid OTP' });
        }

        if (user.otpExpires < Date.now()) {
            return res.status(400).json({ message: 'OTP expired' });
        }

        // Clear OTP
        user.otpCode = undefined;
        user.otpExpires = undefined;
        user.isVerified = true;
        await user.save();

        res.json({
            _id: user._id,
            phoneNumber: user.phoneNumber,
            role: user.role,
            token: generateToken(user._id, user.role),
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Google Login (Stub/Simplified)
// In a real app, verify `idToken` from client with Google Auth SDK
exports.googleLogin = async (req, res) => {
    const { email, googleId, name, role } = req.body;

    try {
        if (!email || !googleId) {
            return res.status(400).json({ message: 'Email and Google ID required' });
        }

        let user = await User.findOne({ email });

        if (user) {
            // Link Google ID if not present
            if (!user.googleId) {
                user.googleId = googleId;
                await user.save();
            }
        } else {
            // Register new user
            if (!role) {
                return res.status(400).json({ message: 'Role required for new registration' });
            }

            user = await User.create({
                email,
                googleId,
                role,
                isVerified: true
            });

            if (role === 'student') {
                await Student.create({ user: user._id, fullName: name || 'New Student' });
            } else if (role === 'company') {
                await Company.create({ user: user._id, companyName: name || 'New Company', isApproved: true });
            }
        }

        res.json({
            _id: user._id,
            email: user.email,
            role: user.role,
            token: generateToken(user._id, user.role),
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// LinkedIn Login (Stub)
exports.linkedinLogin = async (req, res) => {
    // Similar implementation to Google
    res.status(501).json({ message: 'LinkedIn Auth not implemented yet' });
};

// Refresh Token (Conceptual)
exports.refreshToken = async (req, res) => {
    const { token } = req.body;
    // Verify refresh token logic here...
    res.status(501).json({ message: 'Refresh token flow not implemented yet' });
};

// PUBLIC ENDPOINTS
exports.getAllInternshipsPublic = async (req, res) => {
    try {
        const internships = await Internship.find({ isActive: true }).populate('company');
        res.json(internships);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Get all internships (Protected)
exports.getAllInternships = async (req, res) => {
    try {
        // Only show active internships? Or all? Let's say all for now or active.
        const internships = await Internship.find().populate('company');
        res.json(internships);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Get company's internships
exports.getCompanyInternships = async (req, res) => {
    try {
        // Find company profile for this user
        const company = await Company.findOne({ user: req.user.id });
        if (!company) {
            return res.status(404).json({ message: 'Company profile not found' });
        }

        const internships = await Internship.find({ company: company._id });
        res.json(internships);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Get applications for an internship
exports.getInternshipApplications = async (req, res) => {
    const { internshipId } = req.params;
    try {
        // Verify ownership/access if strictly needed here, but relying on route protection + simple fetch for now
        const applications = await Application.find({ internship: internshipId })
            .populate({
                path: 'student',
                populate: { path: 'user', select: '-password' }
            });

        // Reshape if needed to match frontend expectation of 'studentDetails' vs 'student'
        // Frontend expects 'student' object directly usually if populated.
        // The original mock returned both 'student' and 'studentDetails'.

        const formattedApps = applications.map(app => {
            const appObj = app.toObject();
            return {
                ...appObj,
                studentDetails: appObj.student // Compatibility
            };
        });

        res.json(formattedApps);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Update application status
exports.updateApplicationStatus = async (req, res) => {
    const { applicationId } = req.params;
    const { status } = req.body;

    try {
        const application = await Application.findById(applicationId);
        if (!application) {
            return res.status(404).json({ message: 'Application not found' });
        }

        application.status = status;
        await application.save();
        res.json(application);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Admin delete - kept from original
exports.deleteCompany = async (req, res) => {
    if (req.user.role !== 'admin') {
        return res.status(403).json({ message: 'Access denied' });
    }
    const { companyId } = req.params;
    try {
        await Company.findOneAndDelete({ _id: companyId }); // assuming companyId is the _id of company doc, not user
        // If companyId passed is actually userId, logic differs. 
        // Based on routes, it seems we pass ID. 
        // Let's assume passed ID is the USER ID for safety or COMPANY ID?
        // Let's just do a safe delete.
        await User.findByIdAndDelete(companyId); // If ID matches User
        res.json({ message: 'Company deleted' });
    } catch (err) {
        res.status(500).json({ message: 'Error deleting' });
    }
};

exports.deleteStudent = async (req, res) => {
    if (req.user.role !== 'admin') {
        return res.status(403).json({ message: 'Access denied' });
    }
    const { studentId } = req.params;
    try {
        await Student.findOneAndDelete({ user: studentId });
        await User.findByIdAndDelete(studentId);
        res.json({ message: 'Student deleted' });
    } catch (err) {
        res.status(500).json({ message: 'Error deleting' });
    }
};

// ... keep other admin exports
// But we need to ensure we don't duplicate exports.
// I will REPLACE the bottom part of the file with these new functions + the admin ones.

exports.getAllCompanies = async (req, res) => {
    if (req.user.role !== 'admin') return res.status(403).json({ message: 'Access denied' });
    const companies = await Company.find().populate('user', 'email');
    res.json(companies);
};

exports.getAllStudents = async (req, res) => {
    if (req.user.role !== 'admin') return res.status(403).json({ message: 'Access denied' });
    const students = await Student.find().populate('user', 'email');
    res.json(students);
};

exports.getAllApplications = async (req, res) => {
    if (req.user.role !== 'admin') return res.status(403).json({ message: 'Access denied' });
    // This might be heavy, but fine for now
    const applications = await require('../models/Application').find()
        .populate('student')
        .populate('company')
        .populate('internship');
    res.json(applications);
};

// Verify/Approve Company
exports.verifyCompany = async (req, res) => {
    if (req.user.role !== 'admin') {
        return res.status(403).json({ message: 'Access denied' });
    }
    const { companyId } = req.params; // Expects Company Profile ID or User ID? 
    // Let's assume we pass the Company Profile ID usually shown in lists.
    // However, clean implementation might pass _id.

    try {
        const company = await Company.findById(companyId);
        if (!company) {
            return res.status(404).json({ message: 'Company not found' });
        }

        company.isApproved = true;
        await company.save();

        res.json({ message: `Company ${company.companyName} approved successfully`, company });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Reject Company (Delete?)
// Could use deleteCompany endpoint for rejection.
