/**
 * AI Matching Engine with Jaccard Similarity for Internship Recommendations
 * 
 * Implements multi-factor scoring:
 * - Skills Matching (Jaccard Similarity): 40%
 * - Domain Interest: 20%
 * - Location Proximity: 15%
 * - Proficiency & Experience: 15%
 * - Logistics (Work Mode, Stipend): 10%
 */

// Proficiency level values for weighted matching
const PROFICIENCY_WEIGHTS = {
    'Beginner': 1,
    'Intermediate': 2,
    'Advanced': 3,
    'Expert': 4
};

// Default matching weights (sum to 100%)
const DEFAULT_WEIGHTS = {
    skills: 0.40,        // Jaccard similarity of skills
    domainInterest: 0.20,    // Domain & interest alignment
    location: 0.15,      // Geographic proximity
    proficiency: 0.15,   // Skill proficiency & experience
    logistics: 0.10      // Work mode & stipend match
};

/**
 * Helper: Safe division to prevent NaN/Infinity
 */
const safeDivide = (a, b) => {
    if (!b || b === 0) return 0;
    const result = a / b;
    return Number.isFinite(result) ? result : 0;
};

/**
 * Calculate Jaccard Similarity between two sets
 * Jaccard(A, B) = |A ∩ B| / |A ∪ B|
 * 
 * @param {Array} set1 - First set of items
 * @param {Array} set2 - Second set of items
 * @param {Function} keyFn - Function to extract key from items (default: identity)
 * @returns {Number} - Jaccard coefficient (0-1)
 */
const jaccardSimilarity = (set1, set2, keyFn = (x) => x) => {
    if (!set1 || !set2 || set1.length === 0 || set2.length === 0) {
        return 0;
    }

    const keys1 = set1.map(keyFn).map(k => (k || '').toString().toLowerCase().trim());
    const keys2 = set2.map(keyFn).map(k => (k || '').toString().toLowerCase().trim());

    const set1Unique = new Set(keys1);
    const set2Unique = new Set(keys2);

    // Intersection: items in both sets
    const intersection = [...set1Unique].filter(x => set2Unique.has(x));

    // Union: all unique items from both sets
    const union = new Set([...set1Unique, ...set2Unique]);

    return safeDivide(intersection.length, union.size);
};

/**
 * Calculate weighted skill match using Jaccard similarity + proficiency bonus
 * 
 * @param {Array} studentSkills - Student's skills [{name, proficiency, yearsOfExperience}]
 * @param {Array} requiredSkills - Internship required skills [{name, level, isMandatory}]
 * @returns {Object} - { jaccardScore, proficiencyBonus, finalScore }
 */
const calculateSkillsMatch = (studentSkills = [], requiredSkills = []) => {
    if (!requiredSkills || requiredSkills.length === 0) {
        return { jaccardScore: 0.5, proficiencyBonus: 0, finalScore: 50 }; // Neutral if no requirements
    }

    if (!studentSkills || studentSkills.length === 0) {
        return { jaccardScore: 0, proficiencyBonus: 0, finalScore: 0 };
    }

    // Jaccard similarity on skill names
    const jaccardScore = jaccardSimilarity(
        studentSkills,
        requiredSkills,
        skill => skill.name || skill
    );

    // Calculate proficiency bonus for matched skills
    let proficiencyBonus = 0;
    let matchedSkillsCount = 0;
    let mandatoryMatched = 0;
    let mandatoryTotal = requiredSkills.filter(s => s.isMandatory !== false).length;

    requiredSkills.forEach(reqSkill => {
        const reqName = (reqSkill.name || reqSkill || '').toString().toLowerCase().trim();
        const reqLevel = reqSkill.level || 'Intermediate';
        const isMandatory = reqSkill.isMandatory !== false;

        const studentSkill = studentSkills.find(
            s => (s.name || '').toString().toLowerCase().trim() === reqName
        );

        if (studentSkill) {
            matchedSkillsCount++;
            if (isMandatory) mandatoryMatched++;

            const studentLevel = studentSkill.proficiency || 'Beginner';
            const reqLevelValue = PROFICIENCY_WEIGHTS[reqLevel] || 2;
            const studentLevelValue = PROFICIENCY_WEIGHTS[studentLevel] || 1;

            // Proficiency bonus calculation
            if (studentLevelValue >= reqLevelValue) {
                // Meets or exceeds requirement
                proficiencyBonus += 0.15;
            } else if (studentLevelValue === reqLevelValue - 1) {
                // Close to requirement
                proficiencyBonus += 0.05;
            } else {
                // Below requirement
                proficiencyBonus -= 0.05;
            }

            // Years of experience bonus
            if (studentSkill.yearsOfExperience && studentSkill.yearsOfExperience >= 1) {
                proficiencyBonus += Math.min(0.1, studentSkill.yearsOfExperience * 0.02);
            }
        } else if (isMandatory) {
            // Missing mandatory skill - penalty
            proficiencyBonus -= 0.2;
        }
    });

    // Normalize proficiency bonus
    if (requiredSkills.length > 0) {
        proficiencyBonus = safeDivide(proficiencyBonus, requiredSkills.length);
    }

    // Mandatory skills penalty if not all matched
    let mandatoryPenalty = 0;
    if (mandatoryTotal > 0 && mandatoryMatched < mandatoryTotal) {
        mandatoryPenalty = safeDivide((mandatoryTotal - mandatoryMatched), mandatoryTotal) * 0.3;
    }

    // Final skills score (0-100)
    const finalScore = Math.max(0, Math.min(100, (jaccardScore + proficiencyBonus - mandatoryPenalty) * 100));

    return {
        jaccardScore,
        proficiencyBonus,
        mandatoryPenalty,
        matchedCount: matchedSkillsCount,
        totalRequired: requiredSkills.length,
        finalScore: Math.round(Number.isFinite(finalScore) ? finalScore : 0)
    };
};

