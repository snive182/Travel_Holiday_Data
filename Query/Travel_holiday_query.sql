-- Inspecting data
SELECT * FROM travel LIMIT 10;

-- Check for missing values in key columns
SELECT 
    COUNT(*) - COUNT(ProdTaken) AS missing_ProdTaken,
    COUNT(*) - COUNT(Age) AS missing_Age,
    COUNT(*) - COUNT(MonthlyIncome) AS missing_MonthlyIncome,
    COUNT(*) - COUNT(DurationOfPitch) AS missing_DurationOfPitch,
    COUNT(*) - COUNT(Occupation) AS missing_Occupation
FROM travel;

-- Check data distribution for categorical variables
SELECT TypeofContact, COUNT(*) AS count 
FROM travel 
GROUP BY TypeofContact;

SELECT Occupation, COUNT(*) AS count 
FROM travel 
GROUP BY Occupation;

SELECT Gender, COUNT(*) AS count 
FROM travel 
GROUP BY Gender;

-- Fix inconsistent gender values
UPDATE travel_customers 
SET Gender = 'Female' 
WHERE Gender IN ('Fe Male', 'FeMale');

-- Handle missing Age values (impute with median)
SET @median_age = (SELECT AVG(Age) FROM travel WHERE Age IS NOT NULL);

UPDATE travel 
SET Age = @median_age 
WHERE Age IS NULL;

-- Handle missing MonthlyIncome (impute with median by occupation)
CREATE TEMPORARY TABLE occupation_income AS
SELECT Occupation, AVG(MonthlyIncome) AS avg_income
FROM travel 
WHERE MonthlyIncome IS NOT NULL 
GROUP BY Occupation;

UPDATE travel tc
JOIN occupation_income oi ON tc.Occupation = oi.Occupation
SET tc.MonthlyIncome = oi.avg_income
WHERE tc.MonthlyIncome IS NULL;

-- Handle missing DurationOfPitch (impute with overall median)
SET @median_pitch = (SELECT AVG(DurationOfPitch) FROM travel WHERE DurationOfPitch IS NOT NULL);

UPDATE travel 
SET DurationOfPitch = @median_pitch 
WHERE DurationOfPitch IS NULL;

-- Add age groups
ALTER TABLE travel ADD COLUMN AgeGroup VARCHAR(20);

UPDATE travel
SET AgeGroup = CASE 
    WHEN Age < 30 THEN 'Young'
    WHEN Age BETWEEN 30 AND 45 THEN 'Middle-aged'
    WHEN Age > 45 THEN 'Senior'
    ELSE 'Unknown'
END;

-- Add income categories
ALTER TABLE travel ADD COLUMN IncomeCategory VARCHAR(20);

UPDATE travel 
SET IncomeCategory = CASE 
    WHEN MonthlyIncome < 20000 THEN 'Low'
    WHEN MonthlyIncome BETWEEN 20000 AND 40000 THEN 'Medium'
    WHEN MonthlyIncome > 40000 THEN 'High'
    ELSE 'Unknown'
END;

-- Create family size feature
ALTER TABLE travel ADD COLUMN FamilySize INT;

UPDATE travel 
SET FamilySize = NumberOfPersonVisiting + NumberOfChildrenVisiting;

-- Conversion rate analysis
SELECT 
    ProdTaken,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM travel), 2) AS percentage
FROM travel
GROUP BY ProdTaken;

-- Conversion rate by occupation
SELECT 
    Occupation,
    COUNT(*) AS total_customers,
    SUM(ProdTaken) AS conversions,
    ROUND(SUM(ProdTaken) * 100.0 / COUNT(*), 2) AS conversion_rate
FROM travel
GROUP BY Occupation 
ORDER BY conversion_rate DESC;

-- Average income by product taken
SELECT 
    ProdTaken,
    AVG(MonthlyIncome) AS avg_income,
    AVG(Age) AS avg_age
FROM travel 
GROUP BY ProdTaken;

-- Most successful product types
SELECT 
    ProductPitched,
    COUNT(*) AS total_offers,
    SUM(ProdTaken) AS accepted_offers,
    ROUND(SUM(ProdTaken) * 100.0 / COUNT(*), 2) AS success_rate
FROM travel
GROUP BY ProductPitched 
ORDER BY success_rate DESC;

-- Create a view for analysis-ready data
CREATE VIEW cleaned_travel_data AS
SELECT 
    CustomerID,
    ProdTaken,
    Age,
    AgeGroup,
    TypeofContact,
    CityTier,
    DurationOfPitch,
    Occupation,
    Gender,
    NumberOfPersonVisiting,
    NumberOfFollowups,
    ProductPitched,
    PreferredPropertyStar,
    MaritalStatus,
    NumberOfTrips,
    Passport,
    PitchSatisfactionScore,
    OwnCar,
    NumberOfChildrenVisiting,
    FamilySize,
    Designation,
    MonthlyIncome,
    IncomeCategory
FROM travel;

-- Verify no null values in key columns
SELECT 
    COUNT(*) AS total_records,
    SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS null_age,
    SUM(CASE WHEN MonthlyIncome IS NULL THEN 1 ELSE 0 END) AS null_income,
    SUM(CASE WHEN DurationOfPitch IS NULL THEN 1 ELSE 0 END) AS null_pitch
FROM travel;

-- Check data ranges for sanity
SELECT 
    MIN(Age) AS min_age,
    MAX(Age) AS max_age,
    MIN(MonthlyIncome) AS min_income,
    MAX(MonthlyIncome) AS max_income,
    MIN(DurationOfPitch) AS min_pitch,
    MAX(DurationOfPitch) AS max_pitch
FROM travel;