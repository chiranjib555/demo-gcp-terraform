-- Test Customers table
CREATE TABLE Customers (
    Id INT PRIMARY KEY,
    Name NVARCHAR(100),
    Email NVARCHAR(100)
);
GO

INSERT INTO Customers (Id, Name, Email) VALUES 
(1, 'John Doe', 'john@example.com'),
(2, 'Jane Smith', 'jane@example.com'),
(3, 'Bob Johnson', 'bob@example.com');
GO

SELECT * FROM Customers;
GO
