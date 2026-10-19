-- Generated 2025-08-20T20:40:49.480869 by SQLite→MSSQL converter
SET NOCOUNT ON;
GO
IF OBJECT_ID(N'[courses]', N'U') IS NOT NULL DROP TABLE [courses];
GO
CREATE TABLE [courses] (
    [course_id] INT,
    [title] NVARCHAR(MAX),
    [category] NVARCHAR(MAX),
    [published_date] NVARCHAR(MAX)
);
GO
IF OBJECT_ID(N'[instructors]', N'U') IS NOT NULL DROP TABLE [instructors];
GO
CREATE TABLE [instructors] (
    [instructor_id] INT,
    [name] NVARCHAR(MAX),
    [expertise] NVARCHAR(MAX)
);
GO
IF OBJECT_ID(N'[subscriptions]', N'U') IS NOT NULL DROP TABLE [subscriptions];
GO
CREATE TABLE [subscriptions] (
    [subscription_id] INT,
    [user_id] INT,
    [course_id] INT,
    [subscription_date] NVARCHAR(MAX)
);
GO
IF OBJECT_ID(N'[users]', N'U') IS NOT NULL DROP TABLE [users];
GO
CREATE TABLE [users] (
    [user_id] INT,
    [name] NVARCHAR(MAX),
    [email] NVARCHAR(MAX),
    [registration_date] NVARCHAR(MAX)
);
GO
-- Foreign keys
-- Unique indexes
INSERT INTO [courses] ([course_id], [title], [category], [published_date]) VALUES (101, N'Introducción a SQL', N'Data Science', N'2023-01-10');
INSERT INTO [courses] ([course_id], [title], [category], [published_date]) VALUES (102, N'Machine Learning con Python', N'AI', N'2023-04-22');
INSERT INTO [courses] ([course_id], [title], [category], [published_date]) VALUES (103, N'Visualización de Datos', N'Data Viz', N'2023-06-30');
GO
INSERT INTO [instructors] ([instructor_id], [name], [expertise]) VALUES (201, N'Carlos Díaz', N'SQL y Bases de Datos');
INSERT INTO [instructors] ([instructor_id], [name], [expertise]) VALUES (202, N'María Torres', N'Machine Learning');
GO
INSERT INTO [subscriptions] ([subscription_id], [user_id], [course_id], [subscription_date]) VALUES (1001, 1, 101, N'2023-07-01');
INSERT INTO [subscriptions] ([subscription_id], [user_id], [course_id], [subscription_date]) VALUES (1002, 2, 101, N'2023-07-03');
INSERT INTO [subscriptions] ([subscription_id], [user_id], [course_id], [subscription_date]) VALUES (1003, 1, 102, N'2023-07-20');
INSERT INTO [subscriptions] ([subscription_id], [user_id], [course_id], [subscription_date]) VALUES (1004, 3, 103, N'2023-08-21');
GO
INSERT INTO [users] ([user_id], [name], [email], [registration_date]) VALUES (1, N'Ana Martínez', N'ana@example.com', N'2023-06-15');
INSERT INTO [users] ([user_id], [name], [email], [registration_date]) VALUES (2, N'Juan Pérez', N'juan@example.com', N'2023-07-01');
INSERT INTO [users] ([user_id], [name], [email], [registration_date]) VALUES (3, N'Lucía Gómez', N'lucia@example.com', N'2023-08-20');
GO
