const express = require('express');
const router = express.Router();
const {
    getExternalInternships,
    clearExternalCache
} = require('../controllers/externalController');
const { protect, authorize } = require('../middleware/authMiddleware');

// Public route - no auth required for fetching external listings
router.get('/internships', getExternalInternships);

// Admin-only route to clear cache
router.post('/internships/clear-cache', protect, authorize('admin'), clearExternalCache);

module.exports = router;
