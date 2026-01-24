const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    // Recipient
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    userRole: { type: String, enum: ['student', 'company', 'admin'], required: true },

    // Notification Details
    title: { type: String, required: true },
    message: { type: String, required: true },
    type: {
        type: String,
        enum: [
            'Application Status',
            'New Application',
            'Interview Scheduled',
            'Offer Received',
            'Application Shortlisted',
            'Application Rejected',
            'Profile Update',
            'New Internship',
            'Deadline Reminder',
            'Document Verification',
            'Company Approved',
            'Company Rejected',
            'Message Received',
            'System Alert',
            'Other'
        ],
        required: true,
        index: true
    },

    // Priority & Category
    priority: { type: String, enum: ['Low', 'Medium', 'High', 'Urgent'], default: 'Medium' },
    category: { type: String, enum: ['Info', 'Success', 'Warning', 'Error'], default: 'Info' },

    // Related Entities (for deep linking)
    relatedEntity: {
        entityType: { type: String, enum: ['Application', 'Internship', 'Company', 'Student', 'User'] },
        entityId: { type: mongoose.Schema.Types.ObjectId }
    },

    // Action & Deep Linking
    actionRequired: { type: Boolean, default: false },
    actionUrl: String, // Deep link for navigation
    actionText: String, // E.g., "View Application", "Upload Documents"

    // Status
    isRead: { type: Boolean, default: false, index: true },
    readAt: Date,

    // Delivery Status
    deliveryStatus: {
        push: {
            sent: { type: Boolean, default: false },
            sentAt: Date,
            success: Boolean,
            error: String
        },
        email: {
            sent: { type: Boolean, default: false },
            sentAt: Date,
            success: Boolean,
            error: String
        },
        sms: {
            sent: { type: Boolean, default: false },
            sentAt: Date,
            success: Boolean,
            error: String
        },
        inApp: {
            delivered: { type: Boolean, default: true },
            deliveredAt: { type: Date, default: Date.now }
        }
    },

    // Scheduling
    scheduledFor: Date, // If sending in future
    sentAt: Date,

    // Expiry
    expiresAt: Date, // Auto-delete after this date

    // Additional Data (for rich notifications)
    data: mongoose.Schema.Types.Mixed, // Custom payload for specific notification types

    // Metadata
    source: { type: String, default: 'System' }, // Where the notification originated
    isSilent: { type: Boolean, default: false }, // Don't make sound/vibration

    // Bulk notification tracking
    campaignId: String, // For bulk notifications
    batchId: String

}, {
    timestamps: true
});

// Indexes
notificationSchema.index({ user: 1, isRead: 1, createdAt: -1 });
notificationSchema.index({ user: 1, type: 1, createdAt: -1 });
notificationSchema.index({ createdAt: -1 });
notificationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 }); // Auto-delete expired

// Auto-mark as read after 30 days
notificationSchema.index({ createdAt: 1 }, {
    expireAfterSeconds: 30 * 24 * 60 * 60,
    partialFilterExpression: { isRead: true }
});

module.exports = mongoose.model('Notification', notificationSchema);
