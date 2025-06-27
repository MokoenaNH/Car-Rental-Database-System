-- Drop existing database if it exists
DROP DATABASE IF EXISTS CARRENTALDB;

-- Create database
CREATE DATABASE CARRENTALDB;
USE CARRENTALDB;

----------
-- TABLE--
----------

CREATE TABLE Vehicle(
    VEHICLE_ID INT PRIMARY KEY,
    VEHICLE_COLOUR VARCHAR(10),
    VEHICLE_TYPE VARCHAR(15),
    AVAILABILTY_ID INT,
    VEHICLE_MILEAGE DECIMAL(10, 2),
    VEHICLE_RENTAL_PRICE DECIMAL(10, 2),
    MAINTENANCE_ID INT
);

CREATE TABLE Address(
    ADDRESS_ID INT PRIMARY KEY,
    STREET_NAME VARCHAR(20),
    CITY VARCHAR(20),
    PROVINCE VARCHAR(20),
    POSTAL_CODE VARCHAR(4)
);

CREATE TABLE Branch(
    BRANCH_ID INT PRIMARY KEY,
    ADDRESS_ID INT,
    FOREIGN KEY(ADDRESS_ID) REFERENCES Address(ADDRESS_ID) ON DELETE SET NULL,
    BRANCH_PHONE VARCHAR(10),
    BRANCH_EMAIL VARCHAR(50),
    MANAGER_ID INT
);

CREATE TABLE Employee(
    EMPLOYEE_ID INT PRIMARY KEY,
    EMPLOYEE_NAME VARCHAR(20),
    EMPLOYEE_SURNAME VARCHAR(20),
    EMPLOYEE_PHONE VARCHAR(10),
    EMPLOYEE_EMAIL VARCHAR(50),
    EMPLOYEE_POSITION VARCHAR(15),
    BRANCH_ID INT,
    FOREIGN KEY(BRANCH_ID) REFERENCES Branch(BRANCH_ID) ON DELETE SET NULL
);

CREATE TABLE Customer(
    CUSTOMER_ID INT PRIMARY KEY,
    CUSTOMER_NAME VARCHAR(20),
    CUSTOMER_SURNAME VARCHAR(20),
    CUSTOMER_PHONE VARCHAR(10),
    CUSTOMER_EMAIL VARCHAR(50),
    ADDRESS_ID INT,
    FOREIGN KEY(ADDRESS_ID) REFERENCES Address(ADDRESS_ID) ON DELETE SET NULL,
    CUSTOMER_DATE_OF_BIRTH DATE NOT NULL,
    CUSTOMER_AGE DECIMAL(5, 0),
    AGENT_ID INT,
    FOREIGN KEY(AGENT_ID) REFERENCES Employee(EMPLOYEE_ID) ON DELETE SET NULL
);


CREATE TABLE Rental_transaction(
    RENTAL_ID INT PRIMARY KEY,
    CUSTOMER_ID INT,
    FOREIGN KEY(CUSTOMER_ID) REFERENCES Customer(CUSTOMER_ID) ON DELETE SET NULL,
    VEHICLE_ID INT,
    FOREIGN KEY(VEHICLE_ID) REFERENCES Vehicle(VEHICLE_ID) ON DELETE SET NULL,
    AGENT_ID INT,
    FOREIGN KEY(AGENT_ID) REFERENCES Employee(EMPLOYEE_ID) ON DELETE SET NULL,
    RENTAL_START_DATE DATE,
    RENTAL_END_DATE DATE,
    RENTAL_DURATION_IN_DAYS INT AS (DATEDIFF(RENTAL_END_DATE, RENTAL_START_DATE)),
    RENTAL_COST DECIMAL(10, 2),
    LATE_FEE_RATE DECIMAL(5, 2) DEFAULT 100.00,
    RENTAL_STATUS VARCHAR(15) DEFAULT 'Rented'
);

CREATE TABLE Vehicle_maintenance(
    MAINTENANCE_ID INT,
    VEHICLE_ID INT,
    PRIMARY KEY(MAINTENANCE_ID, VEHICLE_ID),
    FOREIGN KEY(VEHICLE_ID) REFERENCES Vehicle(VEHICLE_ID),
    MAINTANACE_TYPE VARCHAR(15),
    MECHANIC_ID INT,
    FOREIGN KEY(MECHANIC_ID) REFERENCES Employee(EMPLOYEE_ID) ON DELETE SET NULL,
    MAINTANACE_DATE DATE,
    UNIQUE(MAINTENANCE_ID)
);

