const express = require('express');
const router = express.Router();
const {
    register,
    login,
    sendOtp,
    verifyOtp,
    googleLogin,
    refreshToken,
    getMe,
    getAllInternships,
    getAllInternshipsPublic,
    getCompanyInternships,
    getInternshipApplications,
    updateApplicationStatus,
    getAllCompanies,
    getAllStudents,
    getAllApplications,
    deleteCompany,
    deleteStudent,
    verifyCompany
} = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

// Auth routes
router.post('/register', register);
router.post('/login', login);
// router.post('/otp/send', sendOtp);
// router.post('/otp/verify', verifyOtp);
// router.post('/google', googleLogin);
// router.post('/refresh', refreshToken);
router.get('/me', protect, getMe);

// PUBLIC route for demo (no auth required)
router.get('/public/internships', getAllInternshipsPublic);

// Internship routes
router.get('/internships', protect, getAllInternships);
router.get('/company/internships', protect, getCompanyInternships);
router.get('/internships/:internshipId/applications', protect, getInternshipApplications);
router.put('/applications/:applicationId/status', protect, updateApplicationStatus);

// Admin Controller
const {
    getDashboardStats,
    getAIConfig,
    updateAIConfig
} = require('../controllers/adminController');

// Admin routes
router.get('/admin/stats', protect, getDashboardStats);
router.get('/admin/ai-config', protect, getAIConfig);
router.put('/admin/ai-config', protect, updateAIConfig);

router.get('/admin/companies', protect, getAllCompanies);
router.put('/admin/companies/:companyId/verify', protect, verifyCompany);
router.get('/admin/students', protect, getAllStudents);
router.get('/admin/applications', protect, getAllApplications);
router.delete('/admin/companies/:companyId', protect, deleteCompany);
router.delete('/admin/students/:studentId', protect, deleteStudent);

module.exports = router;
