const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { createLoginRateLimiter } = require('../src/interfaces/http/middleware/rate-limiter.middleware');
const errorHandler = require('../src/interfaces/http/middleware/errorHandler');
const { ValidationError } = require('../src/domain/errors');

describe('Hardening: Login Rate Limiter', () => {
  it('allows requests within limit (10 attempts) and blocks subsequent attempts with 429', () => {
    const limiter = createLoginRateLimiter({
      windowMs: 60 * 1000,
      maxAttempts: 10,
    });

    const req = { ip: '192.168.1.100', headers: {} };
    let blocked = false;
    let statusCode = 200;
    let jsonBody = null;

    const createRes = () => ({
      setHeader: () => {},
      status: (code) => {
        statusCode = code;
        return {
          json: (body) => {
            jsonBody = body;
            blocked = true;
          },
        };
      },
    });

    // Run 10 allowed attempts
    for (let i = 0; i < 10; i++) {
      let nextCalled = false;
      limiter(req, createRes(), () => {
        nextCalled = true;
      });
      assert.equal(nextCalled, true, `Attempt ${i + 1} should be allowed`);
    }

    // 11th attempt must be blocked with 429
    let nextCalled11 = false;
    limiter(req, createRes(), () => {
      nextCalled11 = true;
    });

    assert.equal(nextCalled11, false, '11th attempt should NOT call next()');
    assert.equal(blocked, true, '11th attempt should be blocked');
    assert.equal(statusCode, 429, 'Status should be 429');
    assert.match(jsonBody.error, /Too many login attempts/);
  });
});

describe('Hardening: Centralized Error Handler', () => {
  it('returns 400 for malformed JSON syntax errors', () => {
    const err = new SyntaxError('Unexpected token');
    err.status = 400;
    err.body = '{ bad json';

    let code = 0;
    let responseBody = null;
    const res = {
      status: (c) => {
        code = c;
        return {
          json: (b) => {
            responseBody = b;
          },
        };
      },
    };

    errorHandler(err, {}, res, () => {});

    assert.equal(code, 400);
    assert.deepEqual(responseBody, { error: 'Invalid JSON payload' });
  });

  it('returns generic 500 without leaking stack traces for unexpected errors', () => {
    const err = new Error('Database connection failed: FATAL at postgres.internal.c:42');

    const originalError = console.error;
    let loggedError = null;
    console.error = (...args) => {
      loggedError = args;
    };

    let code = 0;
    let responseBody = null;
    const res = {
      status: (c) => {
        code = c;
        return {
          json: (b) => {
            responseBody = b;
          },
        };
      },
    };

    try {
      errorHandler(err, {}, res, () => {});
    } finally {
      console.error = originalError;
    }

    assert.equal(code, 500);
    assert.deepEqual(responseBody, { error: 'Internal server error' });
    assert.equal(responseBody.stack, undefined);
    assert.notEqual(loggedError, null);
  });

  it('returns AppError message and status code without stack trace', () => {
    const err = new ValidationError('Field is invalid');

    let code = 0;
    let responseBody = null;
    const res = {
      status: (c) => {
        code = c;
        return {
          json: (b) => {
            responseBody = b;
          },
        };
      },
    };

    errorHandler(err, {}, res, () => {});

    assert.equal(code, 400);
    assert.deepEqual(responseBody, { error: 'Field is invalid' });
  });
});
