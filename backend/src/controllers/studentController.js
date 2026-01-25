const Student = require('../models/Student');
const User = require('../models/User');

// @desc    Get current student profile
// @route   GET /api/student/profile
// @access  Private (Student only)
exports.getProfile = async (req, res) => {
    try {
        const student = await Student.findOne({ user: req.user.id });

        if (!student) {
            // Instead of 404, we can return a default empty profile structure
            // to help the frontend avoid null checks.
            return res.status(200).json({
                user: req.user.id,
                fullName: req.user.email?.split('@')[0] || 'Student',
                profileComplete: 0,
                skills: [],
                interests: [],
                education: [],
                experience: []
            });
        }
        res.json(student);
    } catch (error) {
        console.error('getProfile Error:', error);
        res.status(500).json({ message: 'Server error retrieving profile' });
    }
};

// @desc    Update student profile
// @route   PUT /api/student/profile
// @access  Private (Student only)
exports.updateProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        // console.log('Update payload:', JSON.stringify(req.body, null, 2)); // Debug log

        // 1. Find existing profile or create new instance
        let student = await Student.findOne({ user: userId });

        if (!student) {
            student = new Student({ user: userId });
        }

        // 2. Extract allowed fields from body
        const {
            fullName,
            phone,
            university,
            degree,
            graduationYear,
            bio,
            gender,
            dateOfBirth,
            skills,
            interests,
            education,
            experience,
            projects,
            certifications,
            languages,
            internshipPreferences,
            location,
            linkedin,
            github,
            portfolio,
            portfolioUrl
        } = req.body;

        // 3. Update fields if they are provided (undefined check)
        // We permit null/empty string to clear fields
        if (fullName !== undefined) student.fullName = fullName;
        if (phone !== undefined) student.phone = phone;
        if (university !== undefined) student.university = university;
        if (degree !== undefined) student.degree = degree;
        if (graduationYear !== undefined) student.graduationYear = graduationYear;
        if (bio !== undefined) student.bio = bio;
        if (gender !== undefined) student.gender = gender;
        if (dateOfBirth !== undefined) student.dateOfBirth = dateOfBirth;
        if (linkedin !== undefined) student.linkedin = linkedin;
        if (github !== undefined) student.github = github;
        if (portfolio !== undefined) student.portfolio = portfolio;
        if (portfolioUrl !== undefined) student.portfolioUrl = portfolioUrl;

        // 4. Handle Complex Objects & Arrays (Overwrite strategy)
        // Frontend should send the complete array. Only update if provided.
        if (skills !== undefined) student.skills = skills;
        if (interests !== undefined) student.interests = interests;
        if (education !== undefined) student.education = education;
        if (experience !== undefined) student.experience = experience;
        if (projects !== undefined) student.projects = projects;
        if (certifications !== undefined) student.certifications = certifications;
        if (languages !== undefined) student.languages = languages;

        // Handle Nested Objects carefully (Merge or Overwrite?)
        // For simplicity and safety, we overwrite the whole object if provided,
        // unless specific sub-fields are critical. Here we overwrite.
        if (internshipPreferences !== undefined) {
            student.internshipPreferences = {
                ...student.internshipPreferences, // preserve defaults/existing
                ...internshipPreferences
            };
        }

        if (location !== undefined) {
            student.location = {
                ...student.location,
                ...location
            };
        }

        // 5. Save (Triggers pre-save hook for profileComplete calculation)
        await student.save();

        res.json(student);
    } catch (error) {
        console.error('Update Profile Error:', error);

        // Handle Mongoose Validation Errors nicely
        if (error.name === 'ValidationError') {
            const messages = Object.values(error.errors).map(val => val.message);
            return res.status(400).json({ message: messages.join(', ') });
        }

        // Handle Cast Errors (e.g. string provided for number field)
        if (error.name === 'CastError') {
            return res.status(400).json({ message: `Invalid value for field: ${error.path}` });
        }

        res.status(500).json({
            message: 'Server error updating profile',
            error: process.env.NODE_ENV === 'development' ? error.stack : undefined
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

        // Construct URL needs to be robust. 
        // Ideally use valid static path or cloud storage URL.
        const resumeUrl = `/uploads/resumes/${req.file.filename}`;

        let student = await Student.findOne({ user: req.user.id });
        if (!student) {
            student = new Student({ user: req.user.id, fullName: 'New Student' });
        }

        student.resumeUrl = resumeUrl;
        student.resumeLastUpdated = new Date();
        await student.save();

        res.json({
            message: 'Resume uploaded successfully',
            resumeUrl,
            student
        });
    } catch (error) {
        console.error('Resume Upload Error:', error);
        res.status(500).json({ message: 'Server error uploading resume' });
    }
};

// @desc    Toggle saved internship
// @route   POST /api/student/saved-internships/:id
// @access  Private (Student only)
exports.toggleSavedInternship = async (req, res) => {
    try {
        const internshipId = req.params.id;
        let student = await Student.findOne({ user: req.user.id });

        if (!student) {
            return res.status(404).json({ message: 'Create profile first' });
        }

        // Check if exists
        const index = student.savedInternships.indexOf(internshipId);
        let action = '';

        if (index === -1) {
            student.savedInternships.push(internshipId);
            action = 'saved';
        } else {
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

        if (!student) {
            return res.json([]); // Return empty list instead of 404
        }

        res.json(student.savedInternships);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};
