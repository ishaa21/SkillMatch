const Student = require('../models/Student');
const User = require('../models/User');

// @desc    Get current student profile
// @route   GET /api/student/profile
// @access  Private (Student only)
exports.getProfile = async (req, res) => {
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

// @desc    Update student profile
// @route   PUT /api/student/profile
// @access  Private (Student only)
exports.updateProfile = async (req, res) => {
    try {
        console.log('--- UPDATE SNAPSHOT START ---');
        console.log('User ID:', req.user.id);

        // 1. Sanitize Payload explicitly
        const {
            fullName, phone, university, degree, graduationYear,
            skills, interests, internshipPreferences
        } = req.body;

        // 2. Calculate Score
        let completion = 0;
        if (fullName) completion += 10;
        if (phone) completion += 5;
        if (university) completion += 25;
        if (skills && skills.length > 0) completion += 30;

        // 3. Construct Update Object Safe for Mongoose
        const updateData = {};
        if (fullName) updateData.fullName = fullName;
        if (phone) updateData.phone = phone;
        if (university) updateData.university = university;
        if (degree) updateData.degree = degree;
        if (graduationYear) updateData.graduationYear = graduationYear;
        if (skills) updateData.skills = skills;
        if (interests) updateData.interests = interests;
        if (internshipPreferences) updateData.internshipPreferences = internshipPreferences;

        updateData.profileComplete = completion > 100 ? 100 : completion;

        console.log('Computed Update Data:', JSON.stringify(updateData, null, 2));

        // 4. Perform Update (runValidators: false to prevent crashes on partial/legacy data)
        const student = await Student.findOneAndUpdate(
            { user: req.user.id },
            { $set: updateData },
            { new: true, upsert: true, runValidators: false }
        );

        console.log('Update Success. Doc ID:', student._id);
        console.log('--- UPDATE SNAPSHOT END ---');

        res.json(student);
    } catch (error) {
        console.error('CRITICAL UPDATE ERROR:', error);
        res.status(500).json({
            message: 'Server error during profile update',
            error: error.message
        });
    }
};

// @desc    Upload resume
// @route   POST /api/student/resume
// @access  Private (Student only)
exports.uploadResume = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'Please upload a file' });
        }

        // Construct URL (in production this would be S3 URL)
        // For local: /uploads/resumes/filename
        const resumeUrl = `/uploads/resumes/${req.file.filename}`;

        const student = await Student.findOneAndUpdate(
            { user: req.user.id },
            { resumeUrl: resumeUrl },
            { new: true }
        );

        if (!student) {
            // Clean up file if student not found?
            return res.status(404).json({ message: 'Student profile not found' });
        }

        res.json({ message: 'Resume uploaded successfully', resumeUrl, student });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Toggle saved internship
// @route   POST /api/student/saved-internships/:id
// @access  Private (Student only)
exports.toggleSavedInternship = async (req, res) => {
    try {
        const internshipId = req.params.id;
        const student = await Student.findOne({ user: req.user.id });
        if (!student) return res.status(404).json({ message: 'Student profile not found' });

        // Check if exists
        const index = student.savedInternships.indexOf(internshipId);
        let action = '';

        if (index === -1) {
            // Add
            student.savedInternships.push(internshipId);
            action = 'saved';
        } else {
            // Remove
            student.savedInternships.splice(index, 1);
            action = 'removed';
        }

        await student.save();
        res.json({ message: `Internship ${action}`, savedInternships: student.savedInternships });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Get saved internships
// @route   GET /api/student/saved-internships
// @access  Private (Student only)
exports.getSavedInternships = async (req, res) => {
    try {
        const student = await Student.findOne({ user: req.user.id }).populate({
            path: 'savedInternships',
            populate: { path: 'company' }
        });

        if (!student) return res.status(404).json({ message: 'Student profile not found' });

        res.json(student.savedInternships);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};
