const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Student = require('../models/Student');
const Company = require('../models/Company');
const Internship = require('../models/Internship');
const Application = require('../models/Application');
const Skill = require('../models/Skill');

// Load env vars
dotenv.config({ path: '../.env' });

const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/internship_app');
        console.log('✓ MongoDB Connected for Seeding');
    } catch (err) {
        console.error('✗ MongoDB Connection Error:', err);
        process.exit(1);
    }
};

// Sample Data Collections
const skillsData = [
    { name: 'React', category: 'Web Development', demandScore: 95 },
    { name: 'Node.js', category: 'Web Development', demandScore: 90 },
    { name: 'Python', category: 'Programming Languages', demandScore: 98 },
    { name: 'Java', category: 'Programming Languages', demandScore: 85 },
    { name: 'JavaScript', category: 'Programming Languages', demandScore: 95 },
    { name: 'TypeScript', category: 'Programming Languages', demandScore: 88 },
    { name: 'Flutter', category: 'Mobile Development', demandScore: 82 },
    { name: 'React Native', category: 'Mobile Development', demandScore: 80 },
    { name: 'Machine Learning', category: 'Data Science & AI', demandScore: 92 },
    { name: 'Data Analysis', category: 'Data Science & AI', demandScore: 88 },
    { name: 'MongoDB', category: 'Database', demandScore: 85 },
    { name: 'PostgreSQL', category: 'Database', demandScore: 83 },
    { name: 'AWS', category: 'DevOps & Cloud', demandScore: 90 },
    { name: 'Docker', category: 'DevOps & Cloud', demandScore: 87 },
    { name: 'Figma', category: 'Design', demandScore: 78 },
    { name: 'UI/UX Design', category: 'Design', demandScore: 75 },
    { name: 'Digital Marketing', category: 'Marketing', demandScore: 70 },
    { name: 'SEO', category: 'Marketing', demandScore: 68 },
    { name: 'Content Writing', category: 'Content & Writing', demandScore: 65 },
    { name: 'Django', category: 'Web Development', demandScore: 80 }
];

const studentNames = [
    'Aarav Patel', 'Diya Sharma', 'Rohan Verma', 'Ananya Singh', 'Vihaan Kumar',
    'Aisha Gupta', 'Arjun Reddy', 'Ishita Nair', 'Kabir Mehta', 'Saanvi Iyer',
    'Advait Joshi', 'Myra Desai', 'Reyansh Malhotra', 'Kiara Kapoor', 'Dhruv Agarwal',
    'Navya Bhat', 'Arnav Roy', 'Priya Menon', 'Ayaan Khan', 'Riya Chopra'
];

const universities = [
    'IIT Bombay', 'IIT Delhi', 'BITS Pilani', 'NIT Trichy', 'VIT Vellore',
    'IIIT Hyderabad', 'Delhi University', 'Mumbai University', 'Pune University', 'Bangalore University',
    'Anna University', 'SRM Institute', 'Manipal Institute', 'Amity University', 'Christ University'
];

const degrees = [
    'B.Tech Computer Science', 'B.Tech IT', 'M.Tech AI', 'M.Sc Data Science', 'BCA',
    'MCA', 'B.Tech Electronics', 'B.Tech Mechanical', 'MBA Tech', 'B.Des'
];

const cities = [
    'Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Chennai',
    'Pune', 'Kolkata', 'Ahmedabad', 'Jaipur', 'Lucknow'
];

