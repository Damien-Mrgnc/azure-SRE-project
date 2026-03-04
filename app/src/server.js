const express = require('express');
const cors = require('cors');
const path = require('path');
const logger = require('./config/logger');
const { requireAuth, requireAdmin } = require('./middleware/auth');
const configService = require('./services/configService');

const app = express();
const port = process.env.PORT || 8080;

// Configuration
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, 'public')));

// Middleware
app.use(express.json());

// CORS Configuration - Restrict access in production
if (process.env.NODE_ENV === 'production') {
    app.use(cors({
        origin: [/azurewebsites\.net$/], // Allow all Azure subdomains
        methods: ['GET', 'POST', 'PUT', 'DELETE'],
        allowedHeaders: ['Content-Type', 'Authorization', 'x-correlation-id']
    }));
} else {
    app.use(cors()); // Open for dev
}

// Public API Routes (Public config)
// GET /api/config -> Returns current state
app.get('/api/config', async (req, res) => {
    try {
        const config = await configService.getConfig();
        res.json(config);
    } catch (e) {
        logger.error('Failed to get config API', e);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// Admin API (Protected)
// POST /api/admin/config
const { configUpdateSchema } = require('./validation/configSchema');

app.post('/api/admin/config', requireAuth, requireAdmin, async (req, res) => {
    try {
        // Validation Zod
        const validatedPayload = configUpdateSchema.parse(req.body);

        // Update DB
        const result = await configService.updateConfig(
            validatedPayload,
            req.user.name || 'Admin',
            req.correlationId
        );

        res.json({ message: 'Success', config: result });
    } catch (e) {
        if (e.errors) { // Zod Error
            return res.status(400).json({ message: 'Validation Error', errors: e.errors });
        }
        logger.error('Update failed', e);
        res.status(500).json({ message: 'Internal Server Error' });
    }
});

// Chaos Engineering: Stress route
app.post('/api/admin/stress', requireAuth, requireAdmin, (req, res) => {
    logger.warn('Chaos: Stress test initiated by admin!');
    const duration = parseInt(req.body.duration) || 5000; // block for 5s by default
    const end = Date.now() + duration;

    // Block event loop (CPU Burn) - Perfect for testing autoscaling
    while (Date.now() < end) {
        Math.sqrt(Math.random() * Math.random());
    }

    res.json({ message: `Chaos test completed. CPU blocked for ${duration}ms` });
});

// UI Routes
app.get('/', async (req, res) => {
    // Public Page: Server-side rendered with current config
    try {
        const config = await configService.getConfig();

        let quote = "Le chaos est le meilleur enseignant.";
        try {
            // Using a public API that might be artificially slow or just an external dependency
            const response = await fetch('https://dummyjson.com/quotes/random');
            if (response.ok) {
                const data = await response.json();
                quote = `"${data.quote}" - ${data.author}`;
            }
        } catch (apiErr) {
            logger.warn('Failed to fetch quote of the day', apiErr);
        }

        res.render('index', { config, quote });
    } catch (e) {
        logger.error('Failed to render index', e);
        res.status(500).send('Error loading page');
    }
});

app.get('/admin', requireAuth, requireAdmin, async (req, res) => {
    try {
        const config = await configService.getConfig();
        res.render('admin', { config, error: null });
    } catch (e) {
        logger.error('Failed to render admin', e);
        res.status(500).send('Error loading admin panel');
    }
});

// Audit Log Route (Admin)
app.get('/admin/audit', requireAuth, requireAdmin, async (req, res) => {
    try {
        const config = await configService.getConfig();
        const logs = await configService.getAuditLogs();
        res.render('audit', { config, logs });
    } catch (e) {
        logger.error('Failed to render audit log', e);
        res.status(500).send('Error loading audit log');
    }
});

// Server Start
app.listen(port, () => {
    logger.info(`Runtime Governance App listening on port ${port}`);
});

process.on('SIGTERM', () => {
    logger.info('SIGTERM received. Closing...');
    // Clean DB shutdown etc.
    process.exit(0);
});
