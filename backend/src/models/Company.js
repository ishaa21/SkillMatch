const mongoose = require('mongoose');

const companySchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true, index: true },
    companyName: { type: String, required: true, index: true },
    description: { type: String, maxlength: 1000 },
    tagline: { type: String, maxlength: 200 },

    // Contact Information
    website: { type: String },
    email: { type: String }, // Company official email
    phone: { type: String },
    supportEmail: { type: String },
    supportPhone: { type: String },

    // Company Details
    industry: { type: String },
    companyType: { type: String, enum: ['Startup', 'SME', 'MNC', 'Government', 'Non-Profit', 'Other'] },
    companySize: { type: String, enum: ['1-10', '11-50', '51-200', '201-500', '501-1000', '1000+'] },
    foundedYear: { type: Number },

    // Location with Coordinates
    location: {
        city: String,
        state: String,
        country: { type: String, default: 'India' },
        coordinates: {
            type: { type: String, enum: ['Point'], default: 'Point' },
            coordinates: [Number] // [longitude, latitude]
        },
        address: String,
        pincode: String
    },

    // Multiple Office Locations
    officeLocations: [{
        name: String, // E.g., "Bangalore Office"
        city: String,
        state: String,
        country: String,
        address: String,
        isPrimary: { type: Boolean, default: false }
    }],

    // Branding
    logoUrl: { type: String },
    coverImageUrl: { type: String },

    // Legal Documents (MCA/GST Verification)
    documents: {
        mcaCertificate: {
            url: String,
            uploadedAt: Date,
            status: { type: String, enum: ['Pending', 'Verified', 'Rejected'], default: 'Pending' },
            rejectionReason: String
        },
        gstCertificate: {
            url: String,
            uploadedAt: Date,
            status: { type: String, enum: ['Pending', 'Verified', 'Rejected'], default: 'Pending' },
            rejectionReason: String
        },
        incorporationCertificate: {
            url: String,
            uploadedAt: Date,
            status: { type: String, enum: ['Pending', 'Verified', 'Rejected'], default: 'Pending' },
            rejectionReason: String
        },
        otherDocuments: [{
            name: String,
            url: String,
            uploadedAt: Date
        }]
    },

    // Company Identification Numbers
    cin: { type: String, unique: true, sparse: true, trim: true, index: true }, // Corporate Identification Number
    gstin: { type: String, unique: true, sparse: true, trim: true }, // GST Identification Number
    pan: { type: String, trim: true }, // PAN Number
    tan: { type: String, trim: true }, // TAN Number

    // MCA Verification Data (from external API or admin verification)
    mcaData: {
        legalName: String,
        incorporationDate: Date,
        status: String, // e.g., 'Active', 'Struck Off', 'Dissolved'
        paidUpCapital: String,
        authorizedCapital: String,
        registrationNumber: String,
        companyCategory: String,
        companySubCategory: String,
        classOfCompany: String,
        dateOfLastAGM: Date,
        registeredAddress: String,
        directors: [{
            name: String,
            din: String,
            designation: String
        }]
    },

    // Admin Status Management
    isApproved: { type: Boolean, default: false, index: true },
    isSuspended: { type: Boolean, default: false, index: true },
    isPendingReview: { type: Boolean, default: true },

    // Audit Timestamps
    approvedAt: { type: Date },
    approvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // Admin who approved
    rejectedAt: { type: Date },
    rejectedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    suspendedAt: { type: Date },
    suspendedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    reactivatedAt: { type: Date },
    reactivatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

    // Rejection/Suspension reasons
    rejectionReason: { type: String },
    suspensionReason: { type: String },

    // Verification Status
    verificationStatus: {
        type: String,
        enum: ['Unverified', 'Pending', 'Verified', 'Failed', 'Expired'],
        default: 'Unverified',
        index: true
    },
    verifiedAt: { type: Date },
    verificationExpiresAt: { type: Date }, // Verification may need renewal

    // AuthBridge or External Verification
    externalVerification: {
        provider: String, // e.g., 'AuthBridge'
        referenceId: String,
        status: { type: String, enum: ['Pending', 'Success', 'Failed'] },
        verifiedAt: Date,
        response: mongoose.Schema.Types.Mixed
    },

    // Social Media & Links
    socialLinks: {
        linkedin: String,
        twitter: String,
        facebook: String,
        instagram: String,
        youtube: String
    },

    // Company Benefits & Perks (for attraction)
    benefits: [String], // E.g., ["Health Insurance", "Flexible Hours", "Remote Work"]

    // Company Culture & Values
    culture: {
        values: [String],
        workEnvironment: String,
        diversityCommitment: String
    },

    // Statistics & Analytics
    analytics: {
        totalInternshipsPosted: { type: Number, default: 0 },
        activeInternships: { type: Number, default: 0 },
        totalApplicationsReceived: { type: Number, default: 0 },
        totalHires: { type: Number, default: 0 },
        profileViews: { type: Number, default: 0 },
        averageResponseTime: Number, // in hours
        responseRate: Number // percentage
    },

    // Ratings & Reviews (future enhancement)
    ratings: {
        overall: { type: Number, default: 0, min: 0, max: 5 },
        totalReviews: { type: Number, default: 0 },
        workCulture: { type: Number, default: 0 },
        compensation: { type: Number, default: 0 },
        learning: { type: Number, default: 0 }
    },

    // Activity Metadata
    lastActive: { type: Date, default: Date.now },
    lastInternshipPosted: { type: Date },

    // Subscription & Features (for premium features)
    subscription: {
        plan: { type: String, enum: ['Free', 'Basic', 'Premium', 'Enterprise'], default: 'Free' },
        startDate: Date,
        endDate: Date,
        features: [String]
    },

    // Notes from Admin (internal use)
    adminNotes: [{
        note: String,
        addedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        addedAt: { type: Date, default: Date.now }
    }],

    // Notification Preferences
    notificationPreferences: {
        email: { type: Boolean, default: true },
        applicationAlerts: { type: Boolean, default: true },
        weeklyDigest: { type: Boolean, default: true }
    }
}, {
    timestamps: true
});

// Geospatial Index for Location-Based Search
companySchema.index({ 'location.coordinates': '2dsphere' });

// Text Index for Search
companySchema.index({ companyName: 'text', description: 'text', industry: 'text' });

// Index for efficient admin queries
companySchema.index({ isApproved: 1, isSuspended: 1, isPendingReview: 1 });
companySchema.index({ verificationStatus: 1, createdAt: -1 });

// Compound indexes for analytics
companySchema.index({ 'analytics.totalHires': -1, 'ratings.overall': -1 });

module.exports = mongoose.model('Company', companySchema);
