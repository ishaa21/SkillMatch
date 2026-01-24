const mongoose = require('mongoose');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/internship_app';

console.log('Attempting to connect to:', MONGO_URI);

mongoose.connect(MONGO_URI)
    .then(() => {
        console.log('✅ MongoDB connection successful!');
        console.log('Connection host:', mongoose.connection.host);
        console.log('Database name:', mongoose.connection.name);
        process.exit(0);
    })
    .catch((error) => {
        console.error('❌ MongoDB connection failed:');
        console.error('Error:', error.message);
        console.error('\nPossible issues:');
        console.error('1. MongoDB is not running');
        console.error('2. MongoDB is running on a different port');
        console.error('3. Connection string is incorrect');
        process.exit(1);
    });
