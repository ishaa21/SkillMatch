const mongoose = require('mongoose');

const applicationSchema = new mongoose.Schema({
    // References
    internship: { type: mongoose.Schema.Types.ObjectId, ref: 'Internship', required: true, index: true },
    student: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    company: { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true, index: true },

    // Application Status (Full Workflow as specified)
    status: {
        type: String,
        enum: ['Applied', 'Shortlisted', 'Interview', 'Hired', 'Rejected', 'Withdrawn', 'OnHold'],
        default: 'Applied',
        index: true
    },

    // AI Match Score (0-100) - CRITICAL FIELD
    matchScore: { type: Number, min: 0, max: 100, default: 0 }, // Jaccard similarity score
    aiMatchScore: Number, // Legacy support - same as matchScore

    // Detailed match breakdown
    matchBreakdown: {
        skillsMatch: Number, // 0-100
        experienceMatch: Number,
        educationMatch: Number,
        locationMatch: Number,
        availabilityMatch: Number,
        overallScore: Number
    },

    // Timeline Array for Status Transitions (Applied→Shortlisted→Interview→Hired→Rejected)
    timeline: [{
        status: {
            type: String,
            enum: ['Applied', 'Shortlisted', 'Interview', 'Hired', 'Rejected', 'Withdrawn', 'OnHold']
        },
        timestamp: { type: Date, default: Date.now },
        note: String, // Optional note for this transition
        actionBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' } // Who made this change
    }],

    // Application Timestamps
    appliedAt: { type: Date, default: Date.now, index: true },
    shortlistedAt: Date,
    interviewScheduledAt: Date,
    hiredAt: Date,
    rejectedAt: Date,
    withdrawnAt: Date,

    // Application Materials
    resumeUrl: String, // Submitted resume (may differ from profile resume)
    coverLetter: { type: String, maxlength: 2000 },
    portfolioLinks: [String],

    // Answers to Custom Questions (from internship.questionsForApplicants)
    questionsAnswers: [{
        question: String,
        questionId: String,
        answer: String, // or file URL for file uploads
        type: { type: String, enum: ['Text', 'MultipleChoice', 'File'] }
    }],

    // Company Notes & Feedback
    companyNotes: [{
        note: String,
        addedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        addedAt: { type: Date, default: Date.now },
        isPrivate: { type: Boolean, default: true } // Not visible to student
    }],

    // Interview Details
    interview: {
        scheduledDate: Date,
        scheduledTime: String,
        mode: { type: String, enum: ['Phone', 'Video', 'In-Person', 'Online-Test'] },
        location: String, // Physical address or meeting link
        interviewers: [String],
        duration: Number, // in minutes
        notes: String,
        feedback: String,
        score: Number,
        rounds: [{
            roundNumber: Number,
            roundName: String,
            scheduledAt: Date,
            completedAt: Date,
            result: { type: String, enum: ['Passed', 'Failed', 'Pending'] },
            feedback: String,
            score: Number
        }]
    },

    // Rejection Details
    rejection: {
        reason: String,
        feedback: String,
        canReapply: { type: Boolean, default: true },
        reapplyAfterDays: Number
    },

    // Offer Details (for Hired status)
    offer: {
        stipend: Number,
        currency: { type: String, default: 'INR' },
        startDate: Date,
        endDate: Date,
        duration: String,
        letterUrl: String, // Offer letter PDF
        offeredAt: Date,
        acceptedAt: Date,
        declinedAt: Date,
        status: { type: String, enum: ['Pending', 'Accepted', 'Declined', 'Expired'] }
    },

    // Student Actions
    isFavorite: { type: Boolean, default: false }, // Student marked as favorite
    studentNotes: String, // Student's private notes about this application

    // Communication History
    messages: [{
        from: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        to: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        message: String,
        sentAt: { type: Date, default: Date.now },
        isRead: { type: Boolean, default: false }
    }],

    // Notifications Sent
    notificationsSent: [{
        type: String, // E.g., 'Status Changed', 'Interview Scheduled'
        sentAt: Date,
        channel: { type: String, enum: ['Email', 'Push', 'SMS'] }
    }],

    // Metadata
    source: { type: String, default: 'Direct' }, // How student found the internship
    referralCode: String,
    applicationVersion: { type: Number, default: 1 }, // For tracking reapplications

    // Flags
    isViewed: { type: Boolean, default: false }, // Has company viewed this application
    viewedAt: Date,
    isStarred: { type: Boolean, default: false }, // Company marked as important
    isPriority: { type: Boolean, default: false }, // Fast-track application

    // Activity Tracking
    lastActivityAt: { type: Date, default: Date.now },
    lastViewedByCompany: Date,
    lastViewedByStudent: Date,

    // Additional Info
    expectedJoiningDate: Date,
    currentCTC: Number, // Current compensation (if applicable)
    expectedCTC: Number,
    noticePeriod: Number, // in days

    // Verification
    isResumeVerified: { type: Boolean, default: false },
    isDocumentVerified: { type: Boolean, default: false }

}, {
    timestamps: true
});

// Prevent duplicate applications
applicationSchema.index({ student: 1, internship: 1 }, { unique: true });

// Compound indexes for queries
applicationSchema.index({ company: 1, status: 1, matchScore: -1 });
applicationSchema.index({ student: 1, status: 1, appliedAt: -1 });
applicationSchema.index({ internship: 1, status: 1 });
applicationSchema.index({ status: 1, appliedAt: -1 });

// Auto-update timeline when status changes
applicationSchema.pre('save', function (next) {
    // If status has changed, add to timeline
    if (this.isModified('status')) {
        this.timeline.push({
            status: this.status,
            timestamp: new Date(),
            note: `Status changed to ${this.status}`
        });

        // Update specific timestamp fields
        const now = new Date();
        switch (this.status) {
            case 'Shortlisted':
                this.shortlistedAt = now;
                break;
            case 'Interview':
                this.interviewScheduledAt = now;
                break;
            case 'Hired':
                this.hiredAt = now;
                break;
            case 'Rejected':
                this.rejectedAt = now;
                break;
            case 'Withdrawn':
                this.withdrawnAt = now;
                break;
        }
    }

    this.lastActivityAt = new Date();
    next();
});

module.exports = mongoose.model('Application', applicationSchema);