const companyData = [
    { name: 'TechMahindra Solutions', industry: 'IT Services', type: 'MNC', size: '1000+', city: 'Mumbai' },
    { name: 'Innovate Bangalore Pvt Ltd', industry: 'CleanTech', type: 'Startup', size: '51-200', city: 'Bangalore' },
    { name: 'DataMinds AI', industry: 'Artificial Intelligence', type: 'Startup', size: '11-50', city: 'Hyderabad' },
    { name: 'CloudFront Technologies', industry: 'Cloud Computing', type: 'SME', size: '201-500', city: 'Pune' },
    { name: 'MobileFirst Apps', industry: 'Mobile Development', type: 'Startup', size: '11-50', city: 'Bangalore' },
    { name: 'FinTech India Ltd', industry: 'Financial Technology', type: 'Startup', size: '51-200', city: 'Mumbai' },
    { name: 'EduLearn Solutions', industry: 'EdTech', type: 'Startup', size: '11-50', city: 'Delhi' },
    { name: 'HealthTech Innovations', industry: 'HealthTech', type: 'SME', size: '51-200', city: 'Chennai' },
    { name: 'GreenEnergy Corp', industry: 'Renewable Energy', type: 'MNC', size: '501-1000', city: 'Bangalore' },
    { name: 'RetailTech Solutions', industry: 'E-Commerce', type: 'SME', size: '201-500', city: 'Pune' },
    { name: 'CyberShield Security', industry: 'Cybersecurity', type: 'SME', size: '51-200', city: 'Hyderabad' },
    { name: 'GameDev Studios', industry: 'Gaming', type: 'Startup', size: '11-50', city: 'Bangalore' },
    { name: 'MarketPro Analytics', industry: 'Marketing Tech', type: 'Startup', size: '11-50', city: 'Mumbai' },
    { name: 'AutoTech Dynamics', industry: 'Automotive Tech', type: 'SME', size: '201-500', city: 'Chennai' },
    { name: 'SocialBuzz Media', industry: 'Social Media', type: 'Startup', size: '11-50', city: 'Delhi' },
    { name: 'LogiChain Solutions', industry: 'Logistics', type: 'SME', size: '51-200', city: 'Ahmedabad' },
    { name: 'AgriTech Farms', industry: 'AgriTech', type: 'Startup', size: '11-50', city: 'Pune' },
    { name: 'TravelEase Technologies', industry: 'Travel Tech', type: 'Startup', size: '11-50', city: 'Bangalore' },
    { name: 'BlockChain Ventures', industry: 'Blockchain', type: 'Startup', size: '11-50', city: 'Mumbai' },
    { name: 'VR Experiences Ltd', industry: 'Virtual Reality', type: 'Startup', size: '11-50', city: 'Hyderabad' }
];

// Helper function to get random item from array
const getRandom = (arr) => arr[Math.floor(Math.random() * arr.length)];
const getRandomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const getRandomBool = () => Math.random() > 0.5;

