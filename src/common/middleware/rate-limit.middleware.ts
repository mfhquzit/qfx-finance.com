import { Injectable, NestMiddleware, HttpException, HttpStatus } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { RedisService } from '../../redis/redis.service';

@Injectable()
export class RateLimitMiddleware implements NestMiddleware {
  constructor(private redisService: RedisService) {}

  async use(req: Request, res: Response, next: NextFunction) {
    const ip = req.ip || req.connection.remoteAddress;
    const endpoint = req.path;
    const method = req.method;
    
    // Different rate limits for different endpoints
    const rateLimits = this.getRateLimits(endpoint);
    
    if (!rateLimits) {
      return next();
    }

    const key = `rate_limit:${ip}:${endpoint}:${method}`;
    const current = await this.redisService.get(key);
    const requestCount = current ? parseInt(current, 10) : 0;

    if (requestCount >= rateLimits.max) {
      const ttl = await this.redisService.ttl(key);
      throw new HttpException(
        {
          statusCode: HttpStatus.TOO_MANY_REQUESTS,
          message: 'Too many requests. Please try again later.',
          retryAfter: Math.ceil(ttl / 60),
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // Increment counter
    if (requestCount === 0) {
      await this.redisService.set(key, '1', rateLimits.windowMs / 1000);
    } else {
      await this.redisService.incr(key);
    }

    // Add rate limit headers
    res.setHeader('X-RateLimit-Limit', rateLimits.max);
    res.setHeader('X-RateLimit-Remaining', rateLimits.max - (requestCount + 1));
    res.setHeader('X-RateLimit-Reset', Math.floor(Date.now() / 1000) + (rateLimits.windowMs / 1000));

    next();
  }

  private getRateLimits(endpoint: string): { max: number; windowMs: number } | null {
    // Strict rate limits for auth endpoints
    if (endpoint.includes('/auth/login')) {
      return { max: 5, windowMs: 15 * 60 * 1000 }; // 5 attempts per 15 minutes
    }
    
    if (endpoint.includes('/auth/register')) {
      return { max: 3, windowMs: 60 * 60 * 1000 }; // 3 registrations per hour
    }
    
    if (endpoint.includes('/auth/2fa')) {
      return { max: 10, windowMs: 15 * 60 * 1000 }; // 10 attempts per 15 minutes
    }
    
    // Moderate limits for API endpoints
    if (endpoint.includes('/transactions')) {
      return { max: 50, windowMs: 60 * 60 * 1000 }; // 50 transactions per hour
    }
    
    if (endpoint.includes('/investments')) {
      return { max: 20, windowMs: 60 * 60 * 1000 }; // 20 investment actions per hour
    }
    
    if (endpoint.includes('/crypto/prices')) {
      return { max: 300, windowMs: 60 * 60 * 1000 }; // 300 price checks per hour
    }
    
    if (endpoint.includes('/kyc')) {
      return { max: 10, windowMs: 24 * 60 * 60 * 1000 }; // 10 KYC submissions per day
    }
    
    // Admin endpoints
    if (endpoint.includes('/admin')) {
      return { max: 200, windowMs: 60 * 60 * 1000 }; // 200 admin actions per hour
    }
    
    // Default rate limit
    return { max: 100, windowMs: 15 * 60 * 1000 };
  }
  }
