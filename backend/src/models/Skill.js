const mongoose = require('mongoose');

const skillSchema = new mongoose.Schema({
    // Skill Information
    name: { type: String, required: true, unique: true, trim: true, index: true },
    normalizedName: { type: String, lowercase: true, trim: true, index: true }, // For case-insensitive search

    // Categorization
    category: {
        type: String,
        enum: [
            'Programming Languages',
            'Web Development',
            'Mobile Development',
            'Data Science & AI',
            'Database',
            'DevOps & Cloud',
            'Design',
            'Marketing',
            'Business & Management',
            'Finance & Accounting',
            'Content & Writing',
            'Sales',
            'Legal',
            'HR',
            'Other'
        ],
        required: true,
        index: true
    },

    subCategory: String, // More specific categorization

    // Synonyms & Aliases
    synonyms: [String], // E.g., "JS" for "JavaScript"
    aliases: [String],

    // Description
    description: String,

    // Related Skills
    relatedSkills: [String], // E.g., React relates to JavaScript
    prerequisites: [String], // Skills that are typically learned before this one

    // Metadata
    iconUrl: String, // Icon/logo for the skill
    color: String, // Brand color (e.g., for JavaScript: #F7DF1E)

    // Popularity & Demand
    usageCount: { type: Number, default: 0 }, // How many times this skill is used
    demandScore: { type: Number, default: 0, min: 0, max: 100 }, // Industry demand
    trendingScore: { type: Number, default: 0 }, // Based on recent usage growth

    // Validation
    isVerified: { type: Boolean, default: false }, // Admin verified
    isActive: { type: Boolean, default: true }, // Can be used in platform

    // Industry & Domain
    industries: [String], // Which industries use this skill
    domains: [String], // Technical domains

    // Learning Resources (optional enhancement)
    resources: [{
        title: String,
        url: String,
        type: { type: String, enum: ['Course', 'Tutorial', 'Documentation', 'Video'] }
    }],

    // Proficiency Levels & Descriptions
    proficiencyLevels: [{
        level: { type: String, enum: ['Beginner', 'Intermediate', 'Advanced', 'Expert'] },
        description: String,
        typicalYears: Number
    }],

    // Statistics
    statistics: {
        totalStudents: { type: Number, default: 0 }, // Students with this skill
        totalInternships: { type: Number, default: 0 }, // Internships requiring this skill
        averageSalary: Number, // Average stipend/salary for this skill
        highestSalary: Number
    }

}, {
    timestamps: true
});

// Indexes
skillSchema.index({ name: 'text', description: 'text', synonyms: 'text' });
skillSchema.index({ category: 1, usageCount: -1 });
skillSchema.index({ demandScore: -1, trendingScore: -1 });

// Pre-save hook to normalize name
skillSchema.pre('save', function (next) {
    this.normalizedName = this.name.toLowerCase().trim();
    next();
});

// Static method to find or create skill
skillSchema.statics.findOrCreate = async function (skillName) {
    const normalizedName = skillName.toLowerCase().trim();
    let skill = await this.findOne({ normalizedName });

    if (!skill) {
        skill = await this.create({
            name: skillName,
            normalizedName,
            category: 'Other',
            isVerified: false
        });
    }

    return skill;
};

// Static method to increment usage count
skillSchema.statics.incrementUsage = async function (skillName) {
    const normalizedName = skillName.toLowerCase().trim();
    await this.updateOne(
        { normalizedName },
        { $inc: { usageCount: 1 } },
        { upsert: true }
    );
};

module.exports = mongoose.model('Skill', skillSchema);