const seedData = async () => {
    await connectDB();

    try {
        console.log('\n🗑️  Clearing existing data...');
        await User.deleteMany({});
        await Student.deleteMany({});
        await Company.deleteMany({});
        await Internship.deleteMany({});
        await Application.deleteMany({});
        await Skill.deleteMany({});

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash('password123', salt);

        // ==================== CREATE SKILLS ====================
        console.log('\n🎯 Creating predefined skills...');
        const skills = await Skill.insertMany(skillsData.map(skill => ({
            ...skill,
            normalizedName: skill.name.toLowerCase(),
            isVerified: true,
            isActive: true
        })));
        console.log(`✓ Created ${skills.length} skills`);

        // ==================== CREATE ADMINS ====================
        console.log('\n👔 Creating Admin Users...');
        const adminUsers = await User.insertMany([
            {
                email: 'admin@skillmatch.com',
                password: hashedPassword,
                role: 'admin',
                isVerified: true
            },
            {
                email: 'superadmin@skillmatch.com',
                password: hashedPassword,
                role: 'admin',
                isVerified: true
            }
        ]);
        console.log(`✓ Created ${adminUsers.length} admin users`);

        // ==================== CREATE COMPANIES ====================
        console.log('\n🏢 Creating 20 Companies...');
        const companyUsers = [];
        const companies = [];

        for (let i = 0; i < 20; i++) {
            const companyInfo = companyData[i];
            const domain = companyInfo.name.toLowerCase().replace(/\s+/g, '');

            const companyUser = await User.create({
                email: `hr@${domain}.com`,
                password: hashedPassword,
                role: 'company',
                isVerified: true
            });
            companyUsers.push(companyUser);

            // Random coordinates for Indian cities
            const coords = {
                'Mumbai': [72.8777, 19.0760],
                'Delhi': [77.1025, 28.7041],
                'Bangalore': [77.5946, 12.9716],
                'Hyderabad': [78.4867, 17.3850],
                'Chennai': [80.2707, 13.0827],
                'Pune': [73.8567, 18.5204],
                'Ahmedabad': [72.5714, 23.0225]
            };

            const city = companyInfo.city;
            const coordinates = coords[city] || [77.5946, 12.9716];

            const company = await Company.create({
                user: companyUser._id,
                companyName: companyInfo.name,
                description: `${companyInfo.name} is a leading ${companyInfo.industry} company focused on innovation and excellence.`,
                tagline: `Transforming ${companyInfo.industry} through technology`,
                website: `https://${domain}.com`,
                email: `hr@${domain}.com`,
                phone: `+91 ${getRandomInt(80000, 99999)}${getRandomInt(10000, 99999)}`,
                industry: companyInfo.industry,
                companyType: companyInfo.type,
                companySize: companyInfo.size,
                foundedYear: getRandomInt(2005, 2022),
                location: {
                    city: city,
                    state: city === 'Mumbai' ? 'Maharashtra' : city === 'Bangalore' ? 'Karnataka' : 'India',
                    country: 'India',
                    coordinates: {
                        type: 'Point',
                        coordinates: coordinates
                    },
                    address: `${getRandomInt(1, 999)}, Tech Park, ${city}`
                },
                logoUrl: `https://ui-avatars.com/api/?name=${encodeURIComponent(companyInfo.name)}&size=200`,
                // Varying approval statuses
                isApproved: i < 15, // First 15 approved, last 5 pending
                isPendingReview: i >= 15,
                verificationStatus: i < 15 ? 'Verified' : 'Pending',
                approvedAt: i < 15 ? new Date(Date.now() - getRandomInt(1, 90) * 24 * 60 * 60 * 1000) : null,
                cin: `U${getRandomInt(10000, 99999)}MH${getRandomInt(2000, 2020)}PTC${getRandomInt(100000, 999999)}`,
                gstin: `27${getRandom(['AABCU', 'AADCV', 'AAECP'])}${getRandomInt(1000, 9999)}M1Z${getRandomInt(1, 9)}`,
                analytics: {
                    totalInternshipsPosted: getRandomInt(5, 50),
                    activeInternships: getRandomInt(1, 10),
                    totalApplicationsReceived: getRandomInt(10, 500),
                    totalHires: getRandomInt(2, 30),
                    profileViews: getRandomInt(100, 5000)
                }
            });
            companies.push(company);
        }
        console.log(`✓ Created ${companies.length} companies`);

        // ==================== CREATE STUDENTS ====================
        console.log('\n🎓 Creating 20 Students...');
        const studentUsers = [];
        const students = [];

        for (let i = 0; i < 20; i++) {
            const name = studentNames[i];
            const email = name.toLowerCase().replace(/\s+/g, '.') + '@gmail.com';

            const studentUser = await User.create({
                email: email,
                password: hashedPassword,
                role: 'student',
                isVerified: true
            });
            studentUsers.push(studentUser);

            // Random skill set (3-7 skills)
            const numSkills = getRandomInt(3, 7);
            const studentSkills = [];
            const usedSkills = new Set();

            for (let j = 0; j < numSkills; j++) {
                const skill = getRandom(skillsData);
                if (!usedSkills.has(skill.name)) {
                    studentSkills.push({
                        name: skill.name,
                        proficiency: getRandom(['Beginner', 'Intermediate', 'Advanced', 'Expert']),
                        yearsOfExperience: getRandomInt(0, 3)
                    });
                    usedSkills.add(skill.name);
                }
            }

            // Random education (1-2 entries)
            const education = [{
                institution: getRandom(universities),
                degree: getRandom(degrees).split(' ')[0],
                fieldOfStudy: getRandom(degrees).split(' ').slice(1).join(' '),
                startYear: getRandomInt(2019, 2022),
                endYear: getRandomInt(2023, 2025),
                cgpa: (Math.random() * 2 + 7).toFixed(2),
                isCurrentlyStudying: getRandomBool()
            }];

            // Random projects (0-3)
            const numProjects = getRandomInt(0, 3);
            const projects = [];
            for (let j = 0; j < numProjects; j++) {
                projects.push({
                    title: `${getRandom(['E-commerce', 'Social Media', 'Task Manager', 'Chat', 'Blog'])} ${getRandom(['Platform', 'Application', 'Website', 'App'])}`,
                    description: 'Built a full-featured application with modern tech stack',
                    technologies: studentSkills.slice(0, 3).map(s => s.name),
                    link: `https://github.com/${name.toLowerCase().replace(/\s+/g, '')}/project${j + 1}`,
                    startDate: new Date(Date.now() - getRandomInt(180, 365) * 24 * 60 * 60 * 1000),
                    endDate: new Date(Date.now() - getRandomInt(30, 180) * 24 * 60 * 60 * 1000)
                });
            }

            // Random certifications (0-2)
            const numCerts = getRandomInt(0, 2);
            const certifications = [];
            for (let j = 0; j < numCerts; j++) {
                certifications.push({
                    name: `${getRandom(['AWS', 'Google', 'Microsoft', 'Oracle'])} ${getRandom(['Cloud', 'Developer', 'Associate'])} Certification`,
                    issuingOrganization: getRandom(['AWS', 'Google', 'Microsoft', 'Oracle']),
                    issueDate: new Date(Date.now() - getRandomInt(30, 365) * 24 * 60 * 60 * 1000),
                    credentialUrl: 'https://certifications.example.com/verify'
                });
            }

            const city = getRandom(cities);
            const coords = {
                'Mumbai': [72.8777, 19.0760],
                'Delhi': [77.1025, 28.7041],
                'Bangalore': [77.5946, 12.9716],
                'Hyderabad': [78.4867, 17.3850],
                'Chennai': [80.2707, 13.0827],
                'Pune': [73.8567, 18.5204]
            };

            const student = await Student.create({
                user: studentUser._id,
                fullName: name,
                email: email,
                phone: `+91 ${getRandomInt(70000, 99999)}${getRandomInt(10000, 99999)}`,
                bio: `Passionate ${getRandom(degrees)} student with strong interest in ${studentSkills[0]?.name}. Looking for challenging opportunities to grow and contribute.`,
                dateOfBirth: new Date(2000 + getRandomInt(0, 5), getRandomInt(0, 11), getRandomInt(1, 28)),
                gender: getRandom(['Male', 'Female', 'Other']),
                profilePicture: `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&size=200`,
                education: education,
                university: education[0].institution,
                degree: education[0].degree,
                graduationYear: education[0].endYear,
                skills: studentSkills,
                interests: studentSkills.slice(0, 2).map(s => s.name),
                preferredDomains: [getRandom(['Web Development', 'Mobile Development', 'Data Science', 'AI', 'Cloud'])],
                location: {
                    city: city,
                    state: city === 'Mumbai' ? 'Maharashtra' : city === 'Bangalore' ? 'Karnataka' : 'India',
                    country: 'India',
                    coordinates: {
                        type: 'Point',
                        coordinates: coords[city] || [77.5946, 12.9716]
                    }
                },
                internshipPreferences: {
                    type: getRandom(['Remote', 'On-site', 'Hybrid', 'Any']),
                    minStipend: getRandomInt(5000, 20000),
                    maxStipend: getRandomInt(25000, 50000),
                    durationMonths: getRandomInt(3, 6),
                    locations: [city, 'Remote'],
                    isOpenToRelocate: getRandomBool()
                },
                availability: {
                    startDate: new Date(Date.now() + getRandomInt(0, 90) * 24 * 60 * 60 * 1000),
                    hoursPerWeek: getRandom([20, 30, 40]),
                    status: getRandom(['Available', 'Open to Offers'])
                },
                projects: projects,
                certifications: certifications,
                experience: numProjects > 1 ? [{
                    title: 'Intern',
                    company: getRandom(companyData).name,
                    location: city,
                    startDate: new Date(Date.now() - 180 * 24 * 60 * 60 * 1000),
                    endDate: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000),
                    duration: '3 months',
                    description: 'Worked on various development projects',
                    skills: studentSkills.slice(0, 2).map(s => s.name)
                }] : [],
                languages: [
                    { name: 'English', proficiency: 'Fluent' },
                    { name: 'Hindi', proficiency: getRandom(['Conversational', 'Fluent', 'Native']) }
                ],
                linkedin: `https://linkedin.com/in/${name.toLowerCase().replace(/\s+/g, '-')}`,
                github: `https://github.com/${name.toLowerCase().replace(/\s+/g, '')}`,
                resumeUrl: `/uploads/resumes/${name.toLowerCase().replace(/\s+/g, '_')}_resume.pdf`,
                resumeLastUpdated: new Date(Date.now() - getRandomInt(7, 90) * 24 * 60 * 60 * 1000),
                isEmailVerified: true,
                isPhoneVerified: getRandomBool(),
                totalApplications: getRandomInt(0, 10)
            });

            students.push(student);
        }
        console.log(`✓ Created ${students.length} students`);

        // ==================== CREATE INTERNSHIPS ====================
        console.log('\n💼 Creating Sample Internships...');
        const internships = [];

        const internshipTemplates = [
            {
                title: 'Full Stack Developer Intern',
                skills: ['React', 'Node.js', 'MongoDB'],
                domains: ['Web Development', 'Full Stack'],
                stipend: { min: 15000, max: 25000 }
            },
            {
                title: 'Data Science Intern',
                skills: ['Python', 'Machine Learning', 'Data Analysis'],
                domains: ['Data Science', 'AI'],
                stipend: { min: 20000, max: 35000 }
            },
            {
                title: 'Mobile App Developer',
                skills: ['Flutter', 'React Native'],
                domains: ['Mobile Development'],
                stipend: { min: 12000, max: 22000 }
            },
            {
                title: 'Frontend Developer',
                skills: ['React', 'JavaScript', 'TypeScript'],
                domains: ['Web Development'],
                stipend: { min: 10000, max: 20000 }
            },
            {
                title: 'Backend Developer',
                skills: ['Node.js', 'Python', 'PostgreSQL'],
                domains: ['Web Development'],
                stipend: { min: 15000, max: 25000 }
            },
            {
                title: 'UI/UX Design Intern',
                skills: ['Figma', 'UI/UX Design'],
                domains: ['Design'],
                stipend: { min: 8000, max: 18000 }
            },
            {
                title: 'DevOps Intern',
                skills: ['AWS', 'Docker'],
                domains: ['DevOps & Cloud'],
                stipend: { min: 18000, max: 30000 }
            },
            {
                title: 'Digital Marketing Intern',
                skills: ['Digital Marketing', 'SEO'],
                domains: ['Marketing'],
                stipend: { min: 5000, max: 15000 }
            }
        ];

        // Create 30 internships from approved companies
        for (let i = 0; i < 30; i++) {
            const company = companies[i % 15]; // Only from approved companies
            const template = internshipTemplates[i % internshipTemplates.length];

            const internship = await Internship.create({
                company: company._id,
                title: template.title,
                description: `We are looking for a talented ${template.title} to join our team. You will work on exciting projects and gain hands-on experience with cutting-edge technologies.`,
                shortDescription: `Join our team as ${template.title}. Exciting projects await!`,
                workMode: getRandom(['Remote', 'On-site', 'Hybrid']),
                requiredSkills: template.skills.map(skill => ({
                    name: skill,
                    level: getRandom(['Beginner', 'Intermediate', 'Advanced']),
                    isMandatory: true
                })),
                optionalSkills: [{
                    name: getRandom(['Git', 'Agile', 'Communication']),
                    level: 'Beginner'
                }],
                domains: template.domains,
                category: template.domains[0],
                tags: [...template.skills, ...template.domains],
                stipend: {
                    min: template.stipend.min,
                    max: template.stipend.max,
                    currency: 'INR',
                    period: 'Month',
                    isNegotiable: getRandomBool()
                },
                duration: {
                    value: getRandomInt(3, 6),
                    unit: 'Months',
                    displayString: `${getRandomInt(3, 6)} Months`
                },
                startDate: new Date(Date.now() + getRandomInt(7, 60) * 24 * 60 * 60 * 1000),
                isFlexibleStart: getRandomBool(),
                deadline: new Date(Date.now() + getRandomInt(15, 45) * 24 * 60 * 60 * 1000),
                location: company.location,
                openings: getRandomInt(1, 5),
                responsibilities: [
                    'Develop and maintain software applications',
                    'Collaborate with cross-functional teams',
                    'Participate in code reviews',
                    'Learn new technologies and best practices'
                ],
                perks: ['Certificate', 'Letter of Recommendation', 'Pre-Placement Offer opportunity'],
                isActive: i < 25, // 25 active, 5 inactive
                status: i < 25 ? 'Active' : 'Closed',
                isApproved: true
            });

            internships.push(internship);
        }
        console.log(`✓ Created ${internships.length} internships`);

        // ==================== CREATE APPLICATIONS ====================
        console.log('\n📝 Creating Sample Applications with Match Scores...');
        const { calculateMatchScore } = require('../utils/aiMatcher');

        const applications = [];
        const statuses = ['Applied', 'Shortlisted', 'Interview', 'Hired', 'Rejected'];

        // Create 50 random applications
        for (let i = 0; i < 50; i++) {
            const student = getRandom(students);
            const internship = getRandom(internships.filter(int => int.isActive));

            // Check if application already exists
            const existingApp = applications.find(app =>
                app.student.toString() === student._id.toString() &&
                app.internship.toString() === internship._id.toString()
            );

            if (existingApp) continue;

            // Calculate AI match score
            const matchResult = calculateMatchScore(student, internship);

            const status = getRandom(statuses);
            const timeline = [{
                status: 'Applied',
                timestamp: new Date(Date.now() - getRandomInt(1, 30) * 24 * 60 * 60 * 1000),
                note: 'Application submitted'
            }];

            if (status !== 'Applied') {
                timeline.push({
                    status: status,
                    timestamp: new Date(Date.now() - getRandomInt(1, 15) * 24 * 60 * 60 * 1000),
                    note: `Status changed to ${status}`
                });
            }

            const application = await Application.create({
                internship: internship._id,
                student: student._id,
                company: internship.company,
                status: status,
                matchScore: matchResult.overallScore,
                matchBreakdown: matchResult.breakdown,
                timeline: timeline,
                appliedAt: timeline[0].timestamp,
                coverLetter: `I am excited to apply for the ${internship.title} position. My skills in ${student.skills.slice(0, 2).map(s => s.name).join(' and ')} make me a great fit for this role.`,
                resumeUrl: student.resumeUrl
            });

            applications.push(application);
        }
        console.log(`✓ Created ${applications.length} applications`);

        // ==================== SUMMARY ====================
        console.log('\n✅ ========================================');
        console.log('   DATA SEEDING COMPLETED SUCCESSFULLY!');
        console.log('========================================');
        console.log(`\n📊 Summary:`);
        console.log(`   • Admins: 2`);
        console.log(`   • Companies: 20 (15 approved, 5 pending)`);
        console.log(`   • Students: 20`);
        console.log(`   • Skills: ${skills.length}`);
        console.log(`   • Internships: ${internships.length}`);
        console.log(`   • Applications: ${applications.length}`);

        console.log(`\n🔑 Login Credentials:`);
        console.log(`\n   ADMIN ACCOUNTS:`);
        console.log(`   • admin@skillmatch.com`);
        console.log(`   • superadmin@skillmatch.com`);

        console.log(`\n   COMPANY ACCOUNTS (Sample):`);
        companies.slice(0, 3).forEach(c => {
            console.log(`   • ${c.email} (${c.companyName})`);
        });

        console.log(`\n   STUDENT ACCOUNTS (Sample):`);
        students.slice(0, 3).forEach(s => {
            console.log(`   • ${s.email} (${s.fullName})`);
        });

        console.log(`\n   All passwords: password123`);
        console.log(`\n========================================\n`);

        process.exit(0);
    } catch (err) {
        console.error('\n✗ Error during seeding:', err);
        process.exit(1);
    }
};

seedData();
