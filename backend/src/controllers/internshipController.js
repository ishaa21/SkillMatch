const Internship = require('../models/Internship');
const Company = require('../models/Company');
const Student = require('../models/Student');
const AIConfig = require('../models/AIConfig');

const {
    rankInternshipsForStudent,
    DEFAULT_WEIGHTS,
} = require('../utils/aiMatcher');

const {
    normalizeInternshipForFlutter,
} = require('../utils/flutterDataNormalizer');

/**
 * ============================================================
 * STUDENT: Get AI-Recommended Internships
 * ============================================================
 * @route   GET /api/internships/recommendations
 * @access  Private (Student)
 */
exports.getRecommendedInternships = async (req, res) => {
    try {
        // 1️⃣ Fetch student profile
        const student = await Student.findOne({ user: req.user.id });
        if (!student) {
            return res.status(404).json({ message: 'Student profile not found' });
        }

        // 2️⃣ Build filter query
        const { domain, stipend, location, workMode, duration } = req.query;

        const query = { isActive: true };

        if (domain) query.domains = { $in: [domain] };

        if (stipend) {
            query['stipend.amount'] = { $gte: Number(stipend) };
        }

        if (location) {
            query.location = { $regex: location, $options: 'i' };
        }

        if (workMode && workMode !== 'Any') {
            query.workMode = workMode;
        }

        if (duration) {
            query.duration = { $regex: duration, $options: 'i' };
        }

        // 3️⃣ Fetch internships
        const internships = await Internship.find(query).populate('company');

        // 4️⃣ Load AI config
        const aiConfig = await AIConfig.findOne();
        const weights = aiConfig?.weights || DEFAULT_WEIGHTS;

        // 5️⃣ Rank internships using AI
        const rankedInternships = rankInternshipsForStudent(
            student,
            internships,
            weights
        );

        // 6️⃣ Normalize response for Flutter
        const normalizedInternships = rankedInternships.map(
            normalizeInternshipForFlutter
        );

        res.json(normalizedInternships);
    } catch (error) {
        console.error('AI Recommendation Error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

/**
 * ============================================================
 * COMPANY: Get All Company Internships
 * ============================================================
 * @route   GET /api/internships/my-internships
 * @access  Private (Company)
 */
exports.getCompanyInternships = async (req, res) => {
    try {
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

/**
 * ============================================================
 * COMPANY: Create Internship
 * ============================================================
 * @route   POST /api/internships
 * @access  Private (Company)
 */
exports.createInternship = async (req, res) => {
    try {
        const company = await Company.findOne({ user: req.user.id });

        if (!company) {
            return res.status(404).json({ message: 'Company profile not found' });
        }

        if (!company.isApproved) {
            return res.status(403).json({ message: 'Company not approved yet' });
        }

        const internship = await Internship.create({
            ...req.body,
            company: company._id,
            isActive: true,
        });

        res.status(201).json(internship);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

/**
 * ============================================================
 * COMPANY: Update Internship
 * ============================================================
 * @route   PUT /api/internships/:id
 * @access  Private (Company)
 */
exports.updateInternship = async (req, res) => {
    try {
        const internship = await Internship.findById(req.params.id);
        if (!internship) {
            return res.status(404).json({ message: 'Internship not found' });
        }

        const company = await Company.findOne({ user: req.user.id });
        if (!company) {
            return res.status(404).json({ message: 'Company profile not found' });
        }

        if (internship.company.toString() !== company._id.toString()) {
            return res.status(403).json({ message: 'Not authorized' });
        }

        const updatedInternship = await Internship.findByIdAndUpdate(
            req.params.id,
            req.body,
            { new: true, runValidators: true }
        );

        res.json(updatedInternship);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

/**
 * ============================================================
 * COMPANY: Delete Internship
 * ============================================================
 * @route   DELETE /api/internships/:id
 * @access  Private (Company)
 */
exports.deleteInternship = async (req, res) => {
    try {
        const internship = await Internship.findById(req.params.id);
        if (!internship) {
            return res.status(404).json({ message: 'Internship not found' });
        }

        const company = await Company.findOne({ user: req.user.id });
        if (!company) {
            return res.status(404).json({ message: 'Company profile not found' });
        }

        if (internship.company.toString() !== company._id.toString()) {
            return res.status(403).json({ message: 'Not authorized' });
        }

        await internship.deleteOne();
        res.json({ message: 'Internship deleted successfully' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};
