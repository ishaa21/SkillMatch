
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Student = require('../models/Student');
const Company = require('../models/Company');
const Internship = require('../models/Internship');
const Application = require('../models/Application');
const connectDB = require('../config/db');

dotenv.config();

const seedIndianData = async () => {
    try {
        await connectDB();

        console.log('Clearing existing data...');
        await User.deleteMany({});
        await Student.deleteMany({});
        await Company.deleteMany({});
        await Internship.deleteMany({});
        await Application.deleteMany({});

        console.log('Seeding Users...');
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash('password123', salt);

        // 1. Create Users
        const studentsData = [
            { name: 'Aarav Patel', email: 'aarav@example.com', location: 'Mumbai', skills: ['JavaScript', 'React'], degree: 'B.Tech', university: 'IIT Bombay' },
            { name: 'Diya Sharma', email: 'diya@example.com', location: 'Bangalore', skills: ['Python', 'ML'], degree: 'M.Sc', university: 'IISc Bangalore' },
            { name: 'Vihaan Gupta', email: 'vihaan@example.com', location: 'Delhi', skills: ['Java', 'Spring'], degree: 'B.E', university: 'DTU' },
            { name: 'Aditi Singh', email: 'aditi@example.com', location: 'Hyderabad', skills: ['Figma', 'UI/UX'], degree: 'B.Des', university: 'NID' },
            { name: 'Rohan Mehta', email: 'rohan@example.com', location: 'Pune', skills: ['C++', 'Rust'], degree: 'B.Tech', university: 'COEP' }
        ];

        const companiesData = [
            { name: 'TechSolutions India', email: 'hr@techsolutions.in', location: 'Bangalore', website: 'https://techsolutions.in', approved: true },
            { name: 'InnovateHub Mumbai', email: 'careers@innovatehub.com', location: 'Mumbai', website: 'https://innovatehub.com', approved: true },
            { name: 'GreenTech Hyderabad', email: 'jobs@greentech.hy', location: 'Hyderabad', website: 'https://greentech.hy', approved: true },
            { name: 'PixelDesizn', email: 'hello@pixeldesizn.com', location: 'Delhi', website: 'https://pixeldesizn.com', approved: false }
        ];

        const adminData = { name: 'Admin User', email: 'admin@skillmatch.com' };

        // Insert Admin
        await User.create({
            email: adminData.email,
            password: hashedPassword,
            role: 'admin',
            isVerified: true
        });

        // Insert Students
        const createdStudents = [];
        for (const s of studentsData) {
            const user = await User.create({
                email: s.email,
                password: hashedPassword,
                role: 'student',
                isVerified: true
            });

            const studentProfile = await Student.create({
                user: user._id,
                fullName: s.name,
                university: s.university,
                degree: s.degree,
                linkedin: `https://linkedin.com/in/${s.name.replace(' ', '').toLowerCase()}`,
                skills: s.skills.map(skill => ({ name: skill, proficiency: 'Intermediate' })),
                preference: { locations: [s.location] },
                availability: { status: 'Available' }
            });
            createdStudents.push(studentProfile);
        }

        // Insert Companies
        const createdCompanies = [];
        for (const c of companiesData) {
            const user = await User.create({
                email: c.email,
                password: hashedPassword,
                role: 'company',
                isVerified: true
            });

            const companyProfile = await Company.create({
                user: user._id,
                companyName: c.name,
                location: c.location,
                website: c.website,
                description: `${c.name} is a leading company in ${c.location}.`,
                isApproved: c.approved,
                ...(c.approved ? { approvedAt: new Date() } : {})
            });
            createdCompanies.push(companyProfile);
        }

        console.log('Seeding Internships...');
        // TechSolutions (0) -> Full Stack & Backend
        const i1 = await Internship.create({
            company: createdCompanies[0]._id,
            title: 'Full Stack Intern',
            description: 'Work with MERN stack.',
            roleType: 'Internship',
            workMode: 'Hybrid',
            skillsRequired: [{ name: 'React', level: 'Intermediate' }, { name: 'Node.js' }],
            stipend: { amount: 25000, currency: 'INR', period: 'Month' },
            location: 'Bangalore',
            domains: ['Web Development'],
            isActive: true
        });

        const i2 = await Internship.create({
            company: createdCompanies[0]._id,
            title: 'Backend Developer Intern',
            description: 'Build scalable APIs.',
            roleType: 'Internship',
            workMode: 'On-site',
            skillsRequired: [{ name: 'Java', level: 'Intermediate' }],
            stipend: { amount: 20000, currency: 'INR', period: 'Month' },
            location: 'Bangalore',
            domains: ['Backend'],
            isActive: true
        });

        // InnovateHub (1) -> AI/ML
        const i3 = await Internship.create({
            company: createdCompanies[1]._id,
            title: 'AI/ML Research Intern',
            description: 'NLP Research.',
            roleType: 'Internship',
            workMode: 'Remote',
            skillsRequired: [{ name: 'Python', level: 'Advanced' }],
            stipend: { amount: 30000, currency: 'INR', period: 'Month' },
            location: 'Remote',
            domains: ['AI/ML'],
            isActive: true
        });

        // GreenTech (2) -> Flutter
        const i4 = await Internship.create({
            company: createdCompanies[2]._id,
            title: 'Flutter App Developer',
            description: 'Mobile app development.',
            roleType: 'Internship',
            workMode: 'On-site',
            skillsRequired: [{ name: 'Flutter', level: 'Intermediate' }],
            stipend: { amount: 22000, currency: 'INR', period: 'Month' },
            location: 'Hyderabad',
            domains: ['Mobile App'],
            isActive: true // Active
        });

        // PixelDesizn (3) - Approved: false in company, but lets verify internship creation
        // Usually unapproved companies can't post, but direct DB seed bypasses checks?
        // Let's create one for them, but maybe set isActive: false
        const i5 = await Internship.create({
            company: createdCompanies[3]._id,
            title: 'UI/UX Design Intern',
            description: 'Creative design.',
            roleType: 'Internship',
            workMode: 'Remote',
            skillsRequired: [{ name: 'Figma', level: 'Intermediate' }],
            stipend: { amount: 15000, currency: 'INR', period: 'Month' },
            location: 'Remote',
            domains: ['UI/UX'],
            isActive: false
        });

        console.log('Seeding Applications...');
        // Aarav (0) -> Full Stack (i1) - Applied
        await Application.create({
            student: createdStudents[0]._id,
            internship: i1._id,
            company: createdCompanies[0]._id,
            status: 'Applied',
            coverLetter: 'Interested in MERN stack.'
        });

        // Diya (1) -> AI/ML (i3) - Shortlisted
        await Application.create({
            student: createdStudents[1]._id,
            internship: i3._id,
            company: createdCompanies[1]._id,
            status: 'Shortlisted',
            coverLetter: 'ML expert here.'
        });

        // Vihaan (2) -> Backend (i2) - Rejected
        await Application.create({
            student: createdStudents[2]._id,
            internship: i2._id,
            company: createdCompanies[0]._id,
            status: 'Rejected',
            coverLetter: 'Backend enthusiast.'
        });

        console.log('Database seeded successfully!');
        console.log('Admin: admin@skillmatch.com');
        process.exit();
    } catch (error) {
        console.error('Seeding error:', error);
        process.exit(1);
    }
};

seedIndianData();
