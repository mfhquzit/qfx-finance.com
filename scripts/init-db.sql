-- QFX Finance Database Initialization Script
-- PostgreSQL 15+

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS qfx_db;
\c qfx_db;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- ENUM TYPES
-- ============================================

CREATE TYPE "Role" AS ENUM ('SUPER_ADMIN', 'ADMIN', 'COMPLIANCE_OFFICER', 'KYC_OFFICER', 'SUPPORT_AGENT', 'TRADER', 'INVESTOR', 'USER');
CREATE TYPE "KycStatus" AS ENUM ('PENDING', 'UNDER_REVIEW', 'APPROVED', 'REJECTED');
CREATE TYPE "TransactionType" AS ENUM ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER', 'INVESTMENT', 'PROFIT_DISTRIBUTION', 'FEE');
CREATE TYPE "TransactionStatus" AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED');
CREATE TYPE "InvestmentPlan" AS ENUM ('BRONZE', 'SILVER', 'GOLD', 'VIP');

-- ============================================
-- TABLES
-- ============================================

-- Users table (main account management)
CREATE TABLE users (
    id VARCHAR(255) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    email VARCHAR(255) UNIQUE NOT NULL,
    "passwordHash" VARCHAR(255) NOT NULL,
    "firstName" VARCHAR(100),
    "lastName" VARCHAR(100),
    role "Role" DEFAULT 'USER',
    "twoFactorEnabled" BOOLEAN DEFAULT false,
    "twoFactorSecret" VARCHAR(255),
    "kycStatus" "KycStatus" DEFAULT 'PENDING',
    "kycSubmittedAt" TIMESTAMP,
    "kycApprovedAt" TIMESTAMP,
    "loginAttempts" INTEGER DEFAULT 0,
    "lockedUntil" TIMESTAMP,
    balance DECIMAL(18,8) DEFAULT 0,
    "stripeCustomerId" VARCHAR(255),
    "emailVerified" BOOLEAN DEFAULT false,
    "emailVerifyToken" VARCHAR(255),
    "resetPasswordToken" VARCHAR(255),
    "resetPasswordExpires" TIMESTAMP,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "lastLoginAt" TIMESTAMP
);

