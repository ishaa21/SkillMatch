/**
 * Normalize internship data for Flutter app compatibility
 * Sends ONLY Flutter-safe primitive values
 */

const normalizeInternshipForFlutter = (internObj) => {
    return {
        // IDs
        id: internObj._id?.toString(),

        // Core Info
        title: internObj.title || '',
        description: internObj.description || '',
        location: internObj.location || '',
        workMode: internObj.workMode || 'Remote',
        duration: internObj.duration || '',

        // ✅ STIPEND (Structured Object)
        stipend: (() => {
            const defaults = { min: 0, max: 0, currency: 'INR', period: 'Month' };
            const s = internObj.stipend || {};

            return {
                min: Number(s.min) || Number(s.amount) || defaults.min,
                max: Number(s.max) || Number(s.amount) || defaults.max,
                currency: s.currency || defaults.currency,
                period: s.period || defaults.period
            };
        })(),

        // Skills (Flattened)
        skillsRequired: internObj.skillsRequired || internObj.requiredSkills || [],

        // Company (flattened for Flutter)
        companyId: internObj.company?._id?.toString() || null,
        companyName: internObj.company?.companyName || 'Company',
        companyLogo: internObj.company?.logo || null, // Ensure logo is passed if avail

        // AI Matching (Sanitized)
        matchPercentage: (() => {
            let score = Number(internObj.aiMatchScore) || 0;
            if (!Number.isFinite(score)) score = 0;
            return Math.max(0, Math.min(100, Math.round(score)));
        })(),

        // Status
        isActive: internObj.isActive ?? true,

        // Metadata
        createdAt: internObj.createdAt || null,
    };
};

module.exports = { normalizeInternshipForFlutter };
