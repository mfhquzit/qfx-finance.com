// Rate Limit Middleware

import { Request, Response, NextFunction } from 'express';

const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // Limit each IP to 100 requests per windowMs
});

export const rateLimitMiddleware = (req: Request, res: Response, next: NextFunction) => {
    limiter(req, res, next);
};
