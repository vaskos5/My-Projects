CREATE DATABASE SQLProject_VaskoStojanoski
GO

USE SQLProject_VaskoStojanoski
GO

CREATE TABLE SeniorityLevel
(
	ID INT IDENTITY(1,1) NOT NULL,
	[Name] NVARCHAR(100) NOT NULL,
	CONSTRAINT PK_SeniorityLevel_ID PRIMARY KEY CLUSTERED (ID)
)
GO

INSERT INTO SeniorityLevel ([Name])
VALUES ('Junior'), ('Intermediate'), ('Senor'), ('Lead'), ('Project Manager'), ('Division Manager'), ('Office Manager'), ('CEO'), ('CTO'), ('CIO')
GO

CREATE TABLE [Location]
(
	ID INT IDENTITY(1,1) NOT NULL,
	CountryName NVARCHAR(100) NULL,
	Continent NVARCHAR(100) NULL,
	Region NVARCHAR(100) NULL,
	CONSTRAINT PK_Location_ID PRIMARY KEY CLUSTERED (ID)
)
GO

iNSERT INTO [Location] (CountryName, Continent, Region)
SELECT CountryName, Continent, Region
FROM WideWorldImporters.Application.Countries
GO

CREATE TABLE Department
(
	ID INT IDENTITY(1,1) NOT NULL,
	[Name] NVARCHAR(100) NOT NULL,
	CONSTRAINT PK_Department_ID PRIMARY KEY CLUSTERED (ID)
)
GO

INSERT INTO Department ([Name])
VALUES	('Personal Banking & Operations'),
		('Digital Banking Department'),
		('Retail Banking & Marketing Department'),
		('Wealth Management & Third Party Products'),
		('International Banking Division & DFB'),
		('Treasury'),
		('Information Technology'),
		('Corporate Communications'),
		('Support Services & Brunch Expansion'),
		('Human Resources')
GO

CREATE TABLE Employee
(
	ID INT IDENTITY(1,1),
	FirstName NVARCHAR(100),
	LastName NVARCHAR(100),
	LocationID INT,
	SeniorityLevelID INT,
	DepartmentID INT,
	CONSTRAINT PK_Employee_ID PRIMARY KEY CLUSTERED (ID),
	CONSTRAINT FK_LocationID FOREIGN KEY (LocationID) REFERENCES [Location] (ID),
	CONSTRAINT FK_SeniorityLevelID FOREIGN KEY (SeniorityLevelID) REFERENCES [SeniorityLevel] (ID),
	CONSTRAINT FK_DepartmentID FOREIGN KEY (DepartmentID) REFERENCES [Department] (ID)
)
GO

INSERT INTO Employee (FirstName, LastName)
SELECT SUBSTRING(FullName, 1, CHARINDEX(' ', FullName)-1),
SUBSTRING(FullName, CHARINDEX(' ', FullName)+1, LEN(FullName))
FROM WideWorldImporters.Application.People
GO

;WITH CTE AS (
	SELECT ID,
	NTILE(10) OVER (ORDER BY ID) AS C1
	FROM Employee
)
UPDATE Employee
SET SeniorityLevelID = C1
FROM CTE
INNER JOIN Employee ON cte.ID = Employee.ID
GO

;WITH CTE AS (
	SELECT ID,
	NTILE(10) OVER (ORDER BY ID DESC) AS C2
	FROM Employee
)
UPDATE Employee
SET DepartmentID = C2
FROM CTE
INNER JOIN Employee ON cte.ID = Employee.ID
GO

;WITH CTE AS (
	SELECT ID,
	NTILE(190) OVER (ORDER BY ID DESC) AS C3
	FROM Employee
)
UPDATE Employee
SET LocationID = C3
FROM CTE
INNER JOIN Employee ON cte.ID = Employee.ID
GO

CREATE TABLE Salary
(
	ID BIGINT IDENTITY(1,1),
	EmployeeID INT,
	[Month] SMALLINT,
	[Year] SMALLINT,
	GrossAmount DECIMAL(18,2),
	NetAmount DECIMAL(18,2),
	RegularWorkAmount DECIMAL(18,2),
	BonusAmount DECIMAL(18,2),
	OvertimeAmount DECIMAL(18,2),
	VacationDays SMALLINT,
	SickLeaveDays SMALLINT,
	CONSTRAINT PK_Salary_ID PRIMARY KEY CLUSTERED (ID),
	CONSTRAINT FK_EmployeeID FOREIGN KEY (EmployeeID) REFERENCES [Employee] (ID)
)
GO

WITH YearCTE AS (
    SELECT 2001 AS [Year]
    UNION ALL
    SELECT [Year] + 1
    FROM YearCTE
    WHERE [Year] < 2020
)
SELECT Year
INTO #Year
FROM YearCTE
OPTION (MAXRECURSION 0)
GO

WITH MonthCTE AS (
    SELECT 1 AS [Month]
    UNION ALL
    SELECT [Month] + 1
    FROM MonthCTE
    WHERE [Month] < 12
)
SELECT Month
INTO #Month
FROM MonthCTE
OPTION (MAXRECURSION 0)
GO

INSERT INTO Salary (EmployeeID, Month, Year)
SELECT e.ID, m.Month, y.Year
FROM Employee AS e
CROSS JOIN #Month AS m
CROSS JOIN #Year AS y
ORDER BY e.ID, y.Year, m.Month
GO

UPDATE Salary
SET GrossAmount = ABS(CHECKSUM(NEWID())) % 30001 + 30000
GO

UPDATE Salary
SET NetAmount = 0.90 * GrossAmount
GO

UPDATE Salary
SET RegularWorkAmount = 0.80 * NetAmount
GO

UPDATE Salary
SET BonusAmount = NetAmount - RegularWorkAmount
WHERE Month % 2 = 1
GO

UPDATE Salary
SET OvertimeAmount = NetAmount - RegularWorkAmount
WHERE Month % 2 = 0
GO

UPDATE Salary
SET VacationDays = 10
WHERE Month IN (7, 12)
GO

update dbo.salary set vacationDays = vacationDays + (EmployeeId % 2)
where  (employeeId + MONTH+ year)%5 = 1
GO

update dbo.salary set SickLeaveDays = EmployeeId%8, vacationDays = vacationDays + (EmployeeId % 3)
where  (employeeId + MONTH+ year)%5 = 2
GO

select * from dbo.salary 
where NetAmount <> (regularWorkAmount + BonusAmount + OverTimeAmount)