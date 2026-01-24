const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('../models/User');
const Student = require('../models/Student');
const Company = require('../models/Company');
const Internship = require('../models/Internship');
const Application = require('../models/Application');
const Skill = require('../models/Skill');

dotenv.config({ path: '../.env' });

const verifyData = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/internship_app');
        console.log('✓ MongoDB Connected');

        console.log('\n📊 Database Statistics:\n');
        console.log('========================================');

        const userCount = await User.countDocuments();
        const adminCount = await User.countDocuments({ role: 'admin' });
        const companyUserCount = await User.countDocuments({ role: 'company' });
        const studentUserCount = await User.countDocuments({ role: 'student' });

        console.log(`👥 Users: ${userCount} total`);
        console.log(`   • Admins: ${adminCount}`);
        console.log(`   • Companies: ${companyUserCount}`);
        console.log(`   • Students: ${studentUserCount}`);

        const studentCount = await Student.countDocuments();
        const companyCount = await Company.countDocuments();
        const approvedCompanies = await Company.countDocuments({ isApproved: true });
        const pendingCompanies = await Company.countDocuments({ isPendingReview: true });

        console.log(`\n🎓 Students: ${studentCount}`);
        console.log(`🏢 Companies: ${companyCount}`);
        console.log(`   • Approved: ${approvedCompanies}`);
        console.log(`   • Pending: ${pendingCompanies}`);

        const internshipCount = await Internship.countDocuments();
        const activeInternships = await Internship.countDocuments({ isActive: true, status: 'Active' });

        console.log(`\n💼 Internships: ${internshipCount}`);
        console.log(`   • Active: ${activeInternships}`);

        const applicationCount = await Application.countDocuments();
        const statuses = await Application.aggregate([
            { $group: { _id: '$status', count: { $sum: 1 } } },
            { $sort: { count: -1 } }
        ]);

        console.log(`\n📝 Applications: ${applicationCount}`);
        statuses.forEach(s => {
            console.log(`   • ${s._id}: ${s.count}`);
        });

        const skillCount = await Skill.countDocuments();
        console.log(`\n🎯 Skills: ${skillCount}`);

        // Sample data check
        console.log('\n========================================');
        console.log('✅ Sample Login Credentials:\n');

        const adminUsers = await User.find({ role: 'admin' }).limit(2);
        console.log('ADMIN ACCOUNTS:');
        adminUsers.forEach(u => console.log(`   • ${u.email}`));

        const companyUsers = await User.find({ role: 'company' }).limit(3);
        console.log('\nCOMPANY ACCOUNTS (Sample):');
        for (const u of companyUsers) {
            const company = await Company.findOne({ user: u._id });
            console.log(`   • ${u.email} (${company?.companyName || 'N/A'})`);
        }

        const studentUsers = await User.find({ role: 'student' }).limit(3);
        console.log('\nSTUDENT ACCOUNTS (Sample):');
        for (const u of studentUsers) {
            const student = await Student.findOne({ user: u._id });
            console.log(`   • ${u.email} (${student?.fullName || 'N/A'})`);
        }

        console.log('\nAll passwords: password123');
        console.log('========================================\n');

        process.exit(0);
    } catch (err) {
        console.error('Error:', err);
        process.exit(1);
    }
};

verifyData();
