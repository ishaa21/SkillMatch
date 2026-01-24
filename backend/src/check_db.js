const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./models/User');

dotenv.config();

const checkDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/internship_app');
        console.log('Connected to DB');

        const companyUser = await User.findOne({ email: 'company@test.com' });
        if (companyUser) {
            console.log('Found Company User:');
            console.log(companyUser);
        } else {
            console.log('Company User NOT FOUND');
        }

        process.exit();
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
};

checkDB();
