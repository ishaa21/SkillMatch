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

    const keys1 = set1.map(keyFn).map(k => k.toLowerCase().trim());
    const keys2 = set2.map(keyFn).map(k => k.toLowerCase().trim());

    const set1Unique = new Set(keys1);
    const set2Unique = new Set(keys2);

    // Intersection: items in both sets
    const intersection = [...set1Unique].filter(x => set2Unique.has(x));

    // Union: all unique items from both sets
    const union = new Set([...set1Unique, ...set2Unique]);

    return intersection.length / union.size;
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
        const reqName = (reqSkill.name || reqSkill).toLowerCase().trim();
        const reqLevel = reqSkill.level || 'Intermediate';
        const isMandatory = reqSkill.isMandatory !== false;

        const studentSkill = studentSkills.find(
            s => (s.name || '').toLowerCase().trim() === reqName
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
        proficiencyBonus = proficiencyBonus / requiredSkills.length;
    }

    // Mandatory skills penalty if not all matched
    let mandatoryPenalty = 0;
    if (mandatoryTotal > 0 && mandatoryMatched < mandatoryTotal) {
        mandatoryPenalty = (mandatoryTotal - mandatoryMatched) / mandatoryTotal * 0.3;
    }

    // Final skills score (0-100)
    const finalScore = Math.max(0, Math.min(100, (jaccardScore + proficiencyBonus - mandatoryPenalty) * 100));

    return {
        jaccardScore,
        proficiencyBonus,
        mandatoryPenalty,
        matchedCount: matchedSkillsCount,
        totalRequired: requiredSkills.length,
        finalScore: Math.round(finalScore)
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
        const interestLower = interest.toLowerCase();
        if (titleLower.includes(interestLower) || descLower.includes(interestLower)) {
            keywordMatches++;
        }
    });

    const keywordScore = keywordMatches / studentInterests.length;

    // Tags similarity
    const tagsJaccard = internshipTags.length > 0 ?
        jaccardSimilarity(studentInterests, internshipTags) : 0;

    // Weighted combination
    const finalScore = (domainJaccard * 0.5 + keywordScore * 0.3 + tagsJaccard * 0.2) * 100;

    return Math.round(finalScore);
};

/**
 * Calculate location proximity match
 * Uses Haversine formula for coordinate-based distance if available
 */
const calculateLocationMatch = (student, internship) => {
    // Remote work = perfect match
    if (internship.workMode === 'Remote' || internship.location?.isRemote) {
        return 100;
    }

    // Check if student is open to relocate
    if (student.internshipPreferences?.isOpenToRelocate) {
        return 75; // Good match if willing to relocate
    }

    // City/State exact match
    const studentCity = student.location?.city?.toLowerCase();
    const studentState = student.location?.state?.toLowerCase();
    const internCity = internship.location?.city?.toLowerCase();
    const internState = internship.location?.state?.toLowerCase();

    if (studentCity && internCity && studentCity === internCity) {
        return 100; // Same city
    }

    if (studentState && internState && studentState === internState) {
        return 70; // Same state
    }

    // Check preferred locations
    const preferredLocations = (student.internshipPreferences?.locations || [])
        .map(loc => loc.toLowerCase());

    if (preferredLocations.length > 0) {
        if (preferredLocations.includes(internCity)) {
            return 100;
        }
        if (preferredLocations.includes(internState)) {
            return 75;
        }
    }

    // Coordinate-based distance calculation (if available)
    if (student.location?.coordinates?.coordinates &&
        internship.location?.coordinates?.coordinates) {
        const distance = calculateHaversineDistance(
            student.location.coordinates.coordinates,
            internship.location.coordinates.coordinates
        );

        // Distance-based scoring (in km)
        if (distance < 10) return 100;
        if (distance < 50) return 80;
        if (distance < 100) return 60;
        if (distance < 300) return 40;
        return 20;
    }

    // Default: no location match
    return 30; // Slight match as it's still in India
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

    // Education requirement match
    if (internship.requirements?.education) {
        const reqDegree = internship.requirements.education.degree;
        const studentDegree = student.degree;

        if (reqDegree && studentDegree) {
            if (studentDegree.toLowerCase().includes(reqDegree.toLowerCase())) {
                score += 20;
            }
        }

        // Field of study match
        const reqFields = internship.requirements.education.field || [];
        if (reqFields.length > 0 && student.education && student.education.length > 0) {
            const studentFields = student.education.map(e => e.fieldOfStudy || '');
            const fieldMatch = jaccardSimilarity(studentFields, reqFields);
            score += fieldMatch * 15;
        }
    }

    // Experience requirement match
    if (internship.requirements?.experience) {
        const minExpRequired = internship.requirements.experience.min || 0;
        const studentExpYears = (student.experience || []).length; // Simplified: count of experiences

        if (studentExpYears >= minExpRequired) {
            score += 15;
        } else if (!internship.requirements.experience.isRequired) {
            score += 10; // Not critical
        }
    } else {
        score += 15; // No experience required
    }

    return Math.min(100, Math.round(score));
};

/**
 * Calculate logistics match (work mode & stipend)
 */
const calculateLogisticsMatch = (student, internship) => {
    let score = 0;

    // Work mode preference
    const studentPrefType = student.internshipPreferences?.type;
    const internWorkMode = internship.workMode;

    if (!studentPrefType || studentPrefType === 'Any') {
        score += 50;
    } else if (studentPrefType === internWorkMode) {
        score += 50;
    } else if (studentPrefType === 'Hybrid' && (internWorkMode === 'Remote' || internWorkMode === 'On-site')) {
        score += 35;
    } else if (internWorkMode === 'Remote') {
        score += 40; // Remote is generally flexible
    } else {
        score += 20; // Mismatch
    }

    // Stipend expectation
    const minStipendExpected = student.internshipPreferences?.minStipend || 0;
    const maxStipendExpected = student.internshipPreferences?.maxStipend || Infinity;
    const internStipendMin = internship.stipend?.min || internship.stipend?.amount || 0;
    const internStipendMax = internship.stipend?.max || internStipendMin;

    if (internStipendMax >= minStipendExpected && internStipendMin <= maxStipendExpected) {
        score += 50; // Within range
    } else if (internStipendMax >= minStipendExpected * 0.8) {
        score += 30; // Close to expectation
    } else {
        score += 10; // Below expectation
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
    let overallScore = skillsMatch.finalScore * weights.skills +
        domainScore * weights.domainInterest +
        locationScore * weights.location +
        proficiencyScore * weights.proficiency +
        logisticsScore * weights.logistics;

    // Sanitize Score
    if (Number.isNaN(overallScore) || !Number.isFinite(overallScore)) {
        console.error('AI Match Score corrupted (NaN/Infinity). Resetting to 0.');
        overallScore = 0;
    }

    return {
        overallScore: Math.min(100, Math.max(0, Math.round(overallScore))),
        breakdown: {
            skills: {
                score: skillsMatch.finalScore,
                weight: weights.skills,
                jaccardSimilarity: skillsMatch.jaccardScore,
                matchedSkills: skillsMatch.matchedCount,
                totalRequired: skillsMatch.totalRequired
            },
            domainInterest: {
                score: domainScore,
                weight: weights.domainInterest
            },
            location: {
                score: locationScore,
                weight: weights.location
            },
            proficiency: {
                score: proficiencyScore,
                weight: weights.proficiency
            },
            logistics: {
                score: logisticsScore,
                weight: weights.logistics
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
