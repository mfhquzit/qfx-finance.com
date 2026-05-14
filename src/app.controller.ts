import { Controller, Get, HttpStatus, Logger } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('Health')
@Controller()
export class HealthController {
  private readonly logger = new Logger(HealthController.name);
  private readonly startTime: number;
  private readonly version: string;

  constructor(
    private prismaService: PrismaService,
    private redisService: RedisService,
  ) {
    this.startTime = Date.now();
    this.version = process.env.npm_package_version || '1.0.0';
  }

  @Get('/health')
  @Public()
  @ApiOperation({ summary: 'Basic health check' })
  @ApiResponse({ status: 200, description: 'Service is healthy' })
  async getBasicHealth() {
    const uptime = process.uptime();
    const memoryUsage = process.memoryUsage();
    
    return {
      status: 'ok',
      version: this.version,
      timestamp: new Date().toISOString(),
      uptime: {
        seconds: Math.floor(uptime),
        human: this.formatUptime(uptime),
      },
      memory: {
        rss: `${Math.round(memoryUsage.rss / 1024 / 1024)} MB`,
        heapTotal: `${Math.round(memoryUsage.heapTotal / 1024 / 1024)} MB`,
        heapUsed: `${Math.round(memoryUsage.heapUsed / 1024 / 1024)} MB`,
        external: `${Math.round(memoryUsage.external / 1024 / 1024)} MB`,
      },
      environment: process.env.NODE_ENV || 'development',
    };
  }

  @Get('/health/detailed')
  @Public()
  @ApiOperation({ summary: 'Detailed health check with all dependencies' })
  async getDetailedHealth() {
    const checks = await Promise.all([
      this.checkDatabase(),
      this.checkRedis(),
      this.checkDiskSpace(),
      this.checkExternalApis(),
    ]);

    const allHealthy = checks.every(check => check.status === 'healthy');
    const status = allHealthy ? 'healthy' : 'degraded';
    const httpStatus = allHealthy ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE;

    return {
      status,
      timestamp: new Date().toISOString(),
      version: this.version,
      uptime: this.formatUptime(process.uptime()),
      services: checks.reduce((acc, check) => ({ ...acc, ...check }), {}),
    };
  }

  @Get('/health/readiness')
  @Public()
  @ApiOperation({ summary: 'Readiness probe for orchestration' })
  async getReadiness() {
    const checks = await Promise.all([
      this.checkDatabase(),
      this.checkRedis(),
    ]);

    const isReady = checks.every(check => check.status === 'healthy');
    
    if (!isReady) {
      return {
        status: 'not ready',
        timestamp: new Date().toISOString(),
        checks: checks.map(c => ({ name: c.name, status: c.status, message: c.message })),
      };
    }

    return {
      status: 'ready',
      timestamp: new Date().toISOString(),
    };
  }

  @Get('/health/liveness')
  @Public()
  @ApiOperation({ summary: 'Liveness probe for orchestration' })
  async getLiveness() {
    return {
      status: 'alive',
      timestamp: new Date().toISOString(),
      uptime: this.formatUptime(process.uptime()),
    };
  }

  @Get('/health/metrics')
  @Public()
  @ApiOperation({ summary: 'Detailed metrics for monitoring' })
  async getMetrics() {
    const [dbStats, redisInfo, systemMetrics] = await Promise.all([
      this.getDatabaseMetrics(),
      this.getRedisMetrics(),
      this.getSystemMetrics(),
    ]);

    return {
      timestamp: new Date().toISOString(),
      database: dbStats,
      redis: redisInfo,
      system: systemMetrics,
      application: {
        startTime: new Date(this.startTime).toISOString(),
        uptime: this.formatUptime(process.uptime()),
        version: this.version,
        nodeVersion: process.version,
        platform: process.platform,
        arch: process.arch,
        pid: process.pid,
      },
    };
  }

  // Private helper methods for health checks
  private async checkDatabase() {
    const startTime = Date.now();
    try {
      // Execute a simple query to check database connectivity
      await this.prismaService.$queryRaw`SELECT 1 as connected`;
      const responseTime = Date.now() - startTime;

      // Get database version
      const versionResult = await this.prismaService.$queryRaw`SELECT version() as version`;
      const version = versionResult[0]?.version || 'unknown';

      // Check connection pool status
      const poolStatus = await this.getDatabasePoolStatus();

      return {
        name: 'postgresql',
        status: 'healthy',
        responseTime: `${responseTime}ms`,
        version,
        poolStatus,
      };
    } catch (error) {
      this.logger.error(`Database health check failed: ${error.message}`);
      return {
        name: 'postgresql',
        status: 'unhealthy',
        error: error.message,
      };
    }
  }

  private async checkRedis() {
    const startTime = Date.now();
    try {
      // Test Redis connectivity
      const pong = await this.redisService.ping();
      const responseTime = Date.now() - startTime;

      // Get Redis info
      const info = await this.redisService.getInfo();
      const memory = info?.used_memory_human || 'unknown';
      const connectedClients = info?.connected_clients || 'unknown';

      return {
        name: 'redis',
        status: 'healthy',
        responseTime: `${responseTime}ms`,
        pong: pong === 'PONG' ? 'connected' : 'error',
        memory,
        connectedClients,
      };
    } catch (error) {
      this.logger.error(`Redis health check failed: ${error.message}`);
      return {
        name: 'redis',
        status: 'unhealthy',
        error: error.message,
      };
    }
  }

