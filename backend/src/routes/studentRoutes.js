const express = require('express');
const router = express.Router();
const {
    getProfile,
    updateProfile,
    uploadResume,
    toggleSavedInternship,
    getSavedInternships
} = require('../controllers/studentController');
const { protect, authorize } = require('../middleware/authMiddleware');
const upload = require('../utils/fileUpload');

router.get('/profile', protect, authorize('student'), getProfile);
router.put('/profile', protect, authorize('student'), updateProfile);
router.get('/saved-internships', protect, authorize('student'), getSavedInternships);
router.post('/saved-internships/:id', protect, authorize('student'), toggleSavedInternship);

// Resume upload route
// 'resume' is the key name in form-data
router.post('/resume', protect, authorize('student'), upload.single('resume'), uploadResume);

module.exports = router;
