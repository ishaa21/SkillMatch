const mongoose = require('mongoose');

const internshipSchema = new mongoose.Schema({
    company: { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true, index: true },

    // Basic Information
    title: { type: String, required: true, index: true },
    description: { type: String, required: true, maxlength: 2000 },
    shortDescription: { type: String, maxlength: 200 }, // For cards/previews

    // Role & Type
    roleType: { type: String, enum: ['Full-time', 'Part-time', 'Internship'], default: 'Internship' },
    workMode: { type: String, enum: ['Remote', 'On-site', 'Hybrid'], required: true, index: true },

    // Skills Requirements
    requiredSkills: [{ // Note: Changed from skillsRequired to match spec
        name: { type: String, required: true },
        level: { type: String, enum: ['Beginner', 'Intermediate', 'Advanced', 'Expert'], default: 'Intermediate' },
        isMandatory: { type: Boolean, default: true }
    }],

    // Optional/Nice-to-have Skills
    optionalSkills: [{
        name: String,
        level: { type: String, enum: ['Beginner', 'Intermediate', 'Advanced', 'Expert'] }
    }],

    // Domains & Categories
    domains: [String], // e.g. ["Web Development", "AI", "Marketing"]
    category: { type: String }, // Primary category
    tags: [String], // Additional searchable tags

    // Stipend (INR Currency as specified)
    stipend: {
        min: { type: Number, required: true, default: 0 },
        max: { type: Number, default: 0 },
        currency: { type: String, default: 'INR' },
        period: { type: String, enum: ['Month', 'Week', 'Year', 'One-time', 'Unpaid'], default: 'Month' },
        isNegotiable: { type: Boolean, default: false },
        additionalBenefits: [String]
    },

    // AI Matching Score (Stored transiently or persistently)
    aiMatchScore: { type: Number, default: 0 },

    // Duration & Timeline
    duration: {
        value: Number, // e.g., 3
        unit: { type: String, enum: ['Weeks', 'Months'], default: 'Months' },
        displayString: String // e.g., "3 Months" (computed or manual)
    },
    startDate: Date, // Expected start date
    endDate: Date, // Expected end date
    isFlexibleStart: { type: Boolean, default: false },

    // Application Deadline - CRITICAL FIELD
    deadline: { type: Date, required: true, index: true },

    // Location Details
    location: {
        city: String,
        state: String,
        country: { type: String, default: 'India' },
        coordinates: {
            type: { type: String, enum: ['Point'], default: 'Point' },
            coordinates: [Number] // [longitude, latitude]
        },
        address: String,
        isRemote: { type: Boolean, default: false } // Redundant with workMode but useful
    },

    // Multiple locations (for companies with multiple offices)
    multipleLocations: [{
        city: String,
        state: String,
        country: String,
        coordinates: {
            type: { type: String, enum: ['Point'] },
            coordinates: [Number]
        }
    }],

    // Requirements & Qualifications
    requirements: {
        education: {
            degree: String, // E.g., "Bachelor's"
            field: [String], // E.g., ["Computer Science", "IT"]
            yearOfStudy: String, // E.g., "2nd Year or above"
        },
        experience: {
            min: Number, // Minimum years/months
            max: Number,
            isRequired: { type: Boolean, default: false }
        },
        ageLimit: {
            min: Number,
            max: Number
        },
        otherRequirements: [String] // Additional requirements
    },

    // Job Responsibilities
    responsibilities: [String],

    // Learning Outcomes
    learningOutcomes: [String],

    // Selection Process
    selectionProcess: {
        steps: [String], // E.g., ["Application Review", "Technical Test", "Interview"]
        totalRounds: Number,
        estimatedTimeline: String // E.g., "2-3 weeks"
    },

    // Perks & Benefits
    perks: [String], // E.g., ["Certificate", "Letter of Recommendation", "PPO Opportunity"]

    // Openings & Capacity
    openings: { type: Number, default: 1 }, // Number of positions available
    maxApplications: Number, // Maximum applications accepted (optional)

    // Status & Moderation
    isActive: { type: Boolean, default: true, index: true },
    status: {
        type: String,
        enum: ['Draft', 'Active', 'Paused', 'Closed', 'Expired', 'Rejected'],
        default: 'Active',
        index: true
    },

    // Admin Moderation
    isApproved: { type: Boolean, default: true }, // Auto-approve or require moderation
    moderatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    moderatedAt: Date,
    rejectionReason: String,

    // Timestamps
    postedAt: { type: Date, default: Date.now, index: true },
    lastModified: { type: Date, default: Date.now },
    closedAt: Date,

    // Applications & Tracking
    applicants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Student' }], // Simple list
    applications: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Application' }], // Full applications
    totalApplications: { type: Number, default: 0 },
    shortlistedCount: { type: Number, default: 0 },
    selectedCount: { type: Number, default: 0 },

    // Analytics
    analytics: {
        views: { type: Number, default: 0 },
        uniqueViews: { type: Number, default: 0 },
        saves: { type: Number, default: 0 },
        shares: { type: Number, default: 0 },
        clickThroughRate: Number,
        conversionRate: Number, // Applications / Views
        averageMatchScore: Number // Average AI match score of applicants
    },

    // Featured & Priority
    isFeatured: { type: Boolean, default: false },
    priority: { type: Number, default: 0 }, // Higher = more prominent

    // Additional Info
    questionsForApplicants: [{
        question: String,
        type: { type: String, enum: ['Text', 'MultipleChoice', 'File'], default: 'Text' },
        options: [String], // For MultipleChoice
        isRequired: { type: Boolean, default: false }
    }],

    // Contact Person (if different from company admin)
    contactPerson: {
        name: String,
        email: String,
        phone: String,
        designation: String
    }
}, {
    timestamps: true
});

// Geospatial Index for Location-Based Search
internshipSchema.index({ 'location.coordinates': '2dsphere' });
internshipSchema.index({ 'multipleLocations.coordinates': '2dsphere' });

// Text Index for Search
internshipSchema.index({
    title: 'text',
    description: 'text',
    'requiredSkills.name': 'text',
    'domains': 'text',
    'tags': 'text'
});

// Compound Indexes for Common Queries
internshipSchema.index({ isActive: 1, status: 1, deadline: 1 });
internshipSchema.index({ isActive: 1, postedAt: -1 });
internshipSchema.index({ company: 1, isActive: 1 });
internshipSchema.index({ workMode: 1, isActive: 1 });
internshipSchema.index({ 'stipend.min': 1, 'stipend.max': 1 });

// Auto-update lastModified on save
internshipSchema.pre('save', function (next) {
    this.lastModified = new Date();

    // Auto-display string for duration
    if (this.duration && this.duration.value && this.duration.unit) {
        this.duration.displayString = `${this.duration.value} ${this.duration.unit}`;
    }

    // Auto-expire if past deadline
    if (this.deadline && new Date() > this.deadline && this.status === 'Active') {
        this.status = 'Expired';
        this.isActive = false;
    }

    next();
});

module.exports = mongoose.model('Internship', internshipSchema);
