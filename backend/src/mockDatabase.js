const bcrypt = require('bcryptjs');

// Mock Database - Simulates MongoDB collections in memory
const mockDB = {
    users: [],
    students: [],
    companies: [],
    internships: [],
    applications: []
};

// Generate mock IDs
let idCounter = 100;
const generateId = () => (idCounter++).toString();

// Initialize with seed data
const initializeMockData = async () => {
    const hashedPassword = await bcrypt.hash('password123', 10);

    // Create Company User 1
    const companyUser1 = {
        _id: generateId(),
        email: 'company@test.com',
        password: hashedPassword,
        role: 'company',
        isVerified: true
    };
    mockDB.users.push(companyUser1);

    const company1 = {
        _id: generateId(),
        user: companyUser1._id,
        companyName: 'Tech Innovators Inc.',
        description: 'Leading the way in AI and Web Development solutions.',
        industry: 'Technology',
        location: 'San Francisco, CA',
        isApproved: true,
        logoUrl: 'https://via.placeholder.com/150'
    };
    mockDB.companies.push(company1);

    // Create Company User 2
    const companyUser2 = {
        _id: generateId(),
        email: 'design@test.com',
        password: hashedPassword,
        role: 'company',
        isVerified: true
    };
    mockDB.users.push(companyUser2);

    const company2 = {
        _id: generateId(),
        user: companyUser2._id,
        companyName: 'Creative Minds Studio',
        description: 'We craft beautiful digital experiences.',
        industry: 'Design',
        location: 'New York, NY',
        isApproved: true,
        logoUrl: 'https://via.placeholder.com/150'
    };
    mockDB.companies.push(company2);

    // Create Student User 1
    const studentUser1 = {
        _id: generateId(),
        email: 'student@test.com',
        password: hashedPassword,
        role: 'student',
        isVerified: true
    };
    mockDB.users.push(studentUser1);

    const student1 = {
        _id: generateId(),
        user: studentUser1._id,
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
    };
    mockDB.students.push(student1);

    // Create Student User 2
    const studentUser2 = {
        _id: generateId(),
        email: 'alice@test.com',
        password: hashedPassword,
        role: 'student',
        isVerified: true
    };
    mockDB.users.push(studentUser2);

    const student2 = {
        _id: generateId(),
        user: studentUser2._id,
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
    };
    mockDB.students.push(student2);

    // Create Internships
    const internship1 = {
        _id: generateId(),
        company: company1._id,
        title: 'React Frontend Developer Intern',
        description: 'Looking for a passionate React developer to build modern web interfaces. Must know Hooks and Redux.',
        workMode: 'Remote',
        skillsRequired: ['React', 'JavaScript', 'CSS'],
        stipend: { amount: 1000, currency: 'USD', period: 'Month' },
        duration: '3 Months',
        location: 'Remote',
        isActive: true,
        createdAt: new Date()
    };
    mockDB.internships.push(internship1);

    const internship2 = {
        _id: generateId(),
        company: company1._id,
        title: 'Backend Node.js Developer',
        description: 'Help us scale our API services using Node.js and MongoDB.',
        workMode: 'On-site',
        skillsRequired: ['Node.js', 'MongoDB', 'Express'],
        stipend: { amount: 1200, currency: 'USD', period: 'Month' },
        duration: '6 Months',
        location: 'San Francisco, CA',
        isActive: true,
        createdAt: new Date()
    };
    mockDB.internships.push(internship2);

    const internship3 = {
        _id: generateId(),
        company: company2._id,
        title: 'UI/UX Design Intern',
        description: 'Create stunning user interfaces for mobile and web apps.',
        workMode: 'Hybrid',
        skillsRequired: ['Figma', 'UI Design', 'Prototyping'],
        stipend: { amount: 800, currency: 'USD', period: 'Month' },
        duration: '3 Months',
        location: 'New York, NY',
        isActive: true,
        createdAt: new Date()
    };
    mockDB.internships.push(internship3);

    // Create Applications
    const application1 = {
        _id: generateId(),
        student: student1._id,
        internship: internship1._id,
        company: company1._id,
        status: 'Applied',
        coverLetter: 'I love React and have built several projects.',
        resumeUrl: student1.resumeUrl,
        createdAt: new Date()
    };
    mockDB.applications.push(application1);

    const application2 = {
        _id: generateId(),
        student: student1._id,
        internship: internship2._id,
        company: company1._id,
        status: 'Shortlisted',
        coverLetter: 'I am also good at backend.',
        resumeUrl: student1.resumeUrl,
        createdAt: new Date()
    };
    mockDB.applications.push(application2);

    const application3 = {
        _id: generateId(),
        student: student2._id,
        internship: internship3._id,
        company: company2._id,
        status: 'Applied',
        coverLetter: 'Check out my portfolio!',
        resumeUrl: 'https://alice.design/portfolio',
        createdAt: new Date()
    };
    mockDB.applications.push(application3);

    console.log('✅ Mock database initialized with sample data!');
    console.log(`   Users: ${mockDB.users.length}`);
    console.log(`   Companies: ${mockDB.companies.length}`);
    console.log(`   Students: ${mockDB.students.length}`);
    console.log(`   Internships: ${mockDB.internships.length}`);
    console.log(`   Applications: ${mockDB.applications.length}`);
};

