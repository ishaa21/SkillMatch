const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Company = require('../models/Company');
const Student = require('../models/Student');
const Internship = require('../models/Internship');
const Application = require('../models/Application');

const connectDB = async () => {
    try {
        await mongoose.connect('mongodb://localhost:27017/internship_app', {
            useNewUrlParser: true,
            useUnifiedTopology: true,
        });
        console.log('MongoDB Connected for seeding...');
    } catch (err) {
        console.error('MongoDB connection error:', err);
        process.exit(1);
    }
};

const seedDatabase = async () => {
    try {
        await connectDB();

        // Clear existing data
        console.log('Clearing existing data...');
        await User.deleteMany({});
        await Company.deleteMany({});
        await Student.deleteMany({});
        await Internship.deleteMany({});
        await Application.deleteMany({});

        const hashedPassword = await bcrypt.hash('password123', 10);

        // Create Admin
        console.log('Creating admin user...');
        await User.create({
            email: 'admin@skillmatch.com',
            password: hashedPassword,
            role: 'admin',
            isVerified: true,
        });
        console.log('✓ Created admin user: admin@skillmatch.com / password123');

        // Create 5 Companies with Users
        console.log('Creating companies...');
        const companies = [];
        const companyData = [
            { name: 'TechCorp Solutions', industry: 'Technology', description: 'Leading software development company', location: 'Bangalore', website: 'techcorp.com' },
            { name: 'InnovateLab', industry: 'AI/ML', description: 'AI research and development', location: 'Hyderabad', website: 'innovatelab.com' },
            { name: 'CloudSys Inc', industry: 'Cloud Computing', description: 'Cloud infrastructure solutions', location: 'Mumbai', website: 'cloudsys.com' },
            { name: 'DataMinds Analytics', industry: 'Data Science', description: 'Data analytics and insights', location: 'Pune', website: 'dataminds.com' },
            { name: 'WebWizards', industry: 'Web Development', description: 'Full-stack web solutions', location: 'Delhi', website: 'webwizards.com' },
        ];

        for (let i = 0; i < companyData.length; i++) {
            // Create User first
            const user = await User.create({
                email: `company${i + 1}@test.com`,
                password: hashedPassword,
                role: 'company',
                isVerified: true,
            });

            // Create Company profile linked to User
            const company = await Company.create({
                user: user._id,
                companyName: companyData[i].name,
                industry: companyData[i].industry,
                description: companyData[i].description,
                location: companyData[i].location,
                website: companyData[i].website,
                isApproved: true,
            });
            companies.push(company);
        }
        console.log(`✓ Created ${companies.length} companies`);

        // Create 5 Students with Users
        console.log('Creating students...');
        const students = [];
        const studentData = [
            { name: 'Rahul Sharma', university: 'IIT Bombay', degree: 'B.Tech Computer Science', year: 2026, skills: ['JavaScript', 'React', 'Node.js', 'MongoDB', 'Python'] },
            { name: 'Priya Patel', university: 'IIT Delhi', degree: 'B.Tech Information Technology', year: 2025, skills: ['Java', 'Spring Boot', 'MySQL', 'AWS', 'Docker'] },
            { name: 'Amit Kumar', university: 'BITS Pilani', degree: 'B.Tech Electronics', year: 2026, skills: ['Python', 'Machine Learning', 'TensorFlow', 'Data Analysis', 'SQL'] },
            { name: 'Sneha Reddy', university: 'NIT Trichy', degree: 'B.Tech Computer Science', year: 2027, skills: ['C++', 'Python', 'Data Structures', 'Algorithms', 'Git'] },
            { name: 'Vikram Singh', university: 'VIT Vellore', degree: 'B.Tech Software Engineering', year: 2025, skills: ['Flutter', 'Dart', 'Firebase', 'React Native', 'UI/UX'] },
        ];

        for (let i = 0; i < studentData.length; i++) {
            // Create User first
            const user = await User.create({
                email: `student${i + 1}@test.com`,
                password: hashedPassword,
                role: 'student',
                isVerified: true,
            });

            // Create Student profile linked to User
            const student = await Student.create({
                user: user._id,
                fullName: studentData[i].name,
                university: studentData[i].university,
                degree: studentData[i].degree,
                graduationYear: studentData[i].year,
                skills: studentData[i].skills.map(skill => ({ name: skill, proficiency: 'Intermediate' })),
                phone: `+91-${8000000000 + i}`,
                resumeUrl: `resume_${i + 1}.pdf`,
            });
            students.push(student);
        }
        console.log(`✓ Created ${students.length} students`);

        // Create 10 Internships
        console.log('Creating internships...');
        const internships = [];
        const internshipData = [
            { title: 'Full Stack Developer Intern', type: 'Full-time', workMode: 'On-site', duration: '6 months', stipend: 25000, location: 'Bangalore', skills: ['React', 'Node.js', 'MongoDB'], description: 'Build scalable web applications', positions: 3 },
            { title: 'Machine Learning Intern', type: 'Part-time', workMode: 'Remote', duration: '3 months', stipend: 20000, location: 'Hyderabad', skills: ['Python', 'TensorFlow', 'Machine Learning'], description: 'Work on AI/ML projects', positions: 2 },
            { title: 'Cloud DevOps Intern', type: 'Full-time', workMode: 'Hybrid', duration: '6 months', stipend: 30000, location: 'Mumbai', skills: ['AWS', 'Docker', 'Kubernetes'], description: 'Manage cloud infrastructure', positions: 2 },
            { title: 'Data Analyst Intern', type: 'Part-time', workMode: 'Remote', duration: '4 months', stipend: 18000, location: 'Pune', skills: ['Python', 'SQL', 'Data Analysis'], description: 'Analyze business data', positions: 3 },
            { title: 'Frontend Developer Intern', type: 'Full-time', workMode: 'On-site', duration: '5 months', stipend: 22000, location: 'Delhi', skills: ['React', 'JavaScript', 'CSS'], description: 'Create responsive UIs', positions: 4 },
            { title: 'Mobile App Developer Intern', type: 'Full-time', workMode: 'Hybrid', duration: '6 months', stipend: 28000, location: 'Bangalore', skills: ['Flutter', 'Dart', 'Firebase'], description: 'Build cross-platform apps', positions: 2 },
            { title: 'Backend Developer Intern', type: 'Part-time', workMode: 'Remote', duration: '4 months', stipend: 23000, location: 'Mumbai', skills: ['Java', 'Spring Boot', 'MySQL'], description: 'Build robust APIs', positions: 3 },
            { title: 'Data Science Intern', type: 'Full-time', workMode: 'On-site', duration: '6 months', stipend: 32000, location: 'Bangalore', skills: ['Python', 'Machine Learning', 'Statistics'], description: 'Predictive modeling', positions: 2 },
            { title: 'UI/UX Design Intern', type: 'Part-time', workMode: 'Remote', duration: '3 months', stipend: 20000, location: 'Hyderabad', skills: ['Figma', 'Adobe XD', 'UI/UX'], description: 'Design user interfaces', positions: 2 },
            { title: 'Quality Assurance Intern', type: 'Full-time', workMode: 'On-site', duration: '3 months', stipend: 16000, location: 'Pune', skills: ['Testing', 'Selenium', 'Automation'], description: 'Test automation', positions: 3 },
        ];

        for (let i = 0; i < internshipData.length; i++) {
            const companyIndex = i % companies.length;
            const internship = await Internship.create({
                company: companies[companyIndex]._id,
                title: internshipData[i].title,
                description: internshipData[i].description,
                roleType: internshipData[i].type,
                workMode: internshipData[i].workMode,
                duration: internshipData[i].duration,
                stipend: {
                    amount: internshipData[i].stipend,
                    currency: 'INR',
                    period: 'Month'
                },
                location: internshipData[i].location,
                skillsRequired: internshipData[i].skills.map(s => ({ name: s, level: 'Intermediate' })),
                deadline: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
                isActive: true,
            });
            internships.push(internship);
        }
        console.log(`✓ Created ${internships.length} internships`);

        // Create Applications
        console.log('Creating applications...');
        const applications = [];
        let applicationCount = 0;

        for (const student of students) {
            const numApplications = Math.min(2, internships.length);

            for (let i = 0; i < numApplications; i++) {
                const randomInternship = internships[i % internships.length];

                // Calculate AI match score based on skill overlap
                const internshipSkills = randomInternship.skillsRequired || [];
                const studentSkills = student.skills.map(s => s.name.toLowerCase());
                const matchingSkills = internshipSkills.filter(skill => {
                    const skillName = (skill.name || '').toLowerCase();
                    return studentSkills.some(studentSkill =>
                        studentSkill.includes(skillName) || skillName.includes(studentSkill)
                    );
                });
                const matchScore = internshipSkills.length > 0
                    ? Math.min(95, Math.max(40, (matchingSkills.length / internshipSkills.length) * 100 + (Math.random() * 20 - 10)))
                    : 70;


                const statuses = ['Applied', 'Shortlisted', 'Rejected'];
                const status = applicationCount % 3 === 0 ? 'Shortlisted' : applicationCount % 5 === 0 ? 'Rejected' : 'Applied';

                const application = await Application.create({
                    internship: randomInternship._id,
                    student: student._id,
                    company: randomInternship.company,
                    status: status,
                    coverLetter: `I am very interested in the ${randomInternship.title} position. My skills make me a great fit for this role.`,
                });
                applications.push(application);
                applicationCount++;
            }
        }
        console.log(`✓ Created ${applications.length} applications`);

        console.log('\n✅ Database seeded successfully!');
        console.log('=================================');
        console.log(`Companies: ${companies.length}`);
        console.log(`Students: ${students.length}`);
        console.log(`Internships: ${internships.length}`);
        console.log(`Applications: ${applications.length}`);
        console.log('=================================\n');
        console.log('Login credentials:');
        console.log('Company: company1@test.com / password123');
        console.log('Student: student1@test.com / password123');
        console.log('(Use company1-5 or student1-5)');

        process.exit(0);
    } catch (error) {
        console.error('Error seeding database:', error);
        process.exit(1);
    }
};

seedDatabase();
