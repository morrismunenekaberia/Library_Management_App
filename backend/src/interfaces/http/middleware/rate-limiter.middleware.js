/**
 * In-memory rate limiter for login attempts.
 * Limits requests to 10 attempts per 15 minutes per client IP.
 */
function createLoginRateLimiter({
  windowMs = 15 * 60 * 1000, // 15 minutes
  maxAttempts = 10,
} = {}) {
  const attempts = new Map();

  // Clean up expired records every 5 minutes to prevent memory leaks
  const cleanupInterval = setInterval(() => {
    const now = Date.now();
    for (const [ip, record] of attempts.entries()) {
      if (now > record.resetTime) {
        attempts.delete(ip);
      }
    }
  }, 5 * 60 * 1000);

  if (cleanupInterval.unref) {
    cleanupInterval.unref();
  }

  return function loginRateLimiter(req, res, next) {
    // Extract IP from X-Forwarded-For if behind a proxy, or req.ip
    const forwarded = req.headers['x-forwarded-for'];
    const ip = (typeof forwarded === 'string' ? forwarded.split(',')[0].trim() : null) ||
      req.ip ||
      req.connection?.remoteAddress ||
      'unknown-ip';

    const now = Date.now();
    const record = attempts.get(ip);

    if (!record || now > record.resetTime) {
      attempts.set(ip, { count: 1, resetTime: now + windowMs });
      return next();
    }

    if (record.count >= maxAttempts) {
      const retryAfterSeconds = Math.ceil((record.resetTime - now) / 1000);
      res.setHeader('Retry-After', retryAfterSeconds);
      return res.status(429).json({
        error: 'Too many login attempts. Please try again after 15 minutes.',
      });
    }

    record.count += 1;
    next();
  };
}

module.exports = { createLoginRateLimiter };
