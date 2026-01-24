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

router.get('/internship/:internshipId', protect, authorize('company'), getApplicantsForInternship);
router.put('/:id/status', protect, authorize('company'), updateApplicationStatus);
router.post('/', protect, authorize('student'), applyToInternship);
router.get('/my-applications', protect, authorize('student'), getMyApplications);
router.post('/:id/withdraw', protect, authorize('student'), withdrawApplication);

module.exports = router;
