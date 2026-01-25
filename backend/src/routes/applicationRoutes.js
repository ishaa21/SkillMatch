const express = require('express');
const router = express.Router();

const {
    getApplicantsForInternship,
    updateApplicationStatus,
    applyToInternship,
    getMyApplications,
    withdrawApplication
} = require('../controllers/applicationController');

const { protect, authorize } = require('../middleware/authMiddleware');

// ================= COMPANY =================

// Get all applicants for a specific internship
router.get(
    '/internship/:internshipId',
    protect,
    authorize('company'),
    getApplicantsForInternship
);

// Update application status (Shortlisted / Rejected / Hired etc.)
router.put(
    '/:id/status',
    protect,
    authorize('company'),
    updateApplicationStatus
);

// ================= STUDENT =================

// Apply to an internship
router.post(
    '/',
    protect,
    authorize('student'),
    applyToInternship
);

// Get logged-in student's applications
router.get(
    '/my-applications',
    protect,
    authorize('student'),
    getMyApplications
);

// Withdraw application
router.post(
    '/:id/withdraw',
    protect,
    authorize('student'),
    withdrawApplication
);

module.exports = router;