CREATE TABLE Vehicle_availability(
    AVAILABILITY_ID INT,
    VEHICLE_ID INT,
    PRIMARY KEY(AVAILABILITY_ID, VEHICLE_ID),
    FOREIGN KEY(VEHICLE_ID) REFERENCES Vehicle(VEHICLE_ID),
    VEHICLE_CONDITION VARCHAR(10),
    VEHICLE_AVAILABILITY VARCHAR(15),
    UNIQUE(VEHICLE_ID),
    UNIQUE(AVAILABILITY_ID)
);

CREATE TABLE Card(
    CARD_NUMBER VARCHAR(16) PRIMARY KEY,
    EXPIRATION_DATE DATE
);

CREATE TABLE Banking_information(
    CUSTOMER_ID INT PRIMARY KEY,
    BANK_NAME VARCHAR(20),
    CARD_NUMBER VARCHAR(16),
    FOREIGN KEY(CARD_NUMBER) REFERENCES Card(CARD_NUMBER),
    ACCOUNT_NUMBER VARCHAR(10),
    ACCOUNT_TYPE VARCHAR(10)
);

ALTER TABLE Vehicle
ADD CHECK (VEHICLE_RENTAL_PRICE >= 0);

ALTER TABLE Vehicle
ADD FOREIGN KEY(AVAILABILTY_ID) REFERENCES Vehicle_availability(AVAILABILITY_ID) 
ON DELETE SET NULL;

ALTER TABLE Vehicle
ADD FOREIGN KEY(MAINTENANCE_ID) REFERENCES Vehicle_maintenance(MAINTENANCE_ID)
ON DELETE SET NULL;

ALTER TABLE Vehicle
ADD VEHICLE_MAKE VARCHAR(15);

-- Updates BRANCH_ID values in Employee table
UPDATE Employee
SET BRANCH_ID = 2
WHERE EMPLOYEE_ID = 101;

UPDATE Employee
SET BRANCH_ID = 3
WHERE EMPLOYEE_ID = 102;

UPDATE Employee
SET BRANCH_ID = 1
WHERE EMPLOYEE_ID = 103;

-- Getting the customer's age
UPDATE Customer c
SET CUSTOMER_AGE = (TRUNCATE(DATEDIFF(CURRENT_DATE, c.CUSTOMER_DATE_OF_BIRTH)/365, 0));

ALTER TABLE Branch
ADD FOREIGN KEY(MANAGER_ID) REFERENCES Employee(EMPLOYEE_ID) 
ON DELETE SET NULL;

ALTER TABLE Branch
ADD BRANCH_NAME VARCHAR(20);

-- Determines the rental cost when there is a late fee
UPDATE Rental_transaction rt
SET RENTAL_COST = (SELECT v.VEHICLE_RENTAL_PRICE + (DATEDIFF(CURRENT_DATE, rt.RENTAL_END_DATE) * rt.LATE_FEE_RATE)
                   FROM Vehicle v
                   WHERE v.VEHICLE_ID = rt.VEHICLE_ID AND rt.RENTAL_STATUS = 'Returned');

-- Determines the rental cost when there is no a late fee
UPDATE Rental_transaction rt
SET RENTAL_COST = (SELECT v.VEHICLE_RENTAL_PRICE
                   FROM Vehicle v
                   WHERE v.VEHICLE_ID = rt.VEHICLE_ID AND rt.RENTAL_STATUS = 'Returned');

ALTER TABLE Rental_transaction
ADD CHECK (RENTAL_COST >= 0);

-- determines vehicle availability 
UPDATE Vehicle_availability va
SET VEHICLE_AVAILABILITY = 'Available'
WHERE va.VEHICLE_CONDITION = 'Good' 
AND EXISTS (SELECT 1 FROM Rental_transaction rt 
            WHERE rt.RENTAL_STATUS = 'Returned');

UPDATE Vehicle_availability va
SET VEHICLE_AVAILABILITY = 'Not available'
WHERE va.VEHICLE_CONDITION = 'Bad' 
OR EXISTS (SELECT 1 FROM Rental_transaction rt 
            WHERE rt.RENTAL_STATUS = 'Not returned');

----------------------
-- VIEWS AND QUERIES--
----------------------

-- creates a view to identify the most frequently rented vehicles
CREATE VIEW Popular_Vehicles AS
SELECT v.VEHICLE_TYPE, COUNT(rt.RENTAL_ID) AS Rental_Count
FROM Rental_transaction rt
JOIN Vehicle v ON rt.VEHICLE_ID = v.VEHICLE_ID
GROUP BY v.VEHICLE_TYPE
ORDER BY Rental_Count DESC;

