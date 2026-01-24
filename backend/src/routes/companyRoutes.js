const express = require('express');
const router = express.Router();
const { getProfile, updateProfile, getDashboardStats } = require('../controllers/companyController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.get('/stats', protect, authorize('company'), getDashboardStats);
router.get('/profile', protect, authorize('company'), getProfile);
router.put('/profile', protect, authorize('company'), updateProfile);

module.exports = router;