/**
 * Calculate domain and interest alignment
 */
const calculateDomainMatch = (student, internship) => {
    const studentInterests = [
        ...(student.interests || []),
        ...(student.preferredDomains || [])
    ];

    const internshipDomains = internship.domains || [];
    const internshipTags = internship.tags || [];

    if (studentInterests.length === 0) {
        return 50; // Neutral score if no preferences
    }

    // Jaccard similarity for domains
    const domainJaccard = jaccardSimilarity(studentInterests, internshipDomains);

    // Check for keyword matches in title/description
    const titleLower = (internship.title || '').toLowerCase();
    const descLower = (internship.description || '').toLowerCase();

    let keywordMatches = 0;
    studentInterests.forEach(interest => {
        const interestLower = (interest || '').toLowerCase();
        if (interestLower && (titleLower.includes(interestLower) || descLower.includes(interestLower))) {
            keywordMatches++;
        }
    });

    const keywordScore = safeDivide(keywordMatches, studentInterests.length);

    // Tags similarity
    const tagsJaccard = internshipTags.length > 0 ?
        jaccardSimilarity(studentInterests, internshipTags) : 0;

    // Weighted combination
    const finalScore = (domainJaccard * 0.5 + keywordScore * 0.3 + tagsJaccard * 0.2) * 100;

    return Math.round(Number.isFinite(finalScore) ? finalScore : 0);
};

/**
 * Calculate location proximity match
 * Uses Haversine formula for coordinate-based distance if available
 */
const calculateLocationMatch = (student, internship) => {
    // Remote work = perfect match
    if (internship.workMode === 'Remote' || internship.location?.isRemote) return 100;

    // Check if student is open to relocate
    if (student.internshipPreferences?.isOpenToRelocate) return 75;

    // City/State exact match
    const studentCity = (student.location?.city || '').toLowerCase();
    const studentState = (student.location?.state || '').toLowerCase();
    const internCity = (internship.location?.city || '').toLowerCase();
    const internState = (internship.location?.state || '').toLowerCase();

    if (studentCity && internCity && studentCity === internCity) return 100;
    if (studentState && internState && studentState === internState) return 70;

    return 30; // Default
};

/**
 * Haversine distance calculation (returns distance in km)
 */
const calculateHaversineDistance = (coords1, coords2) => {
    const [lon1, lat1] = coords1; // MongoDB stores [longitude, latitude]
    const [lon2, lat2] = coords2;

    const R = 6371; // Earth's radius in km
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);

    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c;

    return distance;
};

const toRad = (degrees) => degrees * (Math.PI / 180);

/**
 * Calculate proficiency and experience match
 */
const calculateProficiencyMatch = (student, internship) => {
    let score = 50; // Base score

    if (internship.requirements?.education) {
        const reqDegree = internship.requirements.education.degree;
        const studentDegree = student.degree;

        if (reqDegree && studentDegree) {
            if (studentDegree.toLowerCase().includes(reqDegree.toLowerCase())) {
                score += 20;
            }
        }
    }

    // Experience requirement match
    if (internship.requirements?.experience) {
        const minExpRequired = internship.requirements.experience.min || 0;
        const studentExpYears = (student.experience || []).length;

        if (studentExpYears >= minExpRequired) {
            score += 15;
        } else if (!internship.requirements.experience.isRequired) {
            score += 10;
        }
    } else {
        score += 15;
    }

    // Use field match logic from original if complex, or simplify
    return Math.min(100, Math.round(score));
};

/**
 * Calculate logistics match (work mode & stipend)
 */
const calculateLogisticsMatch = (student, internship) => {
    let score = 0;

    // Work Mode
    const studentPrefType = student.internshipPreferences?.type;
    const internWorkMode = internship.workMode;

    if (!studentPrefType || studentPrefType === 'Any' || studentPrefType === internWorkMode) {
        score += 50;
    } else if (internWorkMode === 'Remote') {
        score += 40;
    } else {
        score += 20;
    }

    // Stipend
    const minStipendExpected = student.internshipPreferences?.minStipend || 0;
    const internStipendMax = internship.stipend?.max || internship.stipend?.amount || 0;

    if (internStipendMax >= minStipendExpected) {
        score += 50;
    } else {
        score += 20;
    }

    return Math.min(100, Math.round(score));
};

