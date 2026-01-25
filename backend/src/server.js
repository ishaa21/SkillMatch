// ✅ Load dotenv ONLY in local development
if (process.env.NODE_ENV !== 'production') {
    require('dotenv').config();
}

const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');
const http = require('http');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const hpp = require('hpp');
const path = require('path');



// ✅ Connect DB after env is ready
connectDB();

const app = express();
const server = http.createServer(app);

// ===== Socket.IO =====
const { Server } = require('socket.io');
const io = new Server(server, {
    cors: {
        origin: '*',
        methods: ['GET', 'POST'],
    },
});

app.set('io', io);

io.on('connection', socket => {
    console.log('Socket connected:', socket.id);

    socket.on('join_room', userId => {
        if (userId) socket.join(userId);
    });

    socket.on('disconnect', () => {
        console.log('Socket disconnected');
    });
});

// ===== Security Middleware =====
app.use(helmet());

app.use(cors({
    origin: '*',
    credentials: true,
}));

app.use(express.json({ limit: '10kb' }));
app.use(mongoSanitize());
app.use(hpp());

const limiter = rateLimit({
    windowMs: 10 * 60 * 1000,
    max: 1000,
});
app.use(limiter);

// ===== Static Files =====
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// ===== Routes =====
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/internships', require('./routes/internshipRoutes'));
app.use('/api/company', require('./routes/companyRoutes'));
app.use('/api/applications', require('./routes/applicationRoutes'));
app.use('/api/student', require('./routes/studentRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));
app.use('/api/external', require('./routes/externalRoutes'));

// ===== Health Check =====
app.get('/', (req, res) => {
    res.send('SkillMatch API is running');
});

// ===== Global Error Handler =====
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ message: 'Internal Server Error' });
});

// ===== Start Server =====
const PORT = process.env.PORT || 5000;

server.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
