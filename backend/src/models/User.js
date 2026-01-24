const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    email: { type: String, unique: true, sparse: true, index: true },
    phoneNumber: { type: String, unique: true, sparse: true, index: true },
    password: {
        type: String,
        required: function () { return !this.googleId && !this.linkedinId && !this.phoneNumber; }
    },
    role: { type: String, enum: ['student', 'company', 'admin'], default: 'student', index: true },
    googleId: { type: String, unique: true, sparse: true },
    linkedinId: { type: String, unique: true, sparse: true },
    isVerified: { type: Boolean, default: false },
    otpCode: String,
    otpExpires: Date,
    refreshToken: String,

    // Profile references can be useful here too, but we kept them in separate collections
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', userSchema);