-- creates a view to show vehicles tha are available for rent
CREATE VIEW Available_vehicles AS
SELECT v.VEHICLE_ID, v.VEHICLE_TYPE, v.VEHICLE_COLOUR
FROM Vehicle v
WHERE v.VEHICLE_ID IN (
    #subquery
    SELECT va.VEHICLE_ID
    FROM Vehicle_availability va
    WHERE va.VEHICLE_AVAILABILITY = 'Available'
);

-- creates a view to show all rentals that have exceeded their return date
CREATE VIEW Overdue_Rentals AS
SELECT rt.RENTAL_ID, rt.RENTAL_END_DATE, v.VEHICLE_TYPE, v.VEHICLE_COLOUR, c.CUSTOMER_NAME, c.CUSTOMER_SURNAME
FROM Rental_transaction rt
JOIN Vehicle v ON rt.VEHICLE_ID = v.VEHICLE_ID
JOIN Customer c ON rt.CUSTOMER_ID = c.CUSTOMER_ID
WHERE rt.RENTAL_END_DATE < CURRENT_DATE;

-- creates a view to show the revenue generated over a specific period
CREATE VIEW Revenue_Summary AS
SELECT SUM(rt.RENTAL_COST) AS Total_Revenue, 
       DATE(rt.RENTAL_START_DATE) AS Rental_Date
FROM Rental_transaction rt
GROUP BY Rental_Date;

-- creates view on all rentals associated with a specific vustomer
CREATE VIEW Customer_Rentals AS
SELECT rt.RENTAL_ID, rt.RENTAL_START_DATE, rt.RENTAL_END_DATE, v.VEHICLE_TYPE, v.VEHICLE_COLOUR
FROM Rental_transaction rt
JOIN Vehicle v ON rt.VEHICLE_ID = v.VEHICLE_ID
JOIN Customer c ON rt.CUSTOMER_ID = c.CUSTOMER_ID;

-- creates a view to show rental dates where the total revenue exceeds R5000
CREATE VIEW Total_Revenue_Per_Day_over_R5000 AS
SELECT DATE(rt.RENTAL_START_DATE) AS Rental_Date, SUM(rt.RENTAL_COST) AS Total_Revenue
FROM Rental_transaction rt
GROUP BY Rental_Date
HAVING SUM(rt.RENTAL_COST) > 5000; -- HAVING clause

-- Creates a view that shows all managers
CREATE VIEW Search_Employees AS
SELECT EMPLOYEE_ID, EMPLOYEE_NAME, EMPLOYEE_SURNAME, EMPLOYEE_PHONE, EMPLOYEE_EMAIL
FROM Employee
WHERE EMPLOYEE_POSITION LIKE '%Manager%';

-- Creates a view that shows searches for vehicles with specific attributes
CREATE VIEW Search_Vehicles AS
SELECT v.VEHICLE_ID, v.VEHICLE_TYPE, v.VEHICLE_COLOUR, va.VEHICLE_AVAILABILITY
FROM Vehicle v
JOIN Vehicle_availability va ON v.VEHICLE_ID = va.VEHICLE_ID
WHERE v.VEHICLE_TYPE LIKE '%sedan%' OR v.VEHICLE_COLOUR = 'Red';

-- Creates a view to show all available vehicles with a specific atrribute(type = sedan)
CREATE VIEW Available_sedans AS
SELECT v.VEHICLE_ID, v.VEHICLE_TYPE, v.VEHICLE_COLOUR, v.VEHICLE_RENTAL_PRICE
FROM Vehicle v
JOIN Vehicle_availability va ON v.VEHICLE_ID = va.VEHICLE_ID
WHERE v.VEHICLE_TYPE = 'Sedan' AND va.VEHICLE_AVAILABILITY = 'Available';


-- Limitations of rows and columns
-- Limits the result to 10 rows
SELECT VEHICLE_ID,EHICLE_COLOUR,VEHICLE_TYPE,AVAILABILTY_ID,VEHICLE_MILEAGE,VEHICLE_RENTAL_PRICE,MAINTENANCE_ID From Vehicle  LIMIT 2; -- Limits the result to 10 rows

--  Sorting
 -- Sorts the result by last name in ascending order
SELECT EMPLOYEE_NAME, EMPLOYEE_SURNAME
FROM Employee
ORDER BY EMPLOYEE_SURNAME ASC;

-- LIKE, AND, and OR
SELECT CUSTOMER_NAME, CUSTOMER_SURNAME
FROM Custoner
WHERE CUSTOMER_NAME LIKE 'A%' AND CUSTOMER_SURNAME = 'Brown' OR CUSTOMER_SURNAME = 'Wilson';