// Helper functions to simulate Mongoose operations
const mockHelpers = {
    // Find one document
    findOne: (collection, query) => {
        return mockDB[collection].find(item => {
            return Object.keys(query).every(key => {
                if (key === 'user' && query[key].id) {
                    return item[key] === query[key].id;
                }
                return item[key] === query[key];
            });
        });
    },

    // Find multiple documents
    find: (collection, query = {}) => {
        if (Object.keys(query).length === 0) {
            return mockDB[collection];
        }
        return mockDB[collection].filter(item => {
            return Object.keys(query).every(key => item[key] === query[key]);
        });
    },

    // Find by ID
    findById: (collection, id) => {
        return mockDB[collection].find(item => item._id === id);
    },

    // Create document
    create: (collection, data) => {
        const newDoc = {
            _id: generateId(),
            ...data,
            createdAt: new Date(),
            toObject: function () { return this; }
        };
        mockDB[collection].push(newDoc);
        return newDoc;
    },

    // Update document
    findByIdAndUpdate: (collection, id, update, options = {}) => {
        const index = mockDB[collection].findIndex(item => item._id === id);
        if (index !== -1) {
            mockDB[collection][index] = {
                ...mockDB[collection][index],
                ...update.$set,
                updatedAt: new Date()
            };
            return mockDB[collection][index];
        }
        return null;
    },

    // Delete document
    findByIdAndDelete: (collection, id) => {
        const index = mockDB[collection].findIndex(item => item._id === id);
        if (index !== -1) {
            const deleted = mockDB[collection][index];
            mockDB[collection].splice(index, 1);
            return deleted;
        }
        return null;
    },

    // Populate (simple version)
    populate: (doc, populatePath, fields) => {
        if (!doc) return doc;

        const isArray = Array.isArray(doc);
        const docs = isArray ? doc : [doc];

        docs.forEach(item => {
            const [path, collection] = {
                'company': ['company', 'companies'],
                'student': ['student', 'students'],
                'internship': ['internship', 'internships'],
                'user': ['user', 'users']
            }[populatePath] || [];

            if (path && item[path]) {
                const populated = mockDB[collection].find(c => c._id === item[path]);
                if (populated) {
                    if (fields) {
                        const fieldList = fields.split(' ');
                        item[path] = {};
                        fieldList.forEach(f => {
                            item[path][f] = populated[f];
                        });
                        item[path]._id = populated._id;
                    } else {
                        item[path] = populated;
                    }
                }
            }
        });

        return isArray ? docs : docs[0];
    }
};

module.exports = { mockDB, mockHelpers, initializeMockData };
