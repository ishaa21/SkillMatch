const express = require('express');
const router = express.Router();
const {
    getRecommendedInternships,
    createInternship,
    getCompanyInternships,
    updateInternship,
    deleteInternship
} = require('../controllers/internshipController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.get('/recommendations', protect, authorize('student'), getRecommendedInternships);
router.get('/my-internships', protect, authorize('company'), getCompanyInternships);
router.post('/', protect, authorize('company'), createInternship);
router.put('/:id', protect, authorize('company'), updateInternship);
router.delete('/:id', protect, authorize('company'), deleteInternship);

module.exports = router;
