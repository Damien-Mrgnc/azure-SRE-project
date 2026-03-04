const { createClient } = require('redis');
const logger = require('./logger');

const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';

const redisClient = createClient({
    url: redisUrl,
    pingInterval: 1000 * 60 * 4, // Send ping every 4 minutes (keepalive for Azure)
    ...(redisUrl.startsWith('rediss://') ? {
        socket: {
            tls: true,
            rejectUnauthorized: false
        }
    } : {})
});

redisClient.on('error', (err) => logger.error('Redis Client Error', err));

(async () => {
    try {
        await redisClient.connect();
        logger.info('Connected to Redis cache');
    } catch (err) {
        logger.error('Failed to connect to Redis initially', err);
    }
})();

module.exports = redisClient;
