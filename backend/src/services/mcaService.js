/**
 * Mock MCA Service
 * Simulates fetching company details from Ministry of Corporate Affairs (MCA) API.
 * Uses realistic latency and response structures suitable for production interface.
 */

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

exports.fetchCompanyDetails = async (cin) => {
    console.log(`[Mock MCA] Fetching details for CIN: ${cin}`);

    // Simulate network latency (1-2 seconds)
    await delay(1000 + Math.random() * 1000);

    // Mock Logic based on CIN patterns

    // Case 1: Valid Active Company (starts with L)
    // Example: L12345MH2023PLC123456
    if (cin.startsWith('L') || cin.startsWith('l')) {
        return {
            success: true,
            data: {
                cin: cin.toUpperCase(),
                companyName: 'TechSolutions India Ltd',
                roc: 'RoC-Mumbai',
                registrationNumber: cin.slice(-6),
                status: 'Active',
                incorporationDate: '2010-01-15',
                category: 'Company limited by Shares',
                class: 'Public',
                authorizedCapital: '10,00,000',
                paidUpCapital: '5,00,000',
                address: '123, Tech Park, Mumbai, Maharashtra'
            }
        };
    }

    // Case 2: Struck Off / Inactive Company (starts with U9)
    // Example: U99999MH2020PTC123456
    if (cin.startsWith('U9') || cin.startsWith('u9')) {
        return {
            success: true,
            data: {
                cin: cin.toUpperCase(),
                companyName: 'Fake Shell Company Pvt Ltd',
                roc: 'RoC-Delhi',
                status: 'Strike Off', // or 'Dormant'
                incorporationDate: '2020-05-20',
                address: 'Null Void Street, Delhi'
            }
        };
    }

    // Case 3: Invalid CIN or Not Found (any other pattern)
    return {
        success: false,
        error: {
            code: 'RECORD_NOT_FOUND',
            message: 'No company found with the provided CIN.'
        }
    };
};
