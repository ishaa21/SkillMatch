const Student = require('../models/Student');
const Internship = require('../models/Internship');
const Application = require('../models/Application');
const { rankInternshipsForStudent, calculateMatchScore } = require('../utils/aiMatcher');

// @desc    Get AI-powered recommended internships for student
// @route   GET /api/student/recommendations
// @access  Private (Student)
exports.getRecommendations = async (req, res) => {
    try {
        const student = await Student.findOne({ user: req.user.id });
        if (!student) {
            return res.status(404).json({ message: 'Student profile not found' });
        }

        // Get min score from query or default to 30
        const minScore = parseInt(req.query.minScore) || 30;
        const limit = parseInt(req.query.limit) || 20;

        // Get active internships
        const internships = await Internship.find({
            isActive: true,
            status: 'Active',
            deadline: { $gte: new Date() }
        }).populate('company');

        // Rank by AI match score
        const ranked = rankInternshipsForStudent(student, internships, null, minScore);

        // Limit results
        const limited = ranked.slice(0, limit);

        res.json({
            total: ranked.length,
            showing: limited.length,
            recommendations: limited
        });
    } catch (error) {
        console.error('Recommendations error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// @desc    Get internships with advanced filtering
// @route   GET /api/student/internships
// @access  Private (Student)
// Query params: ?skills[]=React&location=Delhi&minStipend=10000&maxStipend=50000&workMode=Remote&page=1&limit=10
exports.getInternships = async (req, res) => {
    try {
        const {
            skills,
            location,
            city,
            state,
            minStipend,
            maxStipend,
            workMode,
            domains,
            page = 1,
            limit = 10,
            sortBy = 'postedAt',
            sortOrder = 'desc',
            search
        } = req.query;

        // Build query
        const query = {
            isActive: true,
            status: 'Active',
            deadline: { $gte: new Date() }
        };

        // Skills filter
        if (skills) {
            const skillsArray = Array.isArray(skills) ? skills : [skills];
            query['requiredSkills.name'] = { $in: skillsArray.map(s => new RegExp(s, 'i')) };
        }

        // Location filters
        if (city) {
            query['location.city'] = new RegExp(city, 'i');
        }
        if (state) {
            query['location.state'] = new RegExp(state, 'i');
        }
        if (location) {
            // Generic location search
            query.$or = [
                { 'location.city': new RegExp(location, 'i') },
                { 'location.state': new RegExp(location, 'i') },
                { 'location.address': new RegExp(location, 'i') }
            ];
        }

        // Stipend filter
        if (minStipend || maxStipend) {
            query['stipend.min'] = {};
            if (minStipend) query['stipend.min'].$gte = parseInt(minStipend);
            if (maxStipend) query['stipend.max'] = { $lte: parseInt(maxStipend) };
        }

        // Work mode filter
        if (workMode) {
            query.workMode = workMode;
        }

        // Domains filter
        if (domains) {
            const domainsArray = Array.isArray(domains) ? domains : [domains];
            query.domains = { $in: domainsArray };
        }

        // Text search
        if (search) {
            query.$text = { $search: search };
        }

        // Pagination
        const skip = (parseInt(page) - 1) * parseInt(limit);

        // Sort options
        const sort = {};
        sort[sortBy] = sortOrder === 'desc' ? -1 : 1;

        // Execute query
        const [internships, total] = await Promise.all([
            Internship.find(query)
                .populate('company', 'companyName logoUrl location')
                .sort(sort)
                .skip(skip)
                .limit(parseInt(limit)),
            Internship.countDocuments(query)
        ]);

        // Get student for match scores (optional)
        const student = await Student.findOne({ user: req.user.id });

        // Add match scores if student profile exists
        const internshipsWithScores = student ? internships.map(intern => {
            const score = calculateMatchScore(student, intern);
            return {
                ...intern.toObject(),
                matchScore: score.overallScore,
                matchBreakdown: score.breakdown
            };
        }) : internships;

        res.json({
            internships: internshipsWithScores,
            pagination: {
                currentPage: parseInt(page),
                totalPages: Math.ceil(total / parseInt(limit)),
                totalItems: total,
                itemsPerPage: parseInt(limit)
            },
            filters: req.query
        });
    } catch (error) {
        console.error('Get internships error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// @desc    Apply for an internship
// @route   POST /api/student/apply/:internshipId
// @access  Private (Student)
exports.applyForInternship = async (req, res) => {
    try {
        const { internshipId } = req.params;
        const { coverLetter, questionsAnswers, resumeUrl } = req.body;

        // Get student
        const student = await Student.findOne({ user: req.user.id });
        if (!student) {
            return res.status(404).json({ message: 'Student profile not found' });
        }

        // Check profile completion >= 80%
        if (student.profileComplete < 80) {
            return res.status(400).json({
                success: false,
                message: 'Profile must be at least 80% complete to apply',
                profileComplete: student.profileComplete,
                requiredComplete: 80
            });
        }

        // Get internship
        const internship = await Internship.findById(internshipId);
        if (!internship) {
            return res.status(404).json({ message: 'Internship not found' });
        }

        // Check if internship is active
        if (!internship.isActive || internship.status !== 'Active') {
            return res.status(400).json({ message: 'Internship is not accepting applications' });
        }

        // Check deadline
        if (new Date() > internship.deadline) {
            return res.status(400).json({ message: 'Application deadline has passed' });
        }

        // Check if already applied
        const existingApplication = await Application.findOne({
            student: student._id,
            internship: internshipId
        });

        if (existingApplication) {
            return res.status(400).json({
                message: 'You have already applied for this internship',
                application: existingApplication
            });
        }

        // Calculate AI match score
        const matchResult = calculateMatchScore(student, internship);

        // Create application
        const application = new Application({
            internship: internshipId,
            student: student._id,
            company: internship.company,
            status: 'Applied',
            coverLetter,
            questionsAnswers,
            resumeUrl: resumeUrl || student.resumeUrl,
            matchScore: matchResult.overallScore,
            matchBreakdown: matchResult.breakdown,
            timeline: [{
                status: 'Applied',
                timestamp: new Date(),
                note: 'Application submitted'
            }]
        });

        await application.save();

        // Update internship applicants
        internship.applicants.push(student._id);
        internship.applications.push(application._id);
        internship.totalApplications += 1;
        await internship.save();

        // Update student
        student.appliedInternships.push(application._id);
        student.totalApplications += 1;
        await student.save();

        // TODO: Create notification for company

        res.status(201).json({
            success: true,
            message: 'Application submitted successfully',
            application,
            matchScore: matchResult.overallScore
        });
    } catch (error) {
        console.error('Apply error:', error);
        if (error.code === 11000) {
            return res.status(400).json({ message: 'Duplicate application detected' });
        }
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// @desc    Get student's applications with tracking
// @route   GET /api/student/applications
// @access  Private (Student)
exports.getMyApplications = async (req, res) => {
    try {
        const student = await Student.findOne({ user: req.user.id });
        if (!student) {
            return res.status(404).json({ message: 'Student profile not found' });
        }

        const { status, page = 1, limit = 10 } = req.query;

        const query = { student: student._id };
        if (status) {
            query.status = status;
        }

        const skip = (parseInt(page) - 1) * parseInt(limit);

        const [applications, total] = await Promise.all([
            Application.find(query)
                .populate({
                    path: 'internship',
                    populate: { path: 'company', select: 'companyName logoUrl' }
                })
                .sort({ appliedAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            Application.countDocuments(query)
        ]);

        res.json({
            applications,
            pagination: {
                currentPage: parseInt(page),
                totalPages: Math.ceil(total / parseInt(limit)),
                totalItems: total
            }
        });
    } catch (error) {
        console.error('Get applications error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// @desc    Get profile completion details
// @route   GET /api/student/profile/completion
// @access  Private (Student)
exports.getProfileCompletion = async (req, res) => {
    try {
        const student = await Student.findOne({ user: req.user.id });
        if (!student) {
            return res.status(404).json({ message: 'Student profile not found' });
        }

        const breakdown = {
            overall: student.profileComplete,
            sections: {
                basicInfo: {
                    complete: !!(student.fullName && student.phone && student.email && student.bio && student.profilePicture),
                    weight: 10,
                    items: {
                        fullName: !!student.fullName,
                        phone: !!student.phone,
                        email: !!student.email,
                        bio: !!student.bio && student.bio.length >= 50,
                        profilePicture: !!student.profilePicture
                    }
                },
                education: {
                    complete: student.education && student.education.length > 0,
                    weight: 25,
                    count: student.education ? student.education.length : 0,
                    items: student.education
                },
                skills: {
                    complete: student.skills && student.skills.length >= 3,
                    weight: 30,
                    count: student.skills ? student.skills.length : 0,
                    items: student.skills
                },
                experience: {
                    complete: student.experience && student.experience.length > 0,
                    weight: 15,
                    count: student.experience ? student.experience.length : 0
                },
                projects: {
                    complete: student.projects && student.projects.length > 0,
                    weight: 10,
                    count: student.projects ? student.projects.length : 0
                },
                certifications: {
                    complete: student.certifications && student.certifications.length > 0,
                    weight: 10,
                    count: student.certifications ? student.certifications.length : 0
                },
                resume: {
                    complete: !!student.resumeUrl,
                    weight: 10,
                    url: student.resumeUrl
                }
            },
            canApply: student.profileComplete >= 80,
            missingForApplication: student.profileComplete < 80 ? 80 - student.profileComplete : 0
        };

        res.json(breakdown);
    } catch (error) {
        console.error('Profile completion error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Re-export functions from original studentController file
// These are the core CRUD operations that exist in the base controller
const originalStudentController = require('./studentController');

// Use original implementations if they exist, otherwise provide fallback implementations
exports.getProfile = originalStudentController.getProfile
    ? originalStudentController.getProfile
    : async function (req, res) {
        try {
            const student = await Student.findOne({ user: req.user.id });
            if (!student) {
                return res.status(404).json({ message: 'Student profile not found' });
            }
            res.json(student);
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: 'Server error' });
        }
    };

exports.updateProfile = originalStudentController.updateProfile
    ? originalStudentController.updateProfile
    : async function (req, res) {
        try {
            const student = await Student.findOneAndUpdate(
                { user: req.user.id },
                { $set: req.body },
                { new: true, upsert: true, runValidators: true }
            );
            res.json(student);
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: 'Server error' });
        }
    };

exports.uploadResume = originalStudentController.uploadResume
    ? originalStudentController.uploadResume
    : async function (req, res) {
        try {
            if (!req.file) {
                return res.status(400).json({ message: 'Please upload a file' });
            }

            const resumeUrl = `/uploads/resumes/${req.file.filename}`;

            const student = await Student.findOneAndUpdate(
                { user: req.user.id },
                {
                    resumeUrl: resumeUrl,
                    resumeLastUpdated: new Date()
                },
                { new: true }
            );

            if (!student) {
                return res.status(404).json({ message: 'Student profile not found' });
            }

            res.json({ message: 'Resume uploaded successfully', resumeUrl, student });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: 'Server error' });
        }
    };

exports.toggleSavedInternship = originalStudentController.toggleSavedInternship;
exports.getSavedInternships = originalStudentController.getSavedInternships;
