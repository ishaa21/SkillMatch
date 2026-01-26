const Application = require('../models/Application');
const Student = require('../models/Student');
const Internship = require('../models/Internship');
const Company = require('../models/Company');
const AIConfig = require('../models/AIConfig');
const { calculateMatchScore, DEFAULT_WEIGHTS } = require('../utils/aiMatcher');

// @desc    Get applicants for an internship with AI match scores
// @route   GET /api/applications/internship/:internshipId
// @access  Private (Company only)
exports.getApplicantsForInternship = async (req, res) => {
    try {
        const { internshipId } = req.params;
        const internship = await Internship.findById(internshipId);
        if (!internship) {
            return res.status(404).json({ message: 'Internship not found' });
        }

        const applications = await Application.find({ internship: internshipId })
            .populate({
                path: 'student',
                populate: { path: 'user', select: '-password' }
            })
            .populate('internship');

        // Fetch AI Configuration for real-time weights
        const aiConfig = await AIConfig.findOne();
        const weights = aiConfig ? aiConfig.weights : DEFAULT_WEIGHTS;

        const appsWithScore = applications.map(app => {
            const student = app.student;
            const score = calculateMatchScore(student, internship, weights);
            return {
                ...app.toObject(),
                aiMatchScore: score.overallScore,
                matchBreakdown: score.breakdown
            };
        }).sort((a, b) => b.aiMatchScore - a.aiMatchScore);

        res.json(appsWithScore);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Update application status
// @route   PUT /api/applications/:id/status
// @access  Private (Company only)
exports.updateApplicationStatus = async (req, res) => {
    try {
        const { status } = req.body;
        const applicationId = req.params.id;

        const application = await Application.findByIdAndUpdate(
            applicationId,
            { status },
            { new: true }
        );

        if (!application) {
            return res.status(404).json({ message: 'Application not found' });
        }

        // Notify Student via Socket.IO
        const io = req.app.get('io');
        if (io) {
            // Populate student to get user ID
            const appWithStudent = await Application.findById(application._id).populate('student');
            if (appWithStudent && appWithStudent.student && appWithStudent.student.user) {
                const studentUserId = appWithStudent.student.user.toString();
                io.to(studentUserId).emit('application_updated', {
                    applicationId: application._id,
                    status: status,
                    message: `Your application status has been updated to ${status}`
                });
            }
        }

        res.json(application);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Apply to an internship (Student)
// @route   POST /api/applications
// @access  Private (Student only)
exports.applyToInternship = async (req, res) => {
    try {
        const student = await Student.findOne({ user: req.user.id });
        if (!student) {
            return res.status(404).json({ message: 'Student profile not found. Please complete profile first.' });
        }

        const { internshipId, coverLetter } = req.body;

        // Strict validation for ID to prevent CastErrors
        if (!internshipId || internshipId === 'null' || internshipId === 'undefined') {
            return res.status(400).json({ message: 'Invalid or missing Internship ID' });
        }

        const mongoose = require('mongoose');
        if (!mongoose.Types.ObjectId.isValid(internshipId)) {
            return res.status(400).json({ message: 'Invalid Internship ID Format' });
        }

        const internship = await Internship.findById(internshipId).populate('company');
        if (!internship) {
            return res.status(404).json({ message: 'Internship not found' });
        }

        // Check if already applied
        const existingApplication = await Application.findOne({
            student: student._id,
            internship: internshipId
        });

        if (existingApplication) {
            return res.status(400).json({ message: 'Already applied to this internship' });
        }

        // Calculate Real AI Score
        const aiConfig = await AIConfig.findOne();
        const weights = aiConfig ? aiConfig.weights : DEFAULT_WEIGHTS;
        const aiMatchScore = calculateMatchScore(student, internship, weights);

        // Extract company ID safely
        const companyId = internship.company?._id || internship.company;

        if (!companyId) {
            console.error(`Application Failed: Internship ${internshipId} has no company linked.`);
            return res.status(500).json({ message: 'Cannot apply: This internship is not linked to a valid company.' });
        }

        const newApplication = await Application.create({
            student: student._id,
            internship: internshipId,
            company: companyId,
            status: 'Applied',
            coverLetter: coverLetter || '',
            aiMatchScore: (Number.isFinite(aiMatchScore.overallScore) && !Number.isNaN(aiMatchScore.overallScore))
                ? aiMatchScore.overallScore
                : 0,
            matchBreakdown: aiMatchScore.breakdown
        });

        // Notify Company via Socket.IO
        const io = req.app.get('io');
        if (io && internship.company?.user) {
            const companyUserId = internship.company.user.toString();

            io.to(companyUserId).emit('new_application', {
                internshipTitle: internship.title,
                studentName: student.fullName,
                applicationId: newApplication._id
            });
        }

        res.status(201).json(newApplication);
    } catch (error) {
        console.error('Apply Internship Error:', error);
        res.status(500).json({ message: 'Server error: ' + error.message });
    }
};

// @desc    Get student's applications
// @route   GET /api/applications/my-applications
// @access  Private (Student only)
exports.getMyApplications = async (req, res) => {
    try {
        const student = await Student.findOne({ user: req.user.id });
        if (!student) {
            return res.status(404).json({ message: 'Student profile not found' });
        }

        const applications = await Application.find({ student: student._id })
            .populate({
                path: 'internship',
                populate: { path: 'company' }
            });

        res.json(applications);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Withdraw application
// @route   POST /api/applications/:id/withdraw
// @access  Private (Student only)
exports.withdrawApplication = async (req, res) => {
    try {
        const applicationId = req.params.id;
        const student = await Student.findOne({ user: req.user.id });
        if (!student) return res.status(404).json({ message: 'Student profile not found' });

        const application = await Application.findOne({
            _id: applicationId,
            student: student._id
        });

        if (!application) {
            return res.status(404).json({ message: 'Application not found or not authorized' });
        }

        if (application.status === 'Withdrawn') {
            return res.status(400).json({ message: 'Application already withdrawn' });
        }

        application.status = 'Withdrawn';
        await application.save();

        res.json({ message: 'Application withdrawn successfully', application });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};
