const mongoose = require('mongoose');

const connectDB = async () => {
    const uri = process.env.MONGODB_URI;

    console.log('MONGODB_URI from env:', uri ? 'FOUND' : 'NOT FOUND');

    if (!uri) {
        throw new Error('❌ MONGODB_URI is missing in environment variables');
    }

    try {
        await mongoose.connect(uri, {
            useNewUrlParser: true,
            useUnifiedTopology: true,
        });

        console.log('✅ MongoDB Connected');
    } catch (error) {
        console.error('❌ MongoDB connection failed:', error.message);
        process.exit(1);
    }
};

module.exports = connectDB;
