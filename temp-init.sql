-- Quick database initialization script
-- Create database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'DemoDB')
BEGIN
    CREATE DATABASE [DemoDB];
    PRINT 'Database DemoDB created.';
END
ELSE
BEGIN
    PRINT 'Database DemoDB already exists.';
END
GO

USE [DemoDB];
GO

-- Create login at server level if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = N'ci_user')
BEGIN
    -- Note: Replace $(CI_PASSWORD) with your actual password variable if using a different mechanism.
    CREATE LOGIN [ci_user] WITH PASSWORD = N'$(CI_PASSWORD)', CHECK_POLICY=OFF;
    PRINT 'Login ci_user created.';
END
ELSE
BEGIN
    PRINT 'Login ci_user already exists.';
END
GO

-- Create user in database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = N'ci_user')
BEGIN
    CREATE USER [ci_user] FOR LOGIN [ci_user];
    PRINT 'User ci_user created in DemoDB.';
END
ELSE
BEGIN
    PRINT 'User ci_user already exists in DemoDB.';
END
GO

-- Grant db_owner role to ci_user (idempotent)
IF IS_ROLEMEMBER('db_owner', 'ci_user') = 0
BEGIN
    EXEC sp_addrolemember N'db_owner', N'ci_user';
    PRINT 'Granted db_owner role to ci_user.';
END
ELSE
BEGIN
    PRINT 'ci_user already has db_owner role.';
END
GO

PRINT 'Database initialization complete!';
GO
