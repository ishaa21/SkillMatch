const bcrypt = require('bcryptjs');

// In-memory storage
const mockUsers = new Map();
const mockCompanies = new Map();
const mockStudents = new Map();
const mockInternships = new Map();
const mockApplications = new Map();

// Helper to generate IDs
const generateId = (prefix) => `${prefix}_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

// Pre-populate with demo accounts
const initMockData = async () => {
    if (mockUsers.size > 0) return; // Prevent double init

    const hashedPassword = await bcrypt.hash('password123', 10);

    // Add ADMIN account
    const adminId = 'admin_001';
    mockUsers.set('admin@internship.com', {
        _id: adminId,
        email: 'admin@internship.com',
        password: hashedPassword,
        role: 'admin'
    });

    // Add 20 Companies
    const companyNames = ['TechCorp', 'InnovateLab', 'CloudSys', 'DataMinds', 'WebWizards', 'AI Solutions', 'DevOps Pro', 'CodeFactory', 'StartupHub', 'FinTech Global', 'HealthTech', 'EduTech', 'GameDev Studio', 'CyberSec', 'BlockChain Inc', 'IoT Innovations', 'RoboTech', 'GreenEnergy', 'SpaceTech', 'BioTech Labs'];
    const industries = ['Technology', 'AI/ML', 'Cloud Computing', 'Data Science', 'Web Development', 'FinTech', 'HealthTech', 'EdTech', 'Gaming', 'Cybersecurity'];
    const locations = ['Bangalore', 'Mumbai', 'Delhi', 'Hyderabad', 'Pune', 'Chennai', 'Kolkata', 'Ahmedabad'];

    for (let i = 1; i <= 20; i++) {
        const userId = `company${i}`;
        mockUsers.set(`company${i}@test.com`, {
            _id: userId,
            email: `company${i}@test.com`,
            password: hashedPassword,
            role: 'company'
        });
        mockCompanies.set(userId, {
            _id: userId,
            user: userId,
            companyName: companyNames[i - 1] || `Company ${i}`,
            industry: industries[i % industries.length],
            location: locations[i % locations.length],
            description: `Leading ${industries[i % industries.length]} company`,
            website: `www.${companyNames[i - 1]?.toLowerCase().replace(' ', '')}.com`,
            isApproved: true
        });
    }

    // Add 20 Students
    const firstNames = ['Rahul', 'Priya', 'Amit', 'Sneha', 'Vikram', 'Ananya', 'Rohan', 'Kavya', 'Arjun', 'Diya', 'Karan', 'Ishita', 'Aditya', 'Riya', 'Siddharth', 'Meera', 'Varun', 'Nisha', 'Dev', 'Pooja'];
    const lastNames = ['Sharma', 'Patel', 'Kumar', 'Reddy', 'Singh', 'Gupta', 'Verma', 'Joshi', 'Nair', 'Iyer'];
    const universities = ['IIT Bombay', 'IIT Delhi', 'BITS Pilani', 'NIT Trichy', 'VIT Vellore', 'IIT Madras', 'IIT Kanpur', 'NIT Surathkal', 'IIIT Hyderabad', 'DTU Delhi'];
    const degrees = ['B.Tech Computer Science', 'B.Tech IT', 'B.Tech Electronics', 'B.Tech Software Engineering', 'B.Tech AI/ML'];
    const skillSets = [
        ['JavaScript', 'React', 'Node.js', 'MongoDB', 'Python'],
        ['Java', 'Spring Boot', 'MySQL', 'AWS', 'Docker'],
        ['Python', 'Machine Learning', 'TensorFlow', 'Data Analysis', 'SQL'],
        ['C++', 'Python', 'Data Structures', 'Algorithms', 'Git'],
        ['Flutter', 'Dart', 'Firebase', 'React Native', 'UI/UX'],
        ['Angular', 'TypeScript', 'PostgreSQL', 'GraphQL', 'Redis'],
        ['Vue.js', 'Express', 'MongoDB', 'Docker', 'Kubernetes'],
        ['React', 'Redux', 'Next.js', 'Tailwind', 'TypeScript'],
        ['Python', 'Django', 'FastAPI', 'PostgreSQL', 'Celery'],
        ['Go', 'Microservices', 'gRPC', 'Kafka', 'Kubernetes']
    ];

    for (let i = 1; i <= 20; i++) {
        const userId = `student${i}`;
        mockUsers.set(`student${i}@test.com`, {
            _id: userId,
            email: `student${i}@test.com`,
            password: hashedPassword,
            role: 'student'
        });
        mockStudents.set(userId, {
            _id: userId,
            user: userId,
            fullName: `${firstNames[i - 1]} ${lastNames[i % lastNames.length]}`,
            university: universities[i % universities.length],
            degree: degrees[i % degrees.length],
            graduationYear: 2025 + (i % 3),
            skills: skillSets[i % skillSets.length].map(skill => ({ name: skill, proficiency: 'Intermediate' })),
            phone: `+91-${8000000000 + i}`,
            resumeUrl: `resume_${i}.pdf`
        });
    }

    // Add 30 Internships
    const internshipTitles = [
        'Full Stack Developer', 'Machine Learning Engineer', 'Cloud DevOps Engineer', 'Data Analyst', 'Frontend Developer',
        'Mobile App Developer', 'Backend Developer', 'Data Scientist', 'UI/UX Designer', 'QA Engineer',
        'Blockchain Developer', 'Cybersecurity Analyst', 'Game Developer', 'AI Research Intern', 'Product Manager Intern',
        'Digital Marketing Intern', 'Business Analyst', 'IoT Developer', 'AR/VR Developer', 'Site Reliability Engineer',
        'Database Administrator', 'Network Engineer', 'Cloud Architect', 'ML Ops Engineer', 'React Native Developer',
        'Flutter Developer', 'Python Developer', 'Java Developer', 'DevSecOps Engineer', 'Technical Writer'
    ];
    const types = ['Full-time', 'Part-time'];
    const durations = ['3 months', '4 months', '5 months', '6 months'];

    for (let i = 1; i <= 30; i++) {
        const internshipId = `internship${i}`;
        const companyId = `company${((i - 1) % 20) + 1}`;
        mockInternships.set(internshipId, {
            _id: internshipId,
            company: companyId,
            title: internshipTitles[i - 1],
            description: `Work on exciting ${internshipTitles[i - 1]} projects`,
            type: types[i % 2],
            duration: durations[i % 4],
            stipend: { amount: 15000 + (i * 1000) },
            location: locations[i % locations.length],
            requiredSkills: skillSets[i % skillSets.length].slice(0, 3),
            openings: (i % 5) + 1,
            applicationDeadline: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
            isActive: true
        });
    }

    // Add 50 Applications
    let appId = 1;
    for (let studentNum = 1; studentNum <= 20; studentNum++) {
        const numApps = studentNum <= 10 ? 3 : 2;
        for (let j = 0; j < numApps && appId <= 50; j++) {
            const applicationId = `application${appId}`;
            const internshipNum = ((appId - 1) % 30) + 1;
            const internshipId = `internship${internshipNum}`;
            const internship = mockInternships.get(internshipId);
            const student = mockStudents.get(`student${studentNum}`);

            const internshipSkills = internship.requiredSkills || [];
            const studentSkills = student.skills.map(s => s.name.toLowerCase());
            const matchingSkills = internshipSkills.filter(skill =>
                studentSkills.some(studentSkill => studentSkill.includes(skill.toLowerCase()) || skill.toLowerCase().includes(studentSkill))
            );
            const matchScore = internshipSkills.length > 0
                ? Math.min(95, Math.max(40, (matchingSkills.length / internshipSkills.length) * 100 + (Math.random() * 20 - 10)))
                : 70;

            const statuses = ['Pending', 'Shortlisted', 'Rejected', 'Hired'];
            const status = appId % 4 === 0 ? 'Shortlisted' : appId % 7 === 0 ? 'Hired' : appId % 5 === 0 ? 'Rejected' : 'Pending';

            mockApplications.set(applicationId, {
                _id: applicationId,
                internship: internshipId,
                student: `student${studentNum}`,
                company: internship.company,
                status: status,
                aiMatchScore: Math.round(matchScore),
                coverLetter: `I am very interested in the ${internship.title} position. My skills make me a great fit for this role.`,
                appliedAt: new Date(Date.now() - (appId * 24 * 60 * 60 * 1000))
            });
            appId++;
        }
    }

    console.log('✅ Shared Mock Data Store Initialized');
};

module.exports = {
    mockUsers,
    mockCompanies,
    mockStudents,
    mockInternships,
    mockApplications,
    initMockData,
    generateId
};