-- KYC Documents table
CREATE TABLE kyc_documents (
    id VARCHAR(255) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "userId" VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    "fileUrl" TEXT NOT NULL,
    "fileHash" VARCHAR(255),
    status "KycStatus" DEFAULT 'PENDING',
    "reviewNote" TEXT,
    "reviewedBy" VARCHAR(255),
    "reviewedAt" TIMESTAMP,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Wallets table (crypto wallets)
CREATE TABLE wallets (
    id VARCHAR(255) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "userId" VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    address VARCHAR(255) UNIQUE NOT NULL,
    chain VARCHAR(50) NOT NULL,
    label VARCHAR(255),
    "isPrimary" BOOLEAN DEFAULT false,
    "lastUsed" TIMESTAMP,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transactions table
CREATE TABLE transactions (
    id VARCHAR(255) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "userId" VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type "TransactionType" NOT NULL,
    status "TransactionStatus" DEFAULT 'PENDING',
    amount DECIMAL(18,8) NOT NULL,
    fee DECIMAL(18,8) DEFAULT 0,
    currency VARCHAR(10) DEFAULT 'USD',
    description TEXT,
    metadata JSONB,
    "approvedBy" VARCHAR(255),
    "approvedAt" TIMESTAMP,
    "txHash" VARCHAR(255),
    "fromAddress" VARCHAR(255),
    "toAddress" VARCHAR(255),
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Investments table
CREATE TABLE investments (
    id VARCHAR(255) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "userId" VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan "InvestmentPlan" NOT NULL,
    amount DECIMAL(18,8) NOT NULL,
    "dailyReturn" DECIMAL(5,4) NOT NULL,
    "isActive" BOOLEAN DEFAULT true,
    "startDate" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "endDate" TIMESTAMP,
    "totalEarned" DECIMAL(18,8) DEFAULT 0,
    "lastPayoutAt" TIMESTAMP,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Platform wallets (company wallets)
CREATE TABLE platform_wallets (
    id VARCHAR(255) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    address VARCHAR(255) UNIQUE NOT NULL,
    chain VARCHAR(50) NOT NULL,
    label VARCHAR(255),
    balance DECIMAL(18,8) DEFAULT 0,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Investment plan configurations
CREATE TABLE investment_plan_configs (
    id VARCHAR(255) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    plan "InvestmentPlan" UNIQUE NOT NULL,
    name VARCHAR(50) NOT NULL,
    "minInvestment" DECIMAL(18,2) NOT NULL,
    "maxInvestment" DECIMAL(18,2),
    "dailyRoi" DECIMAL(5,4) NOT NULL,
    duration INTEGER NOT NULL,
    "totalReturn" DECIMAL(5,2) NOT NULL,
    "isActive" BOOLEAN DEFAULT true,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit logs for admin actions
CREATE TABLE audit_logs (
    id VARCHAR(255) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "userId" VARCHAR(255) NOT NULL,
    action VARCHAR(100) NOT NULL,
    entity VARCHAR(100) NOT NULL,
    "entityId" VARCHAR(255),
    "oldValues" JSONB,
    "newValues" JSONB,
    "ipAddress" VARCHAR(45),
    "userAgent" TEXT,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Users table indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_kyc_status ON users("kycStatus");
CREATE INDEX idx_users_created_at ON users("createdAt");

-- Transactions table indexes
CREATE INDEX idx_transactions_user_id ON transactions("userId");
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_created_at ON transactions("createdAt");
CREATE INDEX idx_transactions_user_status ON transactions("userId", status);

-- Investments table indexes
CREATE INDEX idx_investments_user_id ON investments("userId");
CREATE INDEX idx_investments_plan ON investments(plan);
CREATE INDEX idx_investments_is_active ON investments("isActive");
CREATE INDEX idx_investments_end_date ON investments("endDate");

-- KYC documents indexes
CREATE INDEX idx_kyc_documents_user_id ON kyc_documents("userId");
CREATE INDEX idx_kyc_documents_status ON kyc_documents(status);

-- Wallets indexes
CREATE INDEX idx_wallets_user_id ON wallets("userId");
CREATE INDEX idx_wallets_address ON wallets(address);

-- Audit logs indexes
CREATE INDEX idx_audit_logs_user_id ON audit_logs("userId");
CREATE INDEX idx_audit_logs_created_at ON audit_logs("createdAt");
CREATE INDEX idx_audit_logs_action ON audit_logs(action);

-- ============================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================

-- Function to update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_platform_wallets_updated_at BEFORE UPDATE ON platform_wallets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_investment_plan_configs_updated_at BEFORE UPDATE ON investment_plan_configs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SEED DATA
-- ============================================

-- Insert investment plans
INSERT INTO investment_plan_configs (plan, name, "minInvestment", "maxInvestment", "dailyRoi", duration, "totalReturn", "isActive") VALUES
    ('BRONZE', 'Bronze Plan', 100, 999, 2.0, 30, 160, true),
    ('SILVER', 'Silver Plan', 1000, 4999, 3.5, 45, 257.5, true),
    ('GOLD', 'Gold Plan', 5000, 19999, 5.0, 60, 400, true),
    ('VIP', 'VIP Plan', 20000, NULL, 8.0, 90, 720, true);

-- Insert platform wallets
INSERT INTO platform_wallets (address, chain, label, balance) VALUES
    ('0x1234567890123456789012345678901234567890', 'ethereum', 'ETH Hot Wallet', 100),
    ('0x0987654321098765432109876543210987654321', 'bsc', 'BSC Hot Wallet', 100),
    ('0xabcdef1234567890abcdef1234567890abcdef12', 'polygon', 'Polygon Hot Wallet', 100);

-- Create super admin (password will be hashed by application)
-- This is just a placeholder - the actual password should be set via the seed script
INSERT INTO users (id, email, "passwordHash", role, "kycStatus", "emailVerified", "firstName", "lastName") 
VALUES ('admin_default_id', 'admin@qfx-finance.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.VTtYE2lwZ6QjU2', 'SUPER_ADMIN', 'APPROVED', true, 'Super', 'Admin')
ON CONFLICT (email) DO NOTHING;

-- ============================================
-- VIEWS FOR COMMON QUERIES
-- ============================================

-- User summary view
CREATE OR REPLACE VIEW user_summary AS
SELECT 
    u.id,
    u.email,
    u."firstName",
    u."lastName",
    u.role,
    u."kycStatus",
    u.balance,
    COUNT(DISTINCT i.id) as active_investments,
    COALESCE(SUM(i.amount), 0) as total_invested,
    COALESCE(SUM(i."totalEarned"), 0) as total_earned,
    COUNT(DISTINCT w.id) as linked_wallets,
    u."createdAt",
    u."lastLoginAt"
FROM users u
LEFT JOIN investments i ON u.id = i."userId" AND i."isActive" = true
LEFT JOIN wallets w ON u.id = w."userId"
GROUP BY u.id;

-- Daily platform statistics view
CREATE OR REPLACE VIEW daily_platform_stats AS
SELECT 
    DATE(t."createdAt") as date,
    COUNT(DISTINCT t."userId") as active_users,
    COUNT(t.id) as total_transactions,
    SUM(CASE WHEN t.type = 'DEPOSIT' THEN t.amount ELSE 0 END) as total_deposits,
    SUM(CASE WHEN t.type = 'WITHDRAWAL' THEN t.amount ELSE 0 END) as total_withdrawals,
    SUM(CASE WHEN t.type = 'PROFIT_DISTRIBUTION' THEN t.amount ELSE 0 END) as total_profits,
    COUNT(DISTINCT i.id) as new_investments,
    SUM(i.amount) as new_investment_volume
FROM transactions t
LEFT JOIN investments i ON DATE(i."createdAt") = DATE(t."createdAt")
WHERE t.status = 'COMPLETED'
GROUP BY DATE(t."createdAt")
ORDER BY date DESC;

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to calculate user's total portfolio value
CREATE OR REPLACE FUNCTION calculate_portfolio_value(user_id VARCHAR)
RETURNS DECIMAL(18,8) AS $$
DECLARE
    total_value DECIMAL(18,8);
BEGIN
    SELECT COALESCE(SUM(i.amount + i."totalEarned"), 0) + COALESCE(u.balance, 0)
    INTO total_value
    FROM users u
    LEFT JOIN investments i ON u.id = i."userId" AND i."isActive" = true
    WHERE u.id = user_id
    GROUP BY u.balance;
    
    RETURN total_value;
END;
$$ LANGUAGE plpgsql;

-- Function to check if user can withdraw
CREATE OR REPLACE FUNCTION can_withdraw(user_id VARCHAR, amount DECIMAL(18,8))
RETURNS BOOLEAN AS $$
DECLARE
    current_balance DECIMAL(18,8);
    has_pending_withdrawals BOOLEAN;
BEGIN
    -- Get current balance
    SELECT balance INTO current_balance FROM users WHERE id = user_id;
    
    -- Check for pending withdrawals
    SELECT EXISTS(
        SELECT 1 FROM transactions 
        WHERE "userId" = user_id 
        AND type = 'WITHDRAWAL' 
        AND status = 'PENDING'
    ) INTO has_pending_withdrawals;
    
    -- Return true if sufficient balance and no pending withdrawals
    RETURN current_balance >= amount AND NOT has_pending_withdrawals;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ROW LEVEL SECURITY (Optional - for multi-tenant)
-- ============================================

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own data
CREATE POLICY user_data_policy ON users
    USING (id = current_setting('app.current_user_id', true)::VARCHAR);

-- Note: These policies require setting app.current_user_id in the application context
-- For production, implement proper JWT-based RLS

-- ============================================
-- MAINTENANCE FUNCTIONS
-- ============================================

-- Function to clean up old audit logs (keep last 90 days)
CREATE OR REPLACE FUNCTION cleanup_old_audit_logs()
RETURNS void AS $$
BEGIN
    DELETE FROM audit_logs 
    WHERE "createdAt" < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Function to archive old completed transactions
CREATE OR REPLACE FUNCTION archive_old_transactions()
RETURNS void AS $$
BEGIN
    -- Create archive table if it doesn't exist
    CREATE TABLE IF NOT EXISTS transactions_archive (LIKE transactions INCLUDING ALL);
    
    -- Move transactions older than 1 year to archive
    WITH archived AS (
        DELETE FROM transactions 
        WHERE "createdAt" < NOW() - INTERVAL '1 year'
        AND status IN ('COMPLETED', 'FAILED', 'CANCELLED')
        RETURNING *
    )
    INSERT INTO transactions_archive SELECT * FROM archived;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- DATABASE STATISTICS
-- ============================================

-- Analyze tables for query optimizer
ANALYZE users;
ANALYZE transactions;
ANALYZE investments;
ANALYZE kyc_documents;
ANALYZE wallets;
ANALYZE audit_logs;

-- ============================================
-- INITIALIZATION COMPLETE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ QFX Finance Database initialized successfully!';
    RAISE NOTICE '📊 Tables created: users, transactions, investments, kyc_documents, wallets, platform_wallets, audit_logs';
    RAISE NOTICE '🔍 Indexes created for optimal performance';
    RAISE NOTICE '⚡ Triggers enabled for automatic timestamp updates';
    RAISE NOTICE '👑 Super admin user created (password will be set by application)';
END $$;
