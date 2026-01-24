// External Internships Controller - Fetches real job listings from Arbeitnow API
// Uses in-memory caching to respect rate limits

// Simple in-memory cache
let cache = {
    data: null,
    timestamp: null,
    TTL: 15 * 60 * 1000 // 15 minutes in milliseconds
};

// Normalize job data to consistent schema
const normalizeJob = (job) => {
    return {
        id: job.slug || `job_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        title: job.title || 'Untitled Position',
        company: job.company_name || 'Unknown Company',
        location: job.location || 'Remote',
        jobType: job.job_types?.join(', ') || job.remote ? 'Remote' : 'Full-time',
        description: job.description || 'No description available',
        applyUrl: job.url || '#',
        postedAt: job.created_at || new Date().toISOString(),
        tags: job.tags || [],
        remote: job.remote || false,
        logo: job.company_logo || null
    };
};

// @desc    Get external internship listings from Arbeitnow API
// @route   GET /api/external/internships
// @access  Public
exports.getExternalInternships = async (req, res) => {
    try {
        const { page = 1, search = '', forceRefresh = false } = req.query;
        const pageNum = parseInt(page) || 1;

        // Check cache validity (not expired and not forced refresh)
        const now = Date.now();
        const cacheValid = cache.data &&
            cache.timestamp &&
            (now - cache.timestamp) < cache.TTL &&
            !forceRefresh;

        let allJobs;

        if (cacheValid) {
            console.log('Returning cached external internships');
            allJobs = cache.data;
        } else {
            console.log('Fetching fresh data from Arbeitnow API');

            // Fetch from Arbeitnow API - public endpoint, no API key required
            const fetch = (await import('node-fetch')).default;
            const response = await fetch('https://www.arbeitnow.com/api/job-board-api', {
                method: 'GET',
                headers: {
                    'Accept': 'application/json',
                    'User-Agent': 'SkillMatch-App/1.0'
                }
            });

            if (!response.ok) {
                throw new Error(`API responded with status ${response.status}`);
            }

            const data = await response.json();

            // Safe extraction - API returns { data: [...jobs] }
            const rawJobs = Array.isArray(data.data) ? data.data :
                Array.isArray(data) ? data : [];

            // Normalize all jobs
            allJobs = rawJobs.map(normalizeJob);

            // Update cache
            cache.data = allJobs;
            cache.timestamp = now;

            console.log(`Cached ${allJobs.length} jobs from Arbeitnow`);
        }

        // Apply search filter if provided
        let filteredJobs = allJobs;
        if (search.trim()) {
            const searchLower = search.toLowerCase().trim();
            filteredJobs = allJobs.filter(job =>
                job.title.toLowerCase().includes(searchLower) ||
                job.company.toLowerCase().includes(searchLower) ||
                job.location.toLowerCase().includes(searchLower) ||
                job.description.toLowerCase().includes(searchLower) ||
                job.tags.some(tag => tag.toLowerCase().includes(searchLower))
            );
        }

        // Pagination
        const perPage = 20;
        const totalJobs = filteredJobs.length;
        const totalPages = Math.ceil(totalJobs / perPage);
        const startIndex = (pageNum - 1) * perPage;
        const paginatedJobs = filteredJobs.slice(startIndex, startIndex + perPage);

        res.json({
            success: true,
            data: paginatedJobs,
            pagination: {
                currentPage: pageNum,
                totalPages,
                totalJobs,
                perPage,
                hasNextPage: pageNum < totalPages,
                hasPrevPage: pageNum > 1
            },
            cached: cacheValid,
            cacheExpiresIn: cacheValid ? Math.round((cache.TTL - (now - cache.timestamp)) / 1000) : cache.TTL / 1000
        });

    } catch (error) {
        console.error('Error fetching external internships:', error.message);

        // Return cached data if available, even if expired
        if (cache.data) {
            console.log('Returning stale cache due to API error');
            return res.json({
                success: true,
                data: cache.data.slice(0, 20),
                pagination: {
                    currentPage: 1,
                    totalPages: Math.ceil(cache.data.length / 20),
                    totalJobs: cache.data.length,
                    perPage: 20
                },
                cached: true,
                stale: true,
                error: 'Using cached data due to API error'
            });
        }

        res.status(500).json({
            success: false,
            message: 'Failed to fetch external internships',
            error: error.message
        });
    }
};

// @desc    Clear external internships cache (admin utility)
// @route   POST /api/external/internships/clear-cache
// @access  Private (Admin)
exports.clearExternalCache = async (req, res) => {
    cache.data = null;
    cache.timestamp = null;
    res.json({ success: true, message: 'External internships cache cleared' });
};
