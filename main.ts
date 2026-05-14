✅ apps/api/src/main.ts (Complete)

```typescript
import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import * as cookieParser from 'cookie-parser';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // Global pipes
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,               // strip properties not in DTO
      forbidNonWhitelisted: true,    // throw error on extra properties
      transform: true,               // auto-transform payloads to DTO instances
    }),
  );

  // Cookie parser for refresh tokens
  app.use(cookieParser());

  // CORS configuration
  app.enableCors({
    origin: [
      'https://qfx-finance.com',
      'https://admin.qfx-finance.com',
      'http://localhost:3000',
      'http://localhost:3002',
    ],
    credentials: true,               // allow cookies
  });

  // Optional: global prefix (not required but nice)
  // app.setGlobalPrefix('api');

  // Swagger documentation
  const config = new DocumentBuilder()
    .setTitle('QFX Finance API')
    .setDescription('Crypto Banking and Wealth Management Platform API')
    .setVersion('1.0')
    .addBearerAuth()
    .addCookieAuth('refresh_token')
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3001;
  await app.listen(port);
  logger.log(`🚀 QFX Finance API running on port ${port}`);
  logger.log(`📚 API documentation available at /api/docs`);
}

bootstrap();
```

---

🔁 Replace Your File

1. Open apps/api/src/main.ts
2. Replace its content with the code above.
3. Save and restart your API service (or rebuild Docker containers).

---

❌ Problems with your current main.ts

Issue Why it matters
Port 3000 Master prompt requires API on 3001 (client on 3000, admin on 3002).
No ValidationPipe Request bodies are not validated – security risk, missing class‑validator errors.
No CORS Frontend (Next.js on port 3000) cannot call the API.
No cookie‑parser Refresh token cookies cannot be read.
No Swagger No interactive API docs – developers cannot test endpoints easily.

Your improved main.ts solves all of these and makes the API production‑ready and fully compliant with the QFX Finance specification. 🚀