  private async checkDiskSpace() {
    const disk = require('diskusage');
    try {
      const path = process.cwd();
      const { available, free, total } = await disk.check(path);
      
      const availableGB = Math.round(available / 1024 / 1024 / 1024);
      const totalGB = Math.round(total / 1024 / 1024 / 1024);
      const usagePercent = Math.round(((total - free) / total) * 100);

      let status = 'healthy';
      let warning = null;

      if (usagePercent > 90) {
        status = 'critical';
        warning = 'Disk usage exceeds 90%';
      } else if (usagePercent > 75) {
        status = 'degraded';
        warning = 'Disk usage exceeds 75%';
      }

      return {
        name: 'disk',
        status,
        available: `${availableGB} GB`,
        total: `${totalGB} GB`,
        usage: `${usagePercent}%`,
        warning,
      };
    } catch (error) {
      this.logger.error(`Disk space check failed: ${error.message}`);
      return {
        name: 'disk',
        status: 'unknown',
        error: error.message,
      };
    }
  }

  private async checkExternalApis() {
    const apis = [
      { name: 'coingecko', url: 'https://api.coingecko.com/api/v3/ping', timeout: 5000 },
      { name: 'stripe', url: 'https://api.stripe.com/v1', timeout: 5000 },
    ];

    const results = await Promise.allSettled(
      apis.map(async (api) => {
        const startTime = Date.now();
        try {
          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(), api.timeout);
          
          const response = await fetch(api.url, {
            signal: controller.signal,
            headers: {
              'User-Agent': 'QFX-Finance-HealthCheck/1.0',
            },
          });
          
          clearTimeout(timeoutId);
          const responseTime = Date.now() - startTime;
          
          return {
            name: api.name,
            status: response.ok ? 'healthy' : 'degraded',
            responseTime: `${responseTime}ms`,
            statusCode: response.status,
          };
        } catch (error) {
          return {
            name: api.name,
            status: 'unhealthy',
            error: error.message,
          };
        }
      })
    );

    const externalApis = results.map(result => 
      result.status === 'fulfilled' ? result.value : { name: 'unknown', status: 'unhealthy' }
    );

    return {
      name: 'external_apis',
      status: externalApis.every(api => api.status === 'healthy') ? 'healthy' : 'degraded',
      apis: externalApis,
    };
  }

  private async getDatabaseMetrics() {
    try {
      // Get active connections
      const connections = await this.prismaService.$queryRaw`
        SELECT count(*) as count FROM pg_stat_activity WHERE datname = current_database()
      `;
      
      // Get database size
      const dbSize = await this.prismaService.$queryRaw`
        SELECT pg_database_size(current_database()) as size
      `;
      
      // Get table counts
      const userCount = await this.prismaService.user.count();
      const transactionCount = await this.prismaService.transaction.count();
      const investmentCount = await this.prismaService.investment.count();

      return {
        activeConnections: connections[0]?.count || 0,
        databaseSize: this.formatBytes(parseInt(dbSize[0]?.size) || 0),
        records: {
          users: userCount,
          transactions: transactionCount,
          investments: investmentCount,
        },
      };
    } catch (error) {
      this.logger.error(`Failed to get database metrics: ${error.message}`);
      return { error: 'Unable to fetch database metrics' };
    }
  }

  private async getRedisMetrics() {
    try {
      const info = await this.redisService.getInfo();
      const keyspace = await this.redisService.getKeyspaceInfo();
      
      return {
        usedMemory: info?.used_memory_human || 'unknown',
        totalConnections: info?.total_connections_received || 'unknown',
        totalCommands: info?.total_commands_processed || 'unknown',
        hitRate: info?.keyspace_hits && info?.keyspace_misses 
          ? `${Math.round((info.keyspace_hits / (info.keyspace_hits + info.keyspace_misses)) * 100)}%`
          : 'unknown',
        keyspace: keyspace,
      };
    } catch (error) {
      return { error: 'Unable to fetch Redis metrics' };
    }
  }

  private async getSystemMetrics() {
    const os = require('os');
    
    return {
      cpu: {
        cores: os.cpus().length,
        model: os.cpus()[0]?.model || 'unknown',
        loadAverage: os.loadavg(),
      },
      memory: {
        total: this.formatBytes(os.totalmem()),
        free: this.formatBytes(os.freemem()),
        usedPercent: `${Math.round(((os.totalmem() - os.freemem()) / os.totalmem()) * 100)}%`,
      },
      network: {
        hostname: os.hostname(),
        platform: os.platform(),
        release: os.release(),
      },
    };
  }

  private async getDatabasePoolStatus() {
    try {
      // Get connection pool stats from Prisma (if available)
      const metrics = (this.prismaService as any).$metrics?.json();
      return {
        active: metrics?.activeConnections || 'unknown',
        idle: metrics?.idleConnections || 'unknown',
        waiting: metrics?.waitingRequests || 'unknown',
      };
    } catch {
      return { status: 'pool metrics unavailable' };
    }
  }

  private formatUptime(seconds: number): string {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    
    const parts = [];
    if (days > 0) parts.push(`${days}d`);
    if (hours > 0) parts.push(`${hours}h`);
    if (minutes > 0) parts.push(`${minutes}m`);
    if (secs > 0 || parts.length === 0) parts.push(`${secs}s`);
    
    return parts.join(' ');
  }

  private formatBytes(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }
          }