-- Variables and character functions:
SET @var_name := 'Sedan';
SELECT VEHICLE_TYPE, CHAR_LENGTH(VEHICLE_TYPE) AS name_length
FROM Vehicle
WHERE VEHICLE_TYPE = @var_name;

-- Round or trunc
SELECT ROUND(VEHICLE_RENTAL_PRICE, 2) AS rounded_amount
FROM Vehicle; 

-- Date functions
SELECT RENTAL_START_DATE, YEAR(RENTAL_START_DATE) AS rental_year
FROM Rental
WHERE YEAR(RENTAL_START_DATE) = 2019;

-- Aggregate functions
SELECT COUNT(*), AVG(VEHICLE_RENTAL_PRICE), MAX(VEHICLE_RENTAL_PRICE), MIN(VEHICLE_RENTAL_PRICE)
FROM Vehicle;

-- Sub-queries
SELECT CUSTOMER_ID, (SELECT AVG(RENTAL_COST) FROM Rental_transaction) AS avg_salary
FROM Rental_transaction;

-----------
-- INDEXES--
-----------

CREATE INDEX VEHICLE_INDEX ON Vehicle(VEHICLE_TYPE);

CREATE INDEX PRICE_INDEX ON Vehicle(VEHICLE_RENTAL_PRICE);

CREATE INDEX EMPLOYEE_INDEX ON Employee(EMPLOYEE_NAME, EMPLOYEE_SURNAME);

CREATE INDEX BRANCH_INDEX ON Branch(BRANCH_NAME);

CREATE INDEX CITY_INDEX ON Address(CITY);

CREATE INDEX PROVINCE_INDEX ON Address(PROVINCE);

CREATE INDEX CUSTOMER_INDEX ON Customer(CUSTOMER_NAME, CUSTOMER_SURNAME);

-------------------------
-- POPULATING THE TABLES--
-------------------------

-- Insert sample data into Address table
INSERT INTO Address (ADDRESS_ID, STREET_NAME, CITY, PROVINCE, POSTAL_CODE) 
VALUES 
(1, '123 Main Street', 'Johannesburg', 'Gauteng', '2000'),
(2, '456 Oak Avenue', 'Cape Town', 'Western Cape', '8001'),
(3, '789 Elm Street', 'Durban', 'KwaZulu-Natal', '4001');

-- Insert sample data into Employee table
INSERT INTO Employee (EMPLOYEE_ID, EMPLOYEE_NAME, EMPLOYEE_SURNAME, EMPLOYEE_PHONE, EMPLOYEE_EMAIL, EMPLOYEE_POSITION, BRANCH_ID) 
VALUES 
(101, 'John', 'Doe', '0111111111', 'john.doe@example.com', 'Manager', Null),
(102, 'Jane', 'Smith', '0212222222', 'jane.smith@example.com', 'Agent', null),
(103, 'Michael', 'Johnson', '031333333', 'michael.johnson@example.com', 'Mechanic', null);


-- Insert sample data into Branch table, ensuring MANAGER_ID references a valid employee
INSERT INTO Branch (BRANCH_ID, ADDRESS_ID, BRANCH_PHONE, BRANCH_EMAIL, MANAGER_ID, BRANCH_NAME) 
VALUES 
(1, 1, '0111234567', 'jhbbranch@example.com', 101, 'Johannesburg Branch'),
(2, 2, '0212345678', 'ctbranch@example.com', 102, 'Cape Town Branch'),
(3, 3, '0313456789', 'dbnbranch@example.com', 103, 'Durban Branch');

-- Insert sample data into Customer table
INSERT INTO Customer (CUSTOMER_ID, CUSTOMER_NAME, CUSTOMER_SURNAME, CUSTOMER_PHONE, CUSTOMER_EMAIL, ADDRESS_ID, CUSTOMER_DATE_OF_BIRTH, AGENT_ID) 
VALUES 
(201, 'Alice', 'Brown', '0831112222', 'alice.brown@example.com', 1, '1980-05-15', 101),
(202, 'David', 'Wilson', '0822223333', 'david.wilson@example.com', 2, '1992-10-20', 102),
(203, 'Sarah', 'Taylor', '0843334444', 'sarah.taylor@example.com', 3, '1975-12-30', 103);

INSERT INTO Vehicle (VEHICLE_ID, VEHICLE_COLOUR, VEHICLE_TYPE, AVAILABILTY_ID, VEHICLE_MILEAGE, VEHICLE_RENTAL_PRICE, MAINTENANCE_ID, VEHICLE_MAKE) 
VALUES 
(301, 'Red', 'Sedan', NULL, 5000.23, 350.00, NULL, 'Toyota'),
(302, 'Blue', 'Compact', NULL, 4050.00, 150.00, NULL, 'Hyundai'),
(303, 'Black', 'SUV', NULL, 7235.67, 250.00, NULL, 'Ford');

