const express = require('express');
const router = express.Router();
const {
    getDashboardStats,
    getCompanies,
    updateCompanyStatus,
    getStudents,
    getInternships,
    getAllApplications,
    getAIConfig,
    updateAIConfig,
    toggleInternshipStatus,
    deleteUser,
    getAnalytics,
    verifyCompany
} = require('../controllers/adminController');
const { protect, authorize } = require('../middleware/authMiddleware');

// All routes are protected and restricted to admin
router.use(protect);
router.use(authorize('admin'));

// Dashboard & Analytics
router.get('/stats', getDashboardStats);
router.get('/analytics', getAnalytics);

// Company Management
router.get('/companies', getCompanies);
router.patch('/companies/:id/status', updateCompanyStatus);
router.post('/verify-company', verifyCompany);

// Student Management
router.get('/students', getStudents);

// Internship Monitoring
router.get('/internships', getInternships);
router.patch('/internships/:id/toggle', toggleInternshipStatus);

// Application Monitoring
router.get('/applications', getAllApplications);

// AI Configuration
router.get('/ai-config', getAIConfig);
router.put('/ai-config', updateAIConfig);

// User Management
router.delete('/users/:id', deleteUser);

module.exports = router;
