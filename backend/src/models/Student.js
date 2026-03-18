const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true, index: true },
    fullName: { type: String, required: true },
    phone: { type: String },
    email: { type: String }, // Denormalized for quick access
    profilePicture: { type: String },

    // Profile Completion Tracking (0-100%)
    profileComplete: { type: Number, default: 0, min: 0, max: 100 },

    // Bio & Personal Info
    bio: { type: String, maxlength: 500 },
    dateOfBirth: { type: Date },
    gender: { type: String, enum: ['Male', 'Female', 'Other', 'Prefer not to say'] },

    // Education (25% of profile completion)
    education: [{
        institution: String,
        degree: String,
        fieldOfStudy: String,
        startYear: Number,
        endYear: Number,
        cgpa: Number,
        isCurrentlyStudying: { type: Boolean, default: false }
    }],
    university: { type: String }, // Primary university
    degree: { type: String }, // Primary degree
    graduationYear: { type: Number },

    // Skills (30% of profile completion)
    skills: [{
        name: { type: String, required: true },
        proficiency: { type: String, enum: ['Beginner', 'Intermediate', 'Advanced', 'Expert'], default: 'Intermediate' },
        yearsOfExperience: Number
    }],

    // Social & Portfolio Links
    linkedin: { type: String },
    github: { type: String },
    portfolio: { type: String },
    portfolioUrl: { type: String },
    twitter: { type: String },

    // Interests & Domains
    interests: [String],
    preferredDomains: [String],

    // Location with Coordinates for Proximity Search
    location: {
        city: String,
        state: String,
        country: { type: String },
        coordinates: {
            type: { type: String, enum: ['Point'] },
            coordinates: [Number] // [longitude, latitude]
        },
        address: String
    },

    // Internship Preferences
    internshipPreferences: {
        type: { type: String, enum: ['Remote', 'On-site', 'Hybrid', 'Any'], default: 'Any' },
        minStipend: { type: Number, default: 0 },
        maxStipend: Number,
        durationMonths: Number,
        locations: [String],
        isOpenToRelocate: { type: Boolean, default: false }
    },

    // Availability
    availability: {
        startDate: Date,
        hoursPerWeek: Number,
        status: { type: String, enum: ['Available', 'Not Available', 'Open to Offers'], default: 'Available' }
    },

    // Documents
    resumeUrl: String,
    resumeLastUpdated: Date,

    // Experience (15% of profile completion)
    experience: [{
        title: String,
        company: String,
        location: String,
        startDate: Date,
        endDate: Date,
        isCurrentlyWorking: { type: Boolean, default: false },
        duration: String,
        description: String,
        skills: [String]
    }],

    // Projects (10% of profile completion)
    projects: [{
        title: String,
        description: String,
        technologies: [String],
        link: String,
        startDate: Date,
        endDate: Date
    }],

    // Certifications (10% of profile completion)
    certifications: [{
        name: String,
        issuingOrganization: String,
        issueDate: Date,
        expiryDate: Date,
        credentialId: String,
        credentialUrl: String
    }],

    // Languages (5% of profile completion)
    languages: [{
        name: String,
        proficiency: { type: String, enum: ['Basic', 'Conversational', 'Fluent', 'Native'] }
    }],

    // Achievements & Awards (5% of profile completion)
    achievements: [{
        title: String,
        description: String,
        date: Date,
        issuer: String
    }],

    // Saved Internships & Applications
    savedInternships: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Internship' }],
    appliedInternships: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Application' }],

    // Verification Status
    isEmailVerified: { type: Boolean, default: false },
    isPhoneVerified: { type: Boolean, default: false },
    isProfileVerified: { type: Boolean, default: false }, // Admin verified
    verifiedBadge: { type: Boolean, default: false }, // Premium verification (e.g., education)

    // Activity Metadata
    lastActive: { type: Date, default: Date.now },
    profileViews: { type: Number, default: 0 },
    totalApplications: { type: Number, default: 0 },

    // Preferences
    notificationPreferences: {
        email: { type: Boolean, default: true },
        push: { type: Boolean, default: true },
        sms: { type: Boolean, default: false }
    }
}, {
    timestamps: true
});

// Geospatial Index for Location-Based Search
studentSchema.index({ 'location.coordinates': '2dsphere' });

// Text Index for Search
studentSchema.index({ fullName: 'text', bio: 'text', 'skills.name': 'text' });

// Compound Indexes for Common Queries
studentSchema.index({ profileComplete: -1, createdAt: -1 });
studentSchema.index({ 'availability.status': 1, profileComplete: -1 });

// Calculate Profile Completion Percentage
studentSchema.methods.calculateProfileCompletion = function () {
    let completion = 0;

    // Basic Info (10%)
    if (this.fullName) completion += 2;
    if (this.phone) completion += 2;
    if (this.email) completion += 2;
    if (this.bio && this.bio.length >= 50) completion += 2;
    if (this.profilePicture) completion += 2;

    // Education (25%)
    if (this.education && this.education.length > 0) {
        completion += 15;
        if (this.education[0].cgpa) completion += 5;
        if (this.education.length > 1) completion += 5;
    }
    if (this.university) completion += 0; // Already counted in education
    if (this.degree) completion += 0; // Already counted in education

    // Skills (30%)
    if (this.skills && this.skills.length > 0) {
        completion += 10;
        if (this.skills.length >= 3) completion += 10;
        if (this.skills.length >= 5) completion += 10;
    }

    // Experience (15%)
    if (this.experience && this.experience.length > 0) {
        completion += 10;
        if (this.experience.length >= 2) completion += 5;
    }

    // Projects (10%)
    if (this.projects && this.projects.length > 0) {
        completion += 5;
        if (this.projects.length >= 2) completion += 5;
    }

    // Certifications (10%)
    if (this.certifications && this.certifications.length > 0) {
        completion += 5;
        if (this.certifications.length >= 2) completion += 5;
    }

    // Resume is critical
    if (this.resumeUrl) completion += 10;

    // Location
    if (this.location && this.location.city) completion += 3;

    // Social Links
    if (this.linkedin) completion += 2;
    if (this.github || this.portfolio) completion += 2;

    // Languages
    if (this.languages && this.languages.length > 0) completion += 5;

    // Achievements
    if (this.achievements && this.achievements.length > 0) completion += 5;

    return Math.min(completion, 100);
};

// Auto-update profile completion before save
studentSchema.pre('save', function (next) {
    this.profileComplete = this.calculateProfileCompletion();
    next();
});

module.exports = mongoose.model('Student', studentSchema);
