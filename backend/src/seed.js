const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const User = require('./models/User');
const Student = require('./models/Student');
const Company = require('./models/Company');
const Internship = require('./models/Internship');
const Application = require('./models/Application');

dotenv.config();

const connectDB = async () => {
    try {
        const conn = await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/internship_app');
        console.log(`MongoDB Connected: ${conn.connection.host}`);
    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
};

const seedData = async () => {
    await connectDB();

    console.log('Clearing database...');
    await User.deleteMany({});
    await Student.deleteMany({});
    await Company.deleteMany({});
    await Internship.deleteMany({});
    await Application.deleteMany({});

    console.log('Creating users...');
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('password123', salt);

    // 0. Create Admin User
    await User.create({
        email: 'admin@test.com',
        password: hashedPassword,
        role: 'admin',
        isVerified: true
    });
    console.log('Admin user created: admin@test.com / password123');

    // 1. Create Companies

    // Tech Corp
    const techCompanyUser = await User.create({
        email: 'company@test.com',
        password: hashedPassword,
        role: 'company',
        isVerified: true
    });

    const techCompany = await Company.create({
        user: techCompanyUser._id,
        companyName: 'Tech Innovators Inc.',
        description: 'Leading the way in AI and Web Development solutions.',
        industry: 'Technology',
        location: 'San Francisco, CA',
        isApproved: true,
        logoUrl: 'https://via.placeholder.com/150'
    });

    // Creative Studio
    const designCompanyUser = await User.create({
        email: 'design@test.com',
        password: hashedPassword,
        role: 'company',
        isVerified: true
    });

    const designCompany = await Company.create({
        user: designCompanyUser._id,
        companyName: 'Creative Minds Studio',
        description: 'We craft beautiful digital experiences.',
        industry: 'Design',
        location: 'New York, NY',
        isApproved: true,
        logoUrl: 'https://via.placeholder.com/150'
    });

    // Pending Company (for testing admin approvals)
    const startupUser = await User.create({
        email: 'startup@test.com',
        password: hashedPassword,
        role: 'company',
        isVerified: true
    });

    const startupCompany = await Company.create({
        user: startupUser._id,
        companyName: 'InnovateTech Startup',
        description: 'A cutting-edge startup building the future of work.',
        industry: 'Technology',
        location: 'Austin, TX',
        isApproved: false,  // Pending approval
        logoUrl: 'https://via.placeholder.com/150'
    });
    console.log('Pending company created for admin testing');

    // 2. Create Students

    // John (Full Stack)
    const johnUser = await User.create({
        email: 'student@test.com',
        password: hashedPassword,
        role: 'student',
        isVerified: true
    });

    const johnStudent = await Student.create({
        user: johnUser._id,
        fullName: 'John Doe',
        university: 'MIT',
        degree: 'B.S. Computer Science',
        skills: [
            { name: 'React', proficiency: 'Expert' },
            { name: 'Node.js', proficiency: 'Intermediate' },
            { name: 'JavaScript', proficiency: 'Advanced' }
        ],
        interests: ['Web Development', 'AI'],
        internshipPreferences: {
            type: 'Remote',
            locations: ['San Francisco', 'Remote']
        },
        resumeUrl: 'https://example.com/resume.pdf'
    });

    // Alice (Designer)
    const aliceUser = await User.create({
        email: 'alice@test.com',
        password: hashedPassword,
        role: 'student',
        isVerified: true
    });

    const aliceStudent = await Student.create({
        user: aliceUser._id,
        fullName: 'Alice Smith',
        university: 'Parsons School of Design',
        degree: 'B.A. Design',
        skills: [
            { name: 'Figma', proficiency: 'Advanced' },
            { name: 'UI Design', proficiency: 'Expert' }
        ],
        interests: ['UI/UX', 'Product Design'],
        internshipPreferences: {
            type: 'Hybrid',
            locations: ['New York']
        }
    });

    // 3. Create Internships

    const reactInternship = await Internship.create({
        company: techCompany._id,
        title: 'React Frontend Developer Intern',
        description: 'Looking for a passionate React developer to build modern web interfaces. Must know Hooks and Redux.',
        workMode: 'Remote',
        skillsRequired: [{ name: 'React', level: 'Intermediate' }, { name: 'JavaScript', level: 'Advanced' }, { name: 'CSS', level: 'Intermediate' }],
        stipend: { amount: 1000, currency: 'USD', period: 'Month' },
        duration: '3 Months',
        location: 'Remote',
        isActive: true
    });

    const nodeInternship = await Internship.create({
        company: techCompany._id,
        title: 'Backend Node.js Developer',
        description: 'Help us scale our API services using Node.js and MongoDB.',
        workMode: 'On-site',
        skillsRequired: [{ name: 'Node.js', level: 'Intermediate' }, { name: 'MongoDB', level: 'Intermediate' }, { name: 'Express', level: 'Intermediate' }],
        stipend: { amount: 1200, currency: 'USD', period: 'Month' },
        duration: '6 Months',
        location: 'San Francisco, CA',
        isActive: true
    });

    const designInternship = await Internship.create({
        company: designCompany._id,
        title: 'UI/UX Design Intern',
        description: 'Create stunning user interfaces for mobile and web apps.',
        workMode: 'Hybrid',
        skillsRequired: [{ name: 'Figma', level: 'Advanced' }, { name: 'UI Design', level: 'Expert' }, { name: 'Prototyping', level: 'Intermediate' }],
        stipend: { amount: 800, currency: 'USD', period: 'Month' },
        duration: '3 Months',
        location: 'New York, NY',
        isActive: true
    });

    // 4. Create Applications

    // John applies to React Internship
    await Application.create({
        student: johnStudent._id,
        internship: reactInternship._id,
        company: techCompany._id,
        status: 'Applied',
        coverLetter: 'I love React and have built several projects.',
        resumeUrl: johnStudent.resumeUrl
    });

    // John also applies to Node Internship
    await Application.create({
        student: johnStudent._id,
        internship: nodeInternship._id,
        company: techCompany._id,
        status: 'Shortlisted',
        coverLetter: 'I am also good at backend.',
        resumeUrl: johnStudent.resumeUrl
    });

    // Alice applies to Design Internship
    await Application.create({
        student: aliceStudent._id,
        internship: designInternship._id,
        company: designCompany._id,
        status: 'Applied',
        coverLetter: 'Check out my portfolio!',
        resumeUrl: 'https://alice.design/portfolio'
    });

    console.log('Dummy data seeded successfully!');
    console.log('');
    console.log('=== Login Credentials ===');
    console.log('Admin:   admin@test.com / password123');
    console.log('Company: company@test.com / password123');
    console.log('Student: student@test.com / password123');
    console.log('Pending: startup@test.com / password123');
    console.log('');

    process.exit();
};

seedData();
