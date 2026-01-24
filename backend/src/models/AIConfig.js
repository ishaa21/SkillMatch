const mongoose = require('mongoose');

const aiConfigSchema = new mongoose.Schema({
    weights: {
        skills: { type: Number, default: 0.40, min: 0, max: 1 },
        domains: { type: Number, default: 0.20, min: 0, max: 1 },
        preferences: { type: Number, default: 0.15, min: 0, max: 1 },
        location: { type: Number, default: 0.10, min: 0, max: 1 },
        experience: { type: Number, default: 0.15, min: 0, max: 1 }
    },
    // Feature toggles for AI matching
    features: {
        skillProficiencyMatching: { type: Boolean, default: true },
        domainKeywordMatching: { type: Boolean, default: true },
        locationFlexibility: { type: Boolean, default: true }
    },
    // Thresholds
    thresholds: {
        minimumMatchScore: { type: Number, default: 30 }, // Minimum score to show in recommendations
        highlightScore: { type: Number, default: 70 }     // Score above which to highlight
    },
    updatedAt: { type: Date, default: Date.now },
    updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
});

module.exports = mongoose.model('AIConfig', aiConfigSchema);
