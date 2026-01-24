const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Student = require('../models/Student');
const Company = require('../models/Company');
const Internship = require('../models/Internship');
const Application = require('../models/Application');

// Load env vars
dotenv.config({ path: '../../.env' });

const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/internship_app');
        console.log('MongoDB Connected for Seeding');
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

const seedData = async () => {
    await connectDB();

    try {
        console.log('Clearing existing data...');
        await User.deleteMany({});
        await Student.deleteMany({});
        await Company.deleteMany({});
        await Internship.deleteMany({});
        await Application.deleteMany({});

        console.log('Creating Users...');
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash('password123', salt);

        // --- Users ---
        const userAdmin = await User.create({
            email: 'admin@skillmatch.com',
            password: hashedPassword,
            role: 'admin',
            isVerified: true
        });

        const userCompany1 = await User.create({
            email: 'hr@techindia.com',
            password: hashedPassword,
            role: 'company',
            isVerified: true
        });

        const userCompany2 = await User.create({
            email: 'careers@innovatebangalore.com',
            password: hashedPassword,
            role: 'company',
            isVerified: true
        });

        const userStudent1 = await User.create({
            email: 'aarav.patel@gmail.com',
            password: hashedPassword,
            role: 'student',
            isVerified: true
        });

        const userStudent2 = await User.create({
            email: 'diya.sharma@gmail.com',
            password: hashedPassword,
            role: 'student',
            isVerified: true
        });

        const userStudent3 = await User.create({
            email: 'rohan.verma@gmail.com',
            password: hashedPassword,
            role: 'student',
            isVerified: true
        });

        console.log('Creating Profiles...');

        // --- Companies ---
        const company1 = await Company.create({
            user: userCompany1._id,
            companyName: 'TechIndia Solutions',
            description: 'Leading IT services provider specializing in cloud computing and AI.',
            website: 'https://techindia.com',
            location: 'Hyderabad, India',
            industry: 'Information Technology',
            isApproved: true
        });

        const company2 = await Company.create({
            user: userCompany2._id,
            companyName: 'Innovate Bangalore',
            description: 'A fast-growing startup focused on sustainable tech and green energy software.',
            website: 'https://innovateblr.com',
            location: 'Bangalore, India',
            industry: 'CleanTech',
            isApproved: true
        });

        // --- Students ---
        const student1 = await Student.create({
            user: userStudent1._id,
            fullName: 'Aarav Patel',
            university: 'IIT Bombay',
            course: 'B.Tech Computer Science',
            skills: [
                { name: 'React', proficiency: 'Advanced' },
                { name: 'Node.js', proficiency: 'Intermediate' },
                { name: 'MongoDB', proficiency: 'Advanced' }
            ],
            interests: ['Web Development', 'Full Stack', 'Cloud'],
            internshipPreferences: {
                type: 'Remote',
                locations: ['Mumbai', 'Remote'],
                minStipend: 15000
            },
            availability: {
                status: 'Available',
                startDate: new Date()
            }
        });

        const student2 = await Student.create({
            user: userStudent2._id,
            fullName: 'Diya Sharma',
            university: 'BITS Pilani',
            course: 'M.Sc Data Science',
            skills: [
                { name: 'Python', proficiency: 'Expert' },
                { name: 'Machine Learning', proficiency: 'Advanced' },
                { name: 'PyTorch', proficiency: 'Intermediate' }
            ],
            interests: ['AI', 'Data Science', 'Research'],
            internshipPreferences: {
                type: 'Any',
                locations: ['Bangalore', 'Remote'],
                minStipend: 25000
            }
        });

        const student3 = await Student.create({
            user: userStudent3._id,
            fullName: 'Rohan Verma',
            university: 'VIT Vellore',
            course: 'B.Tech Electronics',
            skills: [
                { name: 'Flutter', proficiency: 'Intermediate' },
                { name: 'Dart', proficiency: 'Intermediate' },
                { name: 'Firebase', proficiency: 'Beginner' }
            ],
            interests: ['Mobile App Dev', 'UI/UX'],
            internshipPreferences: {
                type: 'Remote',
                locations: ['Chennai', 'Remote'],
                minStipend: 10000
            }
        });

        console.log('Creating Internships...');

        // --- Internships ---
        const internship1 = await Internship.create({
            company: company1._id,
            title: 'Full Stack Developer Intern',
            description: 'Work on our core banking platform using MERN stack. Great learning opportunity.',
            stipend: { amount: 20000, currency: 'INR', interval: 'Monthly' },
            location: 'Hyderabad (Remote allowed)',
            workMode: 'Remote',
            duration: '6 Months',
            skillsRequired: [
                { name: 'React', level: 'Intermediate' },
                { name: 'Node.js', level: 'Intermediate' }
            ],
            domains: ['Web Development', 'FinTech'],
            isActive: true,
            postedAt: new Date()
        });

        const internship2 = await Internship.create({
            company: company2._id,
            title: 'AI Research Intern',
            description: 'Research and implement SOTA models for green energy forecasting.',
            stipend: { amount: 30000, currency: 'INR', interval: 'Monthly' },
            location: 'Bangalore',
            workMode: 'On-site',
            duration: '3 Months',
            skillsRequired: [
                { name: 'Python', level: 'Advanced' },
                { name: 'Machine Learning', level: 'Intermediate' }
            ],
            domains: ['AI', 'CleanTech', 'Data Science'],
            isActive: true,
            postedAt: new Date()
        });

        const internship3 = await Internship.create({
            company: company1._id,
            title: 'Flutter Mobile Dev',
            description: 'Build responsive mobile apps for our client portfolio.',
            stipend: { amount: 15000, currency: 'INR', interval: 'Monthly' },
            location: 'Remote',
            workMode: 'Remote',
            duration: '4 Months',
            skillsRequired: [
                { name: 'Flutter', level: 'Intermediate' }
            ],
            domains: ['Mobile App Dev'],
            isActive: true,
            postedAt: new Date()
        });

        console.log('Creating Applications...');

        // --- Applications ---
        // Aarav applies to Full Stack (Match!)
        await Application.create({
            student: student1._id,
            internship: internship1._id,
            company: company1._id,
            status: 'Applied',
            aiMatchScore: 92
        });

        // Diya applies to AI Research (Perfect Match!)
        await Application.create({
            student: student2._id,
            internship: internship2._id,
            company: company2._id,
            status: 'Shortlisted', // Company liked her
            aiMatchScore: 98
        });

        // Rohan applies to Flutter (Good Match) but withdrawn example? No, let's say Rejected for variety or Hired.
        // Let's say Hired.
        await Application.create({
            student: student3._id,
            internship: internship3._id,
            company: company1._id,
            status: 'Hired',
            aiMatchScore: 85
        });

        console.log('✅ Data Seeding Completed Successfully!');
        console.log('--------------------------------------------------');
        console.log('Admin Email: admin@skillmatch.com');
        console.log('Company 1 Email: hr@techindia.com');
        console.log('Company 2 Email: careers@innovatebangalore.com');
        console.log('Student 1 Email: aarav.patel@gmail.com');
        console.log('Student 2 Email: diya.sharma@gmail.com');
        console.log('All Passwords: password123');
        console.log('--------------------------------------------------');
        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

seedData();
