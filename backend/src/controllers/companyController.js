const Company = require('../models/Company');
const Internship = require('../models/Internship');
const Application = require('../models/Application');
const User = require('../models/User');

// @desc    Get company dashboard stats
// @route   GET /api/company/stats
// @access  Private (Company only)
exports.getDashboardStats = async (req, res) => {
    try {
        let company = await Company.findOne({ user: req.user.id });

        // If no company profile exists, create a default one
        if (!company) {
            const user = await User.findById(req.user.id);
            company = await Company.create({
                user: req.user.id,
                companyName: user?.email?.split('@')[0] || 'New Company',
                isApproved: false // Needs admin approval
            });
        }

        const internships = await Internship.find({ company: company._id });
        const internshipIds = internships.map(i => i._id);

        const applications = await Application.find({ internship: { $in: internshipIds } });

        const stats = {
            activeInternships: internships.filter(i => i.isActive).length,
            totalInternships: internships.length,
            totalApplicants: applications.length,
            shortlisted: applications.filter(a => a.status === 'Shortlisted').length,
            hired: applications.filter(a => a.status === 'Hired').length
        };

        res.json(stats);
    } catch (error) {
        console.error('getDashboardStats error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// @desc    Get company profile
// @route   GET /api/company/profile
// @access  Private (Company only)
exports.getProfile = async (req, res) => {
    try {
        let company = await Company.findOne({ user: req.user.id });
        const user = await User.findById(req.user.id).select('-password');

        // If no company profile exists, create a default one
        if (!company) {
            company = await Company.create({
                user: req.user.id,
                companyName: user?.email?.split('@')[0] || 'New Company',
                isApproved: false // Needs admin approval
            });
        }

        res.json({
            ...company.toObject(),
            email: user?.email || 'No email'
        });
    } catch (error) {
        console.error('getProfile error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// @desc    Update company profile
// @route   PUT /api/company/profile
// @access  Private (Company only)
exports.updateProfile = async (req, res) => {
    try {
        let company = await Company.findOneAndUpdate(
            { user: req.user.id },
            { $set: req.body },
            { new: true, runValidators: true, upsert: true }
        );

        if (!company) {
            // Create if doesn't exist
            company = await Company.create({
                user: req.user.id,
                ...req.body
            });
        }

        res.json(company);
    } catch (error) {
        console.error('updateProfile error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};
