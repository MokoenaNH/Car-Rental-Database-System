**🚗 Car Rental Database System 📊**

**🌟 Overview**

This project is a car rental database system designed to help manage rentals, customers, employees, and branches. It’s perfect for learning how databases work in real-world businesses!


**✨ Key Features**

    ✔ Vehicle Management – Track car details, availability, and maintenance.
    
    ✔ Customer Records – Store customer info, rentals, and payments.
    
    ✔ Branch Operations – Manage different rental locations.
    
    ✔ Automated Calculations – Rental costs, late fees, and vehicle availability.
    
    ✔ Easy Search – Find cars, customers, and employees quickly.
    


**🗂 Database Tables**


    Table Name	                    Description
    🚗 Vehicle	                    Car details (ID, color, type, price, mileage)
    🏠 Address	                    Branch and customer addresses
    🏢 Branch	                    Rental locations and contact info
    👨‍💼 Employee	                    Staff details (name, role, branch)
    👥 Customer	                    Customer info (name, contact, age)
    📝 Rental_transaction	            Rental records (dates, costs, status)
    🔧 Vehicle_maintenance	            Car service history
    💳 Banking_information	            Customer payment details



**🔍 Cool Views (Predefined Queries)**

    🚗 Popular_Vehicles – Most rented cars.
    
    ✅ Available_vehicles – Cars ready for rent.
    
    ⏰ Overdue_Rentals – Late returns.
    
    💰 Revenue_Summary – Daily earnings.
    
    👤 Customer_Rentals – Rental history per customer.


**📝 Example Queries**

Find all available red sedans:
    
    SELECT * FROM Available_sedans WHERE VEHICLE_COLOUR = 'Red';
    
Show managers:
    
    SELECT * FROM Search_Employees;
    
Calculate total revenue:
    
    SELECT SUM(RENTAL_COST) AS "Total Money Made!" FROM Rental_transaction;

**👥 Contributors**

  **Group 12 – North-West University**
    
    Neo Mokoena (Project Leader)
    
    Nentsianane M. (BI Analyst)
    
    Silindile N. (Data Scientist)
    
    Mogomotsi T. (SQL Developer)
    
    Resego M. (Data Architect)
    
    Yola M. (Data Engineer)
    
    Siboniso S. (Data Analyst)

**📌 Project Phases**

    Phase 1 – Planning & Research 📋
    
    Phase 2 – Database Design ✏️
    
    Phase 3 – Building & Testing 🛠