/**
 * Main function: Calculate comprehensive match score for student-internship pair
 * 
 * @param {Object} student - Student profile
 * @param {Object} internship - Internship posting
 * @param {Object} customWeights - Optional custom weights
 * @returns {Object} - Complete match breakdown with overall score
 */
const calculateMatchScore = (student, internship, customWeights = null) => {
    const weights = customWeights || DEFAULT_WEIGHTS;

    // Check if total weights are valid
    const totalWeight = (weights.skills || 0) + (weights.domainInterest || 0) +
        (weights.location || 0) + (weights.proficiency || 0) +
        (weights.logistics || 0);

    if (totalWeight <= 0) {
        return { overallScore: 0, breakdown: {} };
    }

    // Calculate individual component scores
    const skillsMatch = calculateSkillsMatch(
        student.skills,
        internship.requiredSkills || internship.skillsRequired
    );

    const domainScore = calculateDomainMatch(student, internship);
    const locationScore = calculateLocationMatch(student, internship);
    const proficiencyScore = calculateProficiencyMatch(student, internship);
    const logisticsScore = calculateLogisticsMatch(student, internship);

    // Calculate weighted overall score
    let overallScore = skillsMatch.finalScore * (weights.skills || 0) +
        domainScore * (weights.domainInterest || 0) +
        locationScore * (weights.location || 0) +
        proficiencyScore * (weights.proficiency || 0) +
        logisticsScore * (weights.logistics || 0);

    // Final Normalize by total weight (usually 1.0 but just in case)
    overallScore = safeDivide(overallScore, totalWeight);

    // Sanitize Score
    if (!Number.isFinite(overallScore) || Number.isNaN(overallScore)) {
        overallScore = 0;
    }

    return {
        overallScore: Math.min(100, Math.max(0, Math.round(overallScore))),
        breakdown: {
            skills: {
                score: skillsMatch.finalScore,
                weight: weights.skills || 0,
                jaccardSimilarity: skillsMatch.jaccardScore,
                matchedSkills: skillsMatch.matchedCount,
                totalRequired: skillsMatch.totalRequired
            },
            domainInterest: {
                score: domainScore,
                weight: weights.domainInterest || 0
            },
            location: {
                score: locationScore,
                weight: weights.location || 0
            },
            proficiency: {
                score: proficiencyScore,
                weight: weights.proficiency || 0
            },
            logistics: {
                score: logisticsScore,
                weight: weights.logistics || 0
            }
        }
    };
};

/**
 * Rank all internships for a student by match score
 * 
 * @param {Object} student - Student profile
 * @param {Array} internships - Array of internship postings
 * @param {Object} customWeights - Optional custom weights
 * @param {Number} minScore - Minimum match score threshold (default: 0)
 * @returns {Array} - Sorted array of internships with match scores
 */
const rankInternshipsForStudent = (student, internships, customWeights = null, minScore = 0) => {
    const rankedInternships = internships.map(internship => {
        const internObj = internship.toObject ? internship.toObject() : internship;
        const matchResult = calculateMatchScore(student, internObj, customWeights);

        return {
            ...internObj,
            matchScore: matchResult.overallScore,
            matchPercentage: matchResult.overallScore, // Legacy compatibility
            matchBreakdown: matchResult.breakdown
        };
    });

    // Filter by minimum score and sort descending
    return rankedInternships
        .filter(intern => intern.matchScore >= minScore)
        .sort((a, b) => b.matchScore - a.matchScore);
};

/**
 * Rank applicants for an internship by match score
 * 
 * @param {Object} internship - Internship posting
 * @param {Array} students - Array of student profiles
 * @param {Object} customWeights - Optional custom weights
 * @param {Number} minScore - Minimum match score threshold
 * @returns {Array} - Sorted array of students with match scores
 */
const rankApplicantsForInternship = (internship, students, customWeights = null, minScore = 0) => {
    const rankedApplicants = students.map(student => {
        const studentObj = student.toObject ? student.toObject() : student;
        const matchResult = calculateMatchScore(studentObj, internship, customWeights);

        return {
            ...studentObj,
            matchScore: matchResult.overallScore,
            matchBreakdown: matchResult.breakdown
        };
    });

    return rankedApplicants
        .filter(applicant => applicant.matchScore >= minScore)
        .sort((a, b) => b.matchScore - a.matchScore);
};

// Exports
module.exports = {
    calculateMatchScore,
    rankInternshipsForStudent,
    rankApplicantsForInternship,
    jaccardSimilarity,
    calculateSkillsMatch,
    DEFAULT_WEIGHTS,
    PROFICIENCY_WEIGHTS
};
