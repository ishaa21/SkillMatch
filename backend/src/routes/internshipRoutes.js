const express = require('express');
const router = express.Router();

const {
    getRecommendedInternships,
    createInternship,
    getCompanyInternships,
    updateInternship,
    deleteInternship,
    getAllInternshipsPublic
} = require('../controllers/internshipController');

const { protect, authorize } = require('../middleware/authMiddleware');

// ================= PUBLIC =================
// For landing page / unauthenticated users
router.get('/public', getAllInternshipsPublic);

// ================= STUDENT =================
// AI-based recommended internships
router.get(
    '/recommendations',
    protect,
    authorize('student'),
    getRecommendedInternships
);

// ================= COMPANY =================
// View internships posted by logged-in company
router.get(
    '/my-internships',
    protect,
    authorize('company'),
    getCompanyInternships
);

// Create internship
router.post(
    '/',
    protect,
    authorize('company'),
    createInternship
);

// Update internship
router.put(
    '/:id',
    protect,
    authorize('company'),
    updateInternship
);

// Delete internship
router.delete(
    '/:id',
    protect,
    authorize('company'),
    deleteInternship
);

module.exports = router;
