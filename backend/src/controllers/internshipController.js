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

// ── Python AI Microservice Client ──
const {
    getAIRecommendations,
} = require('../utils/aiServiceClient');

/**
 * ============================================================
 * PUBLIC: Get All Active Internships
 * ============================================================
 * @route   GET /api/internships/public
 * @access  Public
 */
exports.getAllInternshipsPublic = async (req, res) => {
    try {
        const internships = await Internship.find({ isActive: true })
            .populate('company', 'companyName location logoUrl industry'); // Optimized populate

        const normalizedInternships = internships.map(normalizeInternshipForFlutter);
        res.json(normalizedInternships);
    } catch (error) {
        console.error('Get All Internships Error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

/**
 * ============================================================
 * STUDENT: Get AI-Recommended Internships
 * ============================================================
 * Uses Python AI microservice (SentenceTransformer) as PRIMARY ranker.
 * Falls back to Jaccard-based matcher if the Python service is unavailable.
 * 
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
            query.$or = [
                { 'location.city': { $regex: location, $options: 'i' } },
                { 'location.country': { $regex: location, $options: 'i' } },
                { location: { $regex: location, $options: 'i' } }
            ];
        }

        if (workMode && workMode !== 'Any') {
            query.workMode = workMode;
        }

        if (duration) {
            if (!isNaN(duration)) {
                query['duration.value'] = Number(duration);
            } else {
                query['duration.displayString'] = { $regex: duration, $options: 'i' };
            }
        }

        // 3️⃣ Fetch internships
        const internships = await Internship.find(query).populate('company');

        // 4️⃣ Try Python AI Service first, fallback to Jaccard
        const jaccardFallback = (studentProfile, internshipList) => {
            const aiConfig = null; // Already loaded above if needed
            return rankInternshipsForStudent(studentProfile, internshipList, DEFAULT_WEIGHTS);
        };

        let rankedInternships = await getAIRecommendations(
            student,
            internships,
            jaccardFallback
        );

        // 5️⃣ FALLBACK: If ranking returns empty, return active internships
        if (rankedInternships.length === 0) {
            const allActive = await Internship.find({ isActive: true }).sort({ createdAt: -1 }).limit(20).populate('company');
            rankedInternships = allActive.map(i => ({
                ...i.toObject(),
                matchPercentage: 70,
                matchScore: 70
            }));
        }

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
