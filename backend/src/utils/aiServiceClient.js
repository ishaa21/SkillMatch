/**
 * AI Service Client — Node.js integration layer
 * 
 * This module provides clean helper functions for the Express backend
 * to call the Python FastAPI AI microservice.
 * 
 * Features:
 *   - Timeout handling (10s default)
 *   - Automatic fallback to existing Jaccard matcher on failure
 *   - Health check before first call (optional)
 *   - Retry logic (1 retry on network errors)
 *   - Structured error logging
 * 
 * Architecture:
 *   Flutter → Node.js → [this module] → Python FastAPI
 *                  ↓ (on failure)
 *             Jaccard fallback (aiMatcher.js)
 */

const fetch = (...args) => import('node-fetch').then(({ default: f }) => f(...args));

// ════════════════════════════════════════════════════════════
// CONFIGURATION
// ════════════════════════════════════════════════════════════

// Set this in .env: AI_SERVICE_URL=https://your-ai-service.onrender.com
const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://localhost:8000';

// Request timeout in milliseconds (AI service needs time for ML inference)
const TIMEOUT_MS = parseInt(process.env.AI_SERVICE_TIMEOUT || '15000');

// Number of retries on network failure
const MAX_RETRIES = 1;


// ════════════════════════════════════════════════════════════
// HELPER: HTTP POST with timeout + retry
// ════════════════════════════════════════════════════════════

/**
 * Make a POST request to the AI service with timeout and retry.
 * 
 * @param {string} endpoint - API endpoint path (e.g., '/recommend')
 * @param {object} body - Request body (will be JSON-stringified)
 * @returns {Promise<object>} - Parsed JSON response
 */
const callAIService = async (endpoint, body) => {
    const url = `${AI_SERVICE_URL}${endpoint}`;
    let lastError = null;

    for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), TIMEOUT_MS);

            const response = await fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(body),
                signal: controller.signal,
            });

            clearTimeout(timeoutId);

            if (!response.ok) {
                const errorBody = await response.text();
                throw new Error(`AI Service returned ${response.status}: ${errorBody}`);
            }

            return await response.json();

        } catch (error) {
            lastError = error;
            if (error.name === 'AbortError') {
                console.error(`[AI Service] Timeout after ${TIMEOUT_MS}ms on attempt ${attempt + 1}`);
            } else {
                console.error(`[AI Service] Error on attempt ${attempt + 1}:`, error.message);
            }

            // Don't retry on non-network errors (4xx responses, etc.)
            if (error.message && error.message.includes('returned 4')) {
                break;
            }
        }
    }

    throw lastError;
};


// ════════════════════════════════════════════════════════════
// PUBLIC API
// ════════════════════════════════════════════════════════════

/**
 * Get AI-powered recommendations for a student.
 * Falls back to the existing Jaccard-based matcher on failure.
 * 
 * @param {object} student - Student document from MongoDB
 * @param {Array} internships - Array of Internship documents
 * @param {object} fallbackFn - Optional fallback function (rankInternshipsForStudent)
 * @returns {Promise<Array>} - Array of internships with matchScore
 */
const getAIRecommendations = async (student, internships, fallbackFn = null) => {
    try {
        // ── Transform MongoDB documents to AI service format ──
        const requestBody = {
            student_skills: (student.skills || []).map(s => s.name || s),
            resume_text: student.bio || '',
            preferred_domain: (student.preferredDomains || [])[0] || '',
            preferred_location: student.location?.city || '',
            internships: internships.map(i => {
                const obj = i.toObject ? i.toObject() : i;
                return {
                    id: obj._id?.toString() || obj.id,
                    title: obj.title || '',
                    description: obj.description || '',
                    required_skills: (obj.requiredSkills || []).map(s => s.name || s),
                    domains: obj.domains || [],
                    location: obj.location?.city
                        ? `${obj.location.city}, ${obj.location.country || 'India'}`
                        : (typeof obj.location === 'string' ? obj.location : ''),
                    work_mode: obj.workMode || 'Remote',
                    company_name: obj.company?.companyName || '',
                };
            }),
        };

        // ── Call AI Service ──
        console.log(`[AI Service] Requesting recommendations for ${internships.length} internships...`);
        const response = await callAIService('/recommend', requestBody);

        // ── Map AI scores back to internship objects ──
        const scoreMap = {};
        (response.recommendations || []).forEach(rec => {
            scoreMap[rec.id] = {
                matchScore: rec.score,
                matchPercentage: rec.score,
                matchBreakdown: rec.breakdown,
                explanation: rec.explanation || '',
                skillGaps: rec.skill_gaps || [],
                aiService: true,  // Flag to identify AI-service scores
            };
        });

        // Merge scores into internship objects
        const rankedInternships = internships.map(i => {
            const obj = i.toObject ? i.toObject() : i;
            const id = obj._id?.toString() || obj.id;
            const aiData = scoreMap[id] || {
                matchScore: 0,
                matchPercentage: 0,
                matchBreakdown: {},
                explanation: '',
                skillGaps: [],
                aiService: true,
            };
            return { ...obj, ...aiData };
        });

        // Sort by match score descending
        rankedInternships.sort((a, b) => b.matchScore - a.matchScore);

        console.log(`[AI Service] ✅ Got ${response.recommendations?.length || 0} recommendations`);
        return rankedInternships;

    } catch (error) {
        console.error('[AI Service] ❌ Failed, falling back to Jaccard matcher:', error.message);

        // ── FALLBACK: Use existing Jaccard-based matcher ──
        if (fallbackFn) {
            return fallbackFn(student, internships);
        }

        // If no fallback provided, return internships with default scores
        return internships.map(i => {
            const obj = i.toObject ? i.toObject() : i;
            return {
                ...obj,
                matchScore: 50,       // Default neutral score
                matchPercentage: 50,
                aiService: false,
            };
        });
    }
};


/**
 * Extract skills from resume text using the AI service.
 * 
 * @param {string} resumeText - Plain text of the resume
 * @returns {Promise<Array<string>>} - Array of extracted skill names
 */
const extractSkillsFromResume = async (resumeText) => {
    try {
        const response = await callAIService('/extract-skills', {
            resume_text: resumeText,
        });
        return response.skills || [];
    } catch (error) {
        console.error('[AI Service] Skill extraction failed:', error.message);
        return [];  // Return empty array on failure — non-critical
    }
};


/**
 * Check if the AI service is healthy and ready.
 * 
 * @returns {Promise<boolean>} - true if service is healthy
 */
const checkAIServiceHealth = async () => {
    try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000);

        const response = await fetch(`${AI_SERVICE_URL}/health`, {
            signal: controller.signal,
        });

        clearTimeout(timeoutId);

        if (response.ok) {
            const data = await response.json();
            return data.status === 'ok' && data.model_loaded === true;
        }
        return false;
    } catch {
        return false;
    }
};


module.exports = {
    getAIRecommendations,
    extractSkillsFromResume,
    checkAIServiceHealth,
    AI_SERVICE_URL,
};