-- Insert sample data into Vehicle_availability table
INSERT INTO Vehicle_availability (AVAILABILITY_ID, VEHICLE_ID, VEHICLE_CONDITION, VEHICLE_AVAILABILITY) 
VALUES 
(401, 301, 'Good', 'Available'),
(402, 302, 'Excellent', 'Available'),
(403, 303, 'Fair', 'Not available');

-- Insert sample data into Rental_transaction table
INSERT INTO Rental_transaction (RENTAL_ID, CUSTOMER_ID, VEHICLE_ID, AGENT_ID, RENTAL_START_DATE, RENTAL_END_DATE, RENTAL_COST, RENTAL_STATUS) 
VALUES 
(501, 201, 301, 101, '2024-05-01', '2024-05-07', 0.0, 'Returned'),
(502, 202, 302, 102, '2024-05-10', '2024-05-15', 0.0, 'Returned'),
(503, 203, 303, 103, '2024-05-05', '2024-05-12', 0.0, 'Not returned');

-- Insert sample data into Vehicle_maintenance table
INSERT INTO Vehicle_maintenance (MAINTENANCE_ID, VEHICLE_ID, MAINTANACE_TYPE, MECHANIC_ID, MAINTANACE_DATE) 
VALUES 
(601, 301, 'Oil change', 103, '2024-05-01'),
(602, 303, 'Tire rotation', 103, '2024-05-05');

-- Insert sample data into Card table
INSERT INTO Card (CARD_NUMBER, EXPIRATION_DATE) 
VALUES 
('1234567812345678', '2026-12-31'),
('9876543210987654', '2025-06-30');

-- Insert sample data into Banking_information table
INSERT INTO Banking_information (CUSTOMER_ID, BANK_NAME, CARD_NUMBER, ACCOUNT_NUMBER, ACCOUNT_TYPE) 
VALUES 
(201, 'ABC Bank', '1234567812345678', '1234567890', 'Savings'),
(202, 'XYZ Bank', '9876543210987654', '9876543210', 'Checking');

SELECT * 
From Vehicle;

SELECT * 
From Address;

SELECT * 
From Branch;

SELECT * 
From Employee;

SELECT * 
From Customer;

SELECT * 
From Rental_transaction;

SELECT * 
From Vehicle_maintenance;

SELECT * 
From Vehicle_availability;

SELECT * 
From Card;

SELECT * 
From Banking_information;

-- Limitations of rows and columns
-- Limits the result to 10 rows
SELECT VEHICLE_ID,VEHICLE_COLOUR,VEHICLE_TYPE,AVAILABILTY_ID,VEHICLE_MILEAGE,VEHICLE_RENTAL_PRICE,MAINTENANCE_ID From Vehicle  LIMIT 2; -- Limits the result to 10 rows

--  Sorting
 -- Sorts the result by last name in ascending order
SELECT EMPLOYEE_NAME, EMPLOYEE_SURNAME
FROM Employee
ORDER BY EMPLOYEE_SURNAME ASC;

-- LIKE, AND, and OR
SELECT CUSTOMER_NAME, CUSTOMER_SURNAME
FROM Customer
WHERE CUSTOMER_NAME LIKE 'A%' AND CUSTOMER_SURNAME = 'Brown' OR CUSTOMER_SURNAME = 'Wilson';

-- Variables and character functions:
SET @var_name := 'Sedan';
SELECT VEHICLE_TYPE, CHAR_LENGTH(VEHICLE_TYPE) AS name_length
FROM Vehicle
WHERE VEHICLE_TYPE = @var_name;

-- Round or trunc
SELECT ROUND(VEHICLE_RENTAL_PRICE, 2) AS rounded_amount
FROM Vehicle; 

-- Date functions
SELECT RENTAL_START_DATE, YEAR(RENTAL_START_DATE) AS rental_year
FROM Rental
WHERE YEAR(RENTAL_START_DATE) = 2019;

-- Aggregate functions
SELECT COUNT(*), AVG(VEHICLE_RENTAL_PRICE), MAX(VEHICLE_RENTAL_PRICE), MIN(VEHICLE_RENTAL_PRICE)
FROM Vehicle;

-- Sub-queries
SELECT CUSTOMER_ID, (SELECT AVG(RENTAL_COST) FROM Rental_transaction) AS avg_salary
FROM Rental_transaction;



