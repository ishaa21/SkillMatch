const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const path = require('path');
const User = require('../models/User');
const Student = require('../models/Student');
const Company = require('../models/Company');
const Internship = require('../models/Internship');
const Application = require('../models/Application');

// Load env vars (try multiple paths to be safe)
// Path is relative to where script is executed. 
// If run from backend root via `npm run seed`: src/scripts/seedData.js -> need ../../.env
dotenv.config({ path: path.join(__dirname, '../../.env') });

const connectDB = async () => {
    try {
        const uri = process.env.MONGODB_URI || process.env.MONGO_URI;
        if (!uri) {
            throw new Error('MONGODB_URI is not defined in .env');
        }
        await mongoose.connect(uri);
        console.log(`✅ MongoDB Connected to: ${uri.split('@')[1] || uri}`); // Log masked URI
    } catch (err) {
        console.error('❌ DB Connection Error:', err.message);
        process.exit(1);
    }
};

const seedData = async () => {
    await connectDB();

    try {
        console.log('⚠️ Clearing existing data...');
        // await User.deleteMany({});
        // await Student.deleteMany({});
        // await Company.deleteMany({});
        // await Internship.deleteMany({});
        // await Application.deleteMany({});

        // --- Selective Clear (Optional: Comment out to append instead of wipe) ---
        // For fresh demo, wipe is best.
        await Promise.all([
            User.deleteMany({}),
            Student.deleteMany({}),
            Company.deleteMany({}),
            Internship.deleteMany({}),
            Application.deleteMany({})
        ]);

        console.log('🌱 Creating Users...');
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

        console.log('🌱 Creating Profiles...');

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
        // Note: We omit coordinates to let schema default or remain undefined to avoid GeoJSON errors
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
            location: {
                city: 'Mumbai',
                country: 'India',
                coordinates: {
                    type: 'Point',
                    coordinates: [72.8777, 19.0760] // Mumbai
                }
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
            },
            location: {
                city: 'Bangalore',
                country: 'India',
                coordinates: {
                    type: 'Point',
                    coordinates: [77.5946, 12.9716] // Bangalore
                }
            }
        });

        console.log('🌱 Creating Internships...');

        // --- Internships ---
        const internship1 = await Internship.create({
            company: company1._id,
            title: 'Full Stack Developer Intern',
            description: 'Work on our core banking platform using MERN stack. Great learning opportunity.',
            stipend: { amount: 20000, currency: 'INR', interval: 'Monthly' },
            location: {
                city: 'Hyderabad',
                country: 'India',
                coordinates: {
                    type: 'Point',
                    coordinates: [78.4867, 17.3850] // Hyderabad
                }
            },
            workMode: 'Remote',
            duration: { value: 6, unit: 'Months' },
            skillsRequired: [
                { name: 'React', level: 'Intermediate' },
                { name: 'Node.js', level: 'Intermediate' }
            ],
            domains: ['Web Development', 'FinTech'],
            isActive: true,
            postedAt: new Date(),
            deadline: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days from now
        });

        const internship2 = await Internship.create({
            company: company2._id,
            title: 'AI Research Intern',
            description: 'Research and implement SOTA models for green energy forecasting.',
            stipend: { amount: 30000, currency: 'INR', interval: 'Monthly' },
            location: {
                city: 'Bangalore',
                country: 'India',
                coordinates: {
                    type: 'Point',
                    coordinates: [77.5946, 12.9716] // Bangalore
                }
            },
            workMode: 'On-site',
            duration: { value: 3, unit: 'Months' },
            skillsRequired: [
                { name: 'Python', level: 'Advanced' },
                { name: 'Machine Learning', level: 'Intermediate' }
            ],
            domains: ['AI', 'CleanTech', 'Data Science'],
            isActive: true,
            postedAt: new Date(),
            deadline: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000) // 60 days from now
        });

        console.log('🌱 Creating Applications...');

        // --- Applications ---
        await Application.create({
            student: student1._id,
            internship: internship1._id,
            company: company1._id,
            status: 'Applied',
            aiMatchScore: 92
        });

        await Application.create({
            student: student2._id,
            internship: internship2._id,
            company: company2._id,
            status: 'Shortlisted',
            aiMatchScore: 98
        });

        console.log('✅ Data Seeding Completed Successfully!');
        console.log('--------------------------------------------------');
        console.log('Admin:    admin@skillmatch.com      / password123');
        console.log('Company:  hr@techindia.com          / password123');
        console.log('Student:  aarav.patel@gmail.com     / password123');
        console.log('--------------------------------------------------');
        process.exit();
    } catch (err) {
        console.error('❌ Seeding Error:', err);
        process.exit(1);
    }
};

seedData();
