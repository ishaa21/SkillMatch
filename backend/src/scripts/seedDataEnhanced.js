const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const path = require('path');
const User = require('../models/User');
const Student = require('../models/Student');
const Company = require('../models/Company');
const Internship = require('../models/Internship');
const Application = require('../models/Application');

// Load environment variables
dotenv.config({ path: path.join(__dirname, '../../.env') });

const connectDB = async () => {
    try {
        const uri = process.env.MONGODB_URI || process.env.MONGO_URI;
        if (!uri) throw new Error('MONGODB_URI is not defined in .env');

        await mongoose.connect(uri);
        console.log('✅ MongoDB Connected');
    } catch (err) {
        console.error('❌ DB Connection Error:', err.message);
        process.exit(1);
    }
};

// --- DATA HELPERS ---
const SKILLS = [
    { name: 'React', proficiency: 'Advanced' },
    { name: 'Node.js', proficiency: 'Intermediate' },
    { name: 'Python', proficiency: 'Expert' },
    { name: 'MongoDB', proficiency: 'Advanced' },
    { name: 'Flutter', proficiency: 'Intermediate' },
    { name: 'Java', proficiency: 'Intermediate' },
    { name: 'AWS', proficiency: 'Beginner' },
    { name: 'SQL', proficiency: 'Advanced' },
    { name: 'UI/UX Design', proficiency: 'Advanced' },
    { name: 'Machine Learning', proficiency: 'Intermediate' }
];

const INDUSTRIES = ['FinTech', 'EdTech', 'HealthTech', 'E-commerce', 'AI/ML', 'Consulting', 'SaaS', 'Cybersecurity'];
const LOCATIONS = [
    { city: 'Mumbai', coords: [72.8777, 19.0760] },
    { city: 'Bangalore', coords: [77.5946, 12.9716] },
    { city: 'Hyderabad', coords: [78.4867, 17.3850] },
    { city: 'Delhi', coords: [77.1025, 28.7041] },
    { city: 'Pune', coords: [73.8567, 18.5204] }
];

const seedData = async () => {
    await connectDB();

    try {
        console.log('🚮 Clearing Database...');
        await Promise.all([
            User.deleteMany({}),
            Student.deleteMany({}),
            Company.deleteMany({}),
            Internship.deleteMany({}),
            Application.deleteMany({})
        ]);

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash('password123', salt); // Default password

        // 1. Create Admins
        console.log('👨‍💼 Creating Admins...');
        await User.create([
            { email: 'admin1@skillmatch.com', password: hashedPassword, role: 'admin', isVerified: true },
            { email: 'admin2@skillmatch.com', password: hashedPassword, role: 'admin', isVerified: true }
        ]);

        // 2. Create Companies
        console.log('🏢 Creating 20 Companies...');
        const companies = [];
        for (let i = 1; i <= 20; i++) {
            const user = await User.create({
                email: `company${i}@tech.com`,
                password: hashedPassword,
                role: 'company',
                isVerified: true
            });

            const loc = LOCATIONS[i % LOCATIONS.length];
            const industry = INDUSTRIES[i % INDUSTRIES.length];

            const company = await Company.create({
                user: user._id,
                companyName: `Tech Giant ${i} Solutions`,
                companyDescription: `Leading innovator in ${industry} providing cutting-edge solutions worldwide.`, // Field name check: Schema uses 'description' usually, but request said 'companyDescription'. Adapting to Schema: mapped to 'description'.
                description: `Leading innovator in ${industry} providing cutting-edge solutions worldwide.`,
                website: `https://techgiant${i}.com`,
                location: `${loc.city}, India`,
                industry: industry,
                isApproved: true
            });
            companies.push(company);
        }

        // 3. Create Internships (3 per company = 60 total)
        console.log('💼 Creating 60+ Internships...');
        for (const company of companies) {
            for (let j = 1; j <= 3; j++) {
                const loc = LOCATIONS[Math.floor(Math.random() * LOCATIONS.length)];

                await Internship.create({
                    company: company._id,
                    title: `${company.industry} Intern - Role ${j}`,
                    description: `Join us to work on exciting ${company.industry} projects. Great learning curve.`,
                    stipend: { amount: 10000 + (j * 5000), currency: 'INR', interval: 'Monthly' },
                    location: {
                        city: loc.city,
                        country: 'India',
                        coordinates: { type: 'Point', coordinates: loc.coords }
                    },
                    workMode: j % 2 === 0 ? 'Remote' : 'On-site',
                    duration: { value: 3 + j, unit: 'Months', displayString: `${3 + j} Months` },
                    skillsRequired: SKILLS.slice(0, 3), // First 3 skills
                    domains: [company.industry, 'Software Engineering'],
                    isActive: true,
                    postedAt: new Date(),
                    deadline: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000), // 60 days from now
                    status: 'Active'
                });
            }
        }

        // 4. Create Students (10 students)
        console.log('🎓 Creating 10 Students...');
        for (let i = 1; i <= 10; i++) {
            const user = await User.create({
                email: `student${i}@uni.edu`,
                password: hashedPassword,
                role: 'student',
                isVerified: true
            });

            const loc = LOCATIONS[i % LOCATIONS.length];

            await Student.create({
                user: user._id,
                fullName: `Student User ${i}`,
                university: `Institute of Technology ${i}`,
                course: 'B.Tech Computer Science',
                skills: SKILLS.slice(i % 5, (i % 5) + 5), // Pick 5 skills
                interests: [INDUSTRIES[i % INDUSTRIES.length], 'Coding'],
                internshipPreferences: {
                    type: 'Any',
                    locations: [loc.city, 'Remote'],
                    minStipend: 5000
                },
                location: {
                    city: loc.city,
                    country: 'India',
                    coordinates: { type: 'Point', coordinates: loc.coords }
                },
                availability: { status: 'Available', startDate: new Date() },
                education: [{
                    institution: `Institute of Technology ${i}`,
                    degree: 'B.Tech',
                    fieldOfStudy: 'CS',
                    startYear: 2022,
                    endYear: 2026,
                    isCurrentlyStudying: true
                }],
                profileComplete: 85
            });
        }

        console.log('✅ SEEDING COMPLETE');
        console.log('--------------------------------------------------');
        console.log('🔑 Credentials (Password: password123)');
        console.log('--------------------------------------------------');
        console.log('Admin:    admin1@skillmatch.com');
        console.log('Company:  company1@tech.com  (up to company20)');
        console.log('Student:  student1@uni.edu   (up to student10)');
        console.log('--------------------------------------------------');

        process.exit();
    } catch (error) {
        console.error('❌ Seeding Failed:', error);
        process.exit(1);
    }
};

seedData();
