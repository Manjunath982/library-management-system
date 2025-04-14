CREATE DATABASE `Library Management Ssystem`;
USE `Library Management System`;

CREATE TABLE Books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255),
    isbn VARCHAR(20) UNIQUE,
    published_year INT,
    total_copies INT DEFAULT 1,
    available_copies INT DEFAULT 1
);

CREATE TABLE Members (
    member_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    registration_date DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Borrowings (
    borrowing_id INT PRIMARY KEY AUTO_INCREMENT,
    member_id INT,
    book_id INT,
    borrow_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    due_date DATETIME,
    return_date DATETIME,
    FOREIGN KEY (member_id) REFERENCES Members(member_id),
    FOREIGN KEY (book_id) REFERENCES Books(book_id)
);

CREATE TABLE Fines (
    fine_id INT PRIMARY KEY AUTO_INCREMENT,
    borrowing_id INT,
    fine_amount DECIMAL(5,2),
    paid BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (borrowing_id) REFERENCES Borrowings(borrowing_id)
);

INSERT INTO Books (title, author, isbn, published_year, total_copies, available_copies)
VALUES ('The Hobbit', 'J.R.R. Tolkien', '9780547928227', 1937, 3, 3);

INSERT INTO Members (full_name, email, phone) 
VALUES ('Alice Johnson', 'alice@example.com', '123-456-7890');

INSERT INTO Borrowings (member_id, book_id, due_date)
VALUES (1, 1, DATE_ADD(CURRENT_DATE, INTERVAL 14 DAY));

UPDATE Borrowings 
SET return_date = CURRENT_DATE 
WHERE borrowing_id = 1;

UPDATE Books 
SET available_copies = available_copies - 1 
WHERE book_id = 1 AND available_copies > 0;

UPDATE Books 
SET available_copies = available_copies + 1 
WHERE book_id = 1;

SELECT 
    B.borrowing_id,
    M.full_name,
    BK.title,
    B.due_date,
    DATEDIFF(CURRENT_DATE, B.due_date) AS days_overdue
FROM Borrowings B
JOIN Members M ON B.member_id = M.member_id
JOIN Books BK ON B.book_id = BK.book_id
WHERE B.return_date IS NULL AND B.due_date < CURRENT_DATE;

START TRANSACTION;

-- Step 1: Decrease available copies (only if available)
UPDATE Books 
SET available_copies = available_copies - 1 
WHERE book_id = 1 AND available_copies > 0;

-- Step 2: Insert borrowing record
INSERT INTO Borrowings (member_id, book_id, due_date)
VALUES (1, 1, DATE_ADD(CURRENT_DATE, INTERVAL 14 DAY));

COMMIT;

DELIMITER $$

CREATE TRIGGER decrease_copies_after_borrow
AFTER INSERT ON Borrowings
FOR EACH ROW
BEGIN
    UPDATE Books 
    SET available_copies = available_copies - 1
    WHERE book_id = NEW.book_id AND available_copies > 0;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER increase_copies_after_return
AFTER UPDATE ON Borrowings
FOR EACH ROW
BEGIN
    IF NEW.return_date IS NOT NULL AND OLD.return_date IS NULL THEN
        UPDATE Books 
        SET available_copies = available_copies + 1
        WHERE book_id = NEW.book_id;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER prevent_borrow_if_no_copies
BEFORE INSERT ON Borrowings
FOR EACH ROW
BEGIN
    DECLARE copies INT;
    SELECT available_copies INTO copies 
    FROM Books 
    WHERE book_id = NEW.book_id;
    
    IF copies <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No available copies for this book.';
    END IF;
END$$

DELIMITER ;


CREATE TABLE Categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE BookCategories (
    book_id INT,
    category_id INT,
    PRIMARY KEY (book_id, category_id),
    FOREIGN KEY (book_id) REFERENCES Books(book_id),
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);
INSERT INTO Categories (category_name) VALUES 
('Fantasy'), 
('Science Fiction'), 
('Mystery'), 
('Biography'), 
('Non-Fiction');

-- Assuming "The Hobbit" is book_id = 1 and "Fantasy" is category_id = 1
INSERT INTO BookCategories (book_id, category_id) 
VALUES (1, 1);

SELECT B.title, C.category_name
FROM Books B
JOIN BookCategories BC ON B.book_id = BC.book_id
JOIN Categories C ON BC.category_id = C.category_id
WHERE C.category_name = 'Fantasy';

-- Check the structure of all tables
SHOW TABLES;

-- Describe a specific table to check its structure
DESCRIBE Books;
DESCRIBE Members;
DESCRIBE Borrowings;
DESCRIBE Fines;
DESCRIBE Categories;
DESCRIBE BookCategories;

-- Check Books Table
SELECT * FROM Books;

-- Check Members Table
SELECT * FROM Members;

-- Check Borrowings Table
SELECT * FROM Borrowings;

-- Check Categories Table
SELECT * FROM Categories;

-- Check BookCategories Table (to verify books are linked to categories)
SELECT * FROM BookCategories;

-- Check available copies of the book before borrowing
SELECT title, available_copies FROM Books WHERE book_id = 1;

-- After borrowing the book, check again
SELECT title, available_copies FROM Books WHERE book_id = 1;

-- Check available copies after return (assuming borrowing_id = 1)
UPDATE Borrowings SET return_date = CURRENT_DATE WHERE borrowing_id = 1;

-- Check the books table to see if available_copies has increased
SELECT title, available_copies FROM Books WHERE book_id = 1;


-- Insert a new borrowing
INSERT INTO Borrowings (member_id, book_id, due_date)
VALUES (1, 1, DATE_ADD(CURRENT_DATE, INTERVAL 14 DAY));

-- Check available copies
SELECT title, available_copies FROM Books WHERE book_id = 1;

-- Update the return date
UPDATE Borrowings SET return_date = CURRENT_DATE WHERE borrowing_id = 2;

-- Check available copies
SELECT title, available_copies FROM Books WHERE book_id = 1;

-- Set available copies to 0 for testing
UPDATE Books SET available_copies = 5 WHERE book_id = 1;

-- Try to borrow a book (this should trigger an error due to the `prevent_borrow_if_no_copies` trigger)
INSERT INTO Borrowings (member_id, book_id, due_date)
VALUES (1, 1, DATE_ADD(CURRENT_DATE, INTERVAL 14 DAY));

-- Get books in the 'Fantasy' category
SELECT B.title, C.category_name
FROM Books B
JOIN BookCategories BC ON B.book_id = BC.book_id
JOIN Categories C ON BC.category_id = C.category_id
WHERE C.category_name = 'Fantasy';


-- Get overdue borrowings
SELECT 
    B.borrowing_id,
    M.full_name,
    BK.title,
    B.due_date,
    DATEDIFF(CURRENT_DATE, B.due_date) AS days_overdue
FROM Borrowings B
JOIN Members M ON B.member_id = M.member_id
JOIN Books BK ON B.book_id = BK.book_id
WHERE B.return_date IS NULL AND B.due_date < CURRENT_DATE;

-- Insert a fine for an overdue borrowing
INSERT INTO Fines (borrowing_id, fine_amount)
VALUES (1, 5.00);  -- assuming borrowing_id = 1 and a fine of 5.00

-- Check before the transaction
SELECT title, available_copies FROM Books WHERE book_id = 1;

-- Insert borrowing within a transaction
START TRANSACTION;
UPDATE Books SET available_copies = available_copies - 1 WHERE book_id = 1 AND available_copies > 0;
INSERT INTO Borrowings (member_id, book_id, due_date)
VALUES (1, 1, DATE_ADD(CURRENT_DATE, INTERVAL 14 DAY));
COMMIT;

-- Check after the transaction
SELECT title, available_copies FROM Books WHERE book_id = 1;


