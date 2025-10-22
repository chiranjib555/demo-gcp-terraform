-- init-database.sql
-- Idempotent SQL Server initialization script
-- Creates database, login, user, and grants permissions

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

-- Switch to the database
USE [DemoDB];
GO

-- Create login at server level if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = N'ci_user')
BEGIN
    CREATE LOGIN [ci_user] WITH PASSWORD = N'$(CI_PASSWORD)';
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

-- Optional: Create a sample table to verify deployment
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DeploymentLog]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[DeploymentLog] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [DeployedAt] DATETIME2 DEFAULT GETDATE(),
        [Version] NVARCHAR(50),
        [Notes] NVARCHAR(MAX)
    );
    PRINT 'Created DeploymentLog table.';
END
ELSE
BEGIN
    PRINT 'DeploymentLog table already exists.';
END
GO

-- Log this deployment
INSERT INTO [dbo].[DeploymentLog] ([Version], [Notes])
VALUES (N'$(VERSION)', N'Deployed via GitHub Actions');
PRINT 'Deployment logged.';
GO
