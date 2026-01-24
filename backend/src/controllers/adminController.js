const Company = require('../models/Company');
const Student = require('../models/Student');
const Internship = require('../models/Internship');
const Application = require('../models/Application');
const User = require('../models/User');
const AIConfig = require('../models/AIConfig');
const { DEFAULT_WEIGHTS } = require('../utils/aiMatcher');
const mcaService = require('../services/mcaService');

// @desc    Get Admin Dashboard Statistics with Analytics
// @route   GET /api/admin/stats
// @access  Private (Admin only)
exports.getDashboardStats = async (req, res) => {
    try {
        // Basic counts
        const totalCompanies = await Company.countDocuments();
        const totalStudents = await Student.countDocuments();
        const totalInternships = await Internship.countDocuments();
        const totalApplications = await Application.countDocuments();

        // Status breakdowns
        const pendingCompanies = await Company.countDocuments({ isApproved: false, isSuspended: { $ne: true } });
        const approvedCompanies = await Company.countDocuments({ isApproved: true, isSuspended: { $ne: true } });
        const suspendedCompanies = await Company.countDocuments({ isSuspended: true });
        const activeInternships = await Internship.countDocuments({ isActive: true });
        const inactiveInternships = await Internship.countDocuments({ isActive: false });

        // Application Status breakdown
        const appStatusBreakdown = await Application.aggregate([
            { $group: { _id: "$status", count: { $sum: 1 } } }
        ]);

        // Recent activity (last 7 days)
        const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
        const recentApplications = await Application.countDocuments({ appliedAt: { $gte: sevenDaysAgo } });
        const recentStudents = await User.countDocuments({ role: 'student', createdAt: { $gte: sevenDaysAgo } });
        const recentCompanies = await User.countDocuments({ role: 'company', createdAt: { $gte: sevenDaysAgo } });

        // Work mode distribution
        const workModeBreakdown = await Internship.aggregate([
            { $match: { isActive: true } },
            { $group: { _id: "$workMode", count: { $sum: 1 } } }
        ]);

        // Industry distribution
        const industryBreakdown = await Company.aggregate([
            { $group: { _id: "$industry", count: { $sum: 1 } } },
            { $sort: { count: -1 } },
            { $limit: 10 }
        ]);

        // Trending internships (by applications)
        const trendingInternships = await Application.aggregate([
            { $group: { _id: "$internship", applicationCount: { $sum: 1 } } },
            { $sort: { applicationCount: -1 } },
            { $limit: 5 },
            {
                $lookup: {
                    from: 'internships',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'internship'
                }
            },
            { $unwind: '$internship' },
            {
                $lookup: {
                    from: 'companies',
                    localField: 'internship.company',
                    foreignField: '_id',
                    as: 'company'
                }
            },
            { $unwind: '$company' },
            {
                $project: {
                    title: '$internship.title',
                    companyName: '$company.companyName',
                    applicationCount: 1
                }
            }
        ]);

        res.json({
            metrics: {
                totalStudents,
                totalCompanies,
                totalInternships,
                totalApplications,
                pendingCompanies,
                approvedCompanies,
                suspendedCompanies,
                activeInternships,
                inactiveInternships
            },
            recentActivity: {
                applications: recentApplications,
                students: recentStudents,
                companies: recentCompanies
            },
            appStatusBreakdown,
            workModeBreakdown,
            industryBreakdown,
            trendingInternships
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error: ' + error.message });
    }
};

// @desc    Get All Companies with filtering
// @route   GET /api/admin/companies
// @access  Private (Admin only)
exports.getCompanies = async (req, res) => {
    try {
        const { status, search, page = 1, limit = 50 } = req.query;
        let filter = {};

        if (status === 'pending') filter.isApproved = false;
        else if (status === 'approved') filter = { isApproved: true, isSuspended: { $ne: true } };
        else if (status === 'suspended') filter.isSuspended = true;

        if (search) {
            filter.$or = [
                { companyName: { $regex: search, $options: 'i' } },
                { industry: { $regex: search, $options: 'i' } }
            ];
        }

        const companies = await Company.find(filter)
            .populate('user', 'email phoneNumber createdAt')
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(parseInt(limit));

        const total = await Company.countDocuments(filter);

        res.json({
            companies,
            pagination: {
                total,
                page: parseInt(page),
                pages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error: ' + error.message });
    }
};

// @desc    Update Company Status (Approve/Reject/Suspend/Reactivate)
// @route   PATCH /api/admin/companies/:id/status
// @access  Private (Admin only)
exports.updateCompanyStatus = async (req, res) => {
    try {
        const { action } = req.body; // 'approve', 'reject', 'suspend', 'reactivate'
        const company = await Company.findById(req.params.id).populate('user', 'email');

        if (!company) {
            return res.status(404).json({ message: 'Company not found' });
        }

        let message = '';
        switch (action) {
            case 'approve':
                company.isApproved = true;
                company.isSuspended = false;
                company.approvedAt = new Date();
                message = `Company ${company.companyName} has been approved`;
                break;
            case 'reject':
                company.isApproved = false;
                company.rejectedAt = new Date();
                message = `Company ${company.companyName} registration has been rejected`;
                break;
            case 'suspend':
                company.isSuspended = true;
                company.suspendedAt = new Date();
                // Also deactivate all their internships
                await Internship.updateMany({ company: company._id }, { isActive: false });
                message = `Company ${company.companyName} has been suspended and all internships deactivated`;
                break;
            case 'reactivate':
                company.isSuspended = false;
                company.reactivatedAt = new Date();
                message = `Company ${company.companyName} has been reactivated`;
                break;
            default:
                return res.status(400).json({ message: 'Invalid action. Use: approve, reject, suspend, or reactivate' });
        }

        await company.save();

        res.json({
            message,
            company
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error: ' + error.message });
    }
};

// @desc    Get All Students with filtering
// @route   GET /api/admin/students
// @access  Private (Admin only)
exports.getStudents = async (req, res) => {
    try {
        const { search, page = 1, limit = 50 } = req.query;
        let filter = {};

        if (search) {
            filter.$or = [
                { fullName: { $regex: search, $options: 'i' } },
                { university: { $regex: search, $options: 'i' } }
            ];
        }

        const students = await Student.find(filter)
            .populate('user', 'email phoneNumber createdAt')
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(parseInt(limit));

        // Get application count for each student
        const studentsWithStats = await Promise.all(students.map(async (student) => {
            const applicationCount = await Application.countDocuments({ student: student._id });
            return {
                ...student.toObject(),
                applicationCount
            };
        }));

        const total = await Student.countDocuments(filter);

        res.json({
            students: studentsWithStats,
            pagination: {
                total,
                page: parseInt(page),
                pages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error: ' + error.message });
    }
};

// @desc    Get All Internships with statistics
// @route   GET /api/admin/internships
// @access  Private (Admin only)
exports.getInternships = async (req, res) => {
    try {
        const { status, search, page = 1, limit = 50 } = req.query;
        let filter = {};

        if (status === 'active') filter.isActive = true;
        else if (status === 'inactive') filter.isActive = false;

        if (search) {
            filter.$or = [
                { title: { $regex: search, $options: 'i' } },
                { location: { $regex: search, $options: 'i' } }
            ];
        }

        const internships = await Internship.find(filter)
            .populate('company', 'companyName industry isApproved isSuspended')
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(parseInt(limit));

        // Get application count for each internship
        const internshipsWithStats = await Promise.all(internships.map(async (internship) => {
            const applicationCount = await Application.countDocuments({ internship: internship._id });
            const statusBreakdown = await Application.aggregate([
                { $match: { internship: internship._id } },
                { $group: { _id: "$status", count: { $sum: 1 } } }
            ]);
            return {
                ...internship.toObject(),
                applicationCount,
                statusBreakdown
            };
        }));

        const total = await Internship.countDocuments(filter);

        res.json({
            internships: internshipsWithStats,
            pagination: {
                total,
                page: parseInt(page),
                pages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error: ' + error.message });
    }
};

// @desc    Get All Applications across platform
// @route   GET /api/admin/applications
// @access  Private (Admin only)
exports.getAllApplications = async (req, res) => {
    try {
        const { status, page = 1, limit = 50 } = req.query;
        let filter = {};

        if (status) filter.status = status;

        const applications = await Application.find(filter)
            .populate({
                path: 'student',
                select: 'fullName university skills',
                populate: { path: 'user', select: 'email' }
            })
            .populate({
                path: 'internship',
                select: 'title workMode location'
            })
            .populate({
                path: 'company',
                select: 'companyName industry'
            })
            .sort({ appliedAt: -1 })
            .skip((page - 1) * limit)
            .limit(parseInt(limit));

        const total = await Application.countDocuments(filter);

        res.json({
            applications,
            pagination: {
                total,
                page: parseInt(page),
                pages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error: ' + error.message });
    }
};

// @desc    Get AI Configuration
// @route   GET /api/admin/ai-config
// @access  Private (Admin only)
exports.getAIConfig = async (req, res) => {
    try {
        let config = await AIConfig.findOne();
        if (!config) {
            // Create default config if none exists
            config = await AIConfig.create({
                weights: {
                    skills: DEFAULT_WEIGHTS.skills,
                    domains: DEFAULT_WEIGHTS.domains,
                    preferences: DEFAULT_WEIGHTS.preferences,
                    location: DEFAULT_WEIGHTS.location,
                    experience: 0.0 // New weight for experience
                }
            });
        }
        res.json(config);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error: ' + error.message });
    }
};

// @desc    Update AI Configuration
// @route   PUT /api/admin/ai-config
// @access  Private (Admin only)
exports.updateAIConfig = async (req, res) => {
    try {
        const { weights } = req.body;

        // Validate weights sum - should be close to 1.0
        const sum = Object.values(weights).reduce((a, b) => a + b, 0);
        if (sum < 0.9 || sum > 1.1) {
            return res.status(400).json({
                message: `Weights should sum to approximately 1.0 (current sum: ${sum.toFixed(2)})`
            });
        }

        let config = await AIConfig.findOne();
        if (config) {
            config.weights = weights;
            config.updatedAt = Date.now();
            await config.save();
        } else {
            config = await AIConfig.create({ weights });
        }

        res.json({ message: 'AI weights updated successfully', config });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error: ' + error.message });
    }
};

// @desc    Toggle Internship Status (Admin override)
// @route   PATCH /api/admin/internships/:id/toggle
// @access  Private (Admin only)
exports.toggleInternshipStatus = async (req, res) => {
    try {
        const internship = await Internship.findById(req.params.id);
        if (!internship) {
            return res.status(404).json({ message: 'Internship not found' });
        }

        internship.isActive = !internship.isActive;
        internship.adminModified = true;
        internship.adminModifiedAt = new Date();
        await internship.save();

        res.json({
            message: `Internship ${internship.isActive ? 'activated' : 'deactivated'} by admin`,
            internship
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error: ' + error.message });
    }
};

// @desc    Delete User Account with cascade
// @route   DELETE /api/admin/users/:id
// @access  Private (Admin only)
exports.deleteUser = async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Prevent self-deletion
        if (user._id.toString() === req.user.id) {
            return res.status(400).json({ message: 'Cannot delete your own account' });
        }

        // Prevent deleting other admins
        if (user.role === 'admin') {
            return res.status(400).json({ message: 'Cannot delete admin accounts through this endpoint' });
        }

        // Cascade delete based on role
        if (user.role === 'student') {
            const student = await Student.findOne({ user: user._id });
            if (student) {
                await Application.deleteMany({ student: student._id });
                await Student.deleteOne({ _id: student._id });
            }
        } else if (user.role === 'company') {
            const company = await Company.findOne({ user: user._id });
            if (company) {
                // Delete all applications to their internships
                const internshipIds = await Internship.find({ company: company._id }).distinct('_id');
                await Application.deleteMany({ internship: { $in: internshipIds } });
                await Internship.deleteMany({ company: company._id });
                await Company.deleteOne({ _id: company._id });
            }
        }

        await User.deleteOne({ _id: user._id });
        res.json({ message: 'User and all associated data deleted successfully' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error: ' + error.message });
    }
};

// @desc    Get Analytics Data for Charts
// @route   GET /api/admin/analytics
// @access  Private (Admin only)
exports.getAnalytics = async (req, res) => {
    try {
        // Applications over time (last 30 days)
        const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
        const applicationsTrend = await Application.aggregate([
            { $match: { appliedAt: { $gte: thirtyDaysAgo } } },
            {
                $group: {
                    _id: { $dateToString: { format: "%Y-%m-%d", date: "$appliedAt" } },
                    count: { $sum: 1 }
                }
            },
            { $sort: { _id: 1 } }
        ]);

        // Registrations over time (last 30 days)
        const registrationsTrend = await User.aggregate([
            { $match: { createdAt: { $gte: thirtyDaysAgo } } },
            {
                $group: {
                    _id: {
                        date: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
                        role: "$role"
                    },
                    count: { $sum: 1 }
                }
            },
            { $sort: { "_id.date": 1 } }
        ]);

        // Success rate (Hired vs Total)
        const totalApps = await Application.countDocuments();
        const hiredApps = await Application.countDocuments({ status: 'Hired' });
        const successRate = totalApps > 0 ? ((hiredApps / totalApps) * 100).toFixed(1) : 0;

        // Average AI Match Score
        const avgMatchScore = await Application.aggregate([
            { $match: { aiMatchScore: { $exists: true, $ne: null } } },
            { $group: { _id: null, avgScore: { $avg: "$aiMatchScore" } } }
        ]);

        // Top Skills in demand
        const topSkills = await Internship.aggregate([
            { $match: { isActive: true } },
            { $unwind: "$skillsRequired" },
            { $group: { _id: "$skillsRequired", count: { $sum: 1 } } },
            { $sort: { count: -1 } },
            { $limit: 10 }
        ]);

        res.json({
            applicationsTrend,
            registrationsTrend,
            successRate: parseFloat(successRate),
            avgMatchScore: avgMatchScore[0]?.avgScore?.toFixed(1) || 0,
            topSkills
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error: ' + error.message });
    }
};

// @desc    Verify Company via MCA (Mock)
// @route   POST /api/admin/verify-company
// @access  Private (Admin only)
exports.verifyCompany = async (req, res) => {
    try {
        const { companyId, cin } = req.body;

        if (!companyId || !cin) {
            return res.status(400).json({ message: 'Company ID and CIN are required' });
        }

        const company = await Company.findById(companyId);
        if (!company) {
            return res.status(404).json({ message: 'Company not found' });
        }

        // Call Mock MCA Service
        const mcaResponse = await mcaService.fetchCompanyDetails(cin);

        if (!mcaResponse.success) {
            company.verificationStatus = 'Failed';
            company.verifiedAt = new Date();
            company.rejectionReason = mcaResponse.error.message;
            await company.save();

            return res.status(400).json({
                message: 'verification_failed',
                error: mcaResponse.error.message
            });
        }

        const mcaData = mcaResponse.data;

        // Check availability (Active)
        if (mcaData.status !== 'Active') {
            company.verificationStatus = 'Failed';
            company.verifiedAt = new Date();
            company.rejectionReason = `Company status is ${mcaData.status} (Not Active)`;
            await company.save();

            return res.status(400).json({
                message: 'company_inactive',
                status: mcaData.status
            });
        }

        // Success - Verify
        company.verificationStatus = 'Verified';
        company.cin = cin;
        company.mcaData = {
            legalName: mcaData.companyName,
            incorporationDate: mcaData.incorporationDate,
            status: mcaData.status,
            paidUpCapital: mcaData.paidUpCapital
        };
        company.verifiedAt = new Date();

        // Auto-approve if verified
        company.isApproved = true;
        company.isSuspended = false;

        await company.save();

        res.json({
            success: true,
            message: 'Company verified successfully',
            company
        });

    } catch (error) {
        console.error('Verification Error:', error);
        res.status(500).json({ message: 'Server error during verification' });
    }
};
