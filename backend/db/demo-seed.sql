-- ============================================================
-- Library Management App – Demo Seed Data
-- 25 books across 5 categories, 10 active members, and 8 loans
-- Safe to re-run (idempotent with ON CONFLICT and WHERE NOT EXISTS)
-- ============================================================

-- 1. Insert 25 realistic books across 5 distinct categories
INSERT INTO books (isbn, title, author, category, total_copies, available_copies) VALUES
  -- Category 1: Computer Science (5 titles)
  ('978-0262033848', 'Introduction to Algorithms', 'Thomas H. Cormen, Charles E. Leiserson, Ronald L. Rivest, Clifford Stein', 'Computer Science', 6, 6),
  ('978-0135957059', 'The Pragmatic Programmer: Your Journey to Mastery', 'Andrew Hunt, David Thomas', 'Computer Science', 5, 5),
  ('978-0131103627', 'The C Programming Language', 'Brian W. Kernighan, Dennis M. Ritchie', 'Computer Science', 4, 4),
  ('978-0262510875', 'Structure and Interpretation of Computer Programs', 'Harold Abelson, Gerald Jay Sussman', 'Computer Science', 3, 3),
  ('978-0134685991', 'Effective Java', 'Joshua Bloch', 'Computer Science', 4, 4),

  -- Category 2: Software Engineering (5 titles)
  ('978-0132350884', 'Clean Code: A Handbook of Agile Software Craftsmanship', 'Robert C. Martin', 'Software Engineering', 7, 7),
  ('978-0201633610', 'Design Patterns: Elements of Reusable Object-Oriented Software', 'Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides', 'Software Engineering', 5, 5),
  ('978-0134494166', 'Clean Architecture: A Craftsman''s Guide to Software Structure', 'Robert C. Martin', 'Software Engineering', 5, 5),
  ('978-0321125217', 'Domain-Driven Design: Tackling Complexity in the Heart of Software', 'Eric Evans', 'Software Engineering', 3, 3),
  ('978-0201485677', 'Refactoring: Improving the Design of Existing Code', 'Martin Fowler', 'Software Engineering', 4, 4),

  -- Category 3: Database & Cloud (5 titles)
  ('978-0073523323', 'Database System Concepts', 'Abraham Silberschatz, Henry F. Korth, S. Sudarshan', 'Database & Cloud', 5, 5),
  ('978-1449373320', 'Designing Data-Intensive Applications', 'Martin Kleppmann', 'Database & Cloud', 6, 6),
  ('978-1491950357', 'Building Microservices: Designing Fine-Grained Systems', 'Sam Newman', 'Database & Cloud', 4, 4),
  ('978-1492040651', 'Cloud Native Patterns: Designing High-Availability Systems', 'Cornelia Davis', 'Database & Cloud', 3, 3),
  ('978-1449355739', 'Learning SQL: Generate, Manipulate, and Retrieve Data', 'Alan Beaulieu', 'Database & Cloud', 3, 3),

  -- Category 4: Mathematics & AI (5 titles)
  ('978-0262035613', 'Deep Learning', 'Ian Goodfellow, Yoshua Bengio, Aaron Courville', 'Mathematics & AI', 5, 5),
  ('978-0134610993', 'Artificial Intelligence: A Modern Approach', 'Stuart Russell, Peter Norvig', 'Mathematics & AI', 4, 4),
  ('978-1492032649', 'Hands-On Machine Learning with Scikit-Learn, Keras, and TensorFlow', 'Aurélien Géron', 'Mathematics & AI', 5, 5),
  ('978-0980232714', 'Linear Algebra and Its Applications', 'Gilbert Strang', 'Mathematics & AI', 4, 4),
  ('978-1107298019', 'Pattern Recognition and Machine Learning', 'Christopher M. Bishop', 'Mathematics & AI', 3, 3),

  -- Category 5: Cybersecurity & Networks (5 titles)
  ('978-0133594140', 'Computer Networks', 'Andrew S. Tanenbaum, David J. Wetherall', 'Cybersecurity & Networks', 5, 5),
  ('978-1118915387', 'The Web Application Hacker''s Handbook', 'Dafydd Stuttard, Marcus Pinto', 'Cybersecurity & Networks', 3, 3),
  ('978-1593276102', 'Practical Malware Analysis: The Hands-On Guide', 'Michael Sikorski, Andrew Honig', 'Cybersecurity & Networks', 2, 2),
  ('978-0134444284', 'Cryptography and Network Security: Principles and Practice', 'William Stallings', 'Cybersecurity & Networks', 4, 4),
  ('978-1593279929', 'The Linux Command Line: A Complete Introduction', 'William E. Shotts Jr.', 'Cybersecurity & Networks', 3, 3)
ON CONFLICT (isbn) DO UPDATE SET
  title = EXCLUDED.title,
  author = EXCLUDED.author,
  category = EXCLUDED.category,
  total_copies = EXCLUDED.total_copies;

-- 2. Insert 10 active library members
INSERT INTO members (full_name, admission_number, phone, email, status) VALUES
  ('Alice Johnson',   'ADM-2024-001', '0712000001', 'alice.johnson@university.ac.ke',   'active'),
  ('Bob Smith',       'ADM-2024-002', '0712000002', 'bob.smith@university.ac.ke',       'active'),
  ('Carol Williams',  'ADM-2024-003', '0712000003', 'carol.williams@university.ac.ke',  'active'),
  ('David Brown',     'ADM-2024-004', '0712000004', 'david.brown@university.ac.ke',     'active'),
  ('Eva Davis',       'ADM-2024-005', '0712000005', 'eva.davis@university.ac.ke',       'active'),
  ('Frank Miller',    'ADM-2024-006', '0712000006', 'frank.miller@university.ac.ke',    'active'),
  ('Grace Wilson',    'ADM-2024-007', '0712000007', 'grace.wilson@university.ac.ke',    'active'),
  ('Henry Taylor',    'ADM-2024-008', '0712000008', 'henry.taylor@university.ac.ke',    'active'),
  ('Ivy Anderson',    'ADM-2024-009', '0712000009', 'ivy.anderson@university.ac.ke',    'active'),
  ('Jack Thomas',     'ADM-2024-010', '0712000010', 'jack.thomas@university.ac.ke',     'active')
ON CONFLICT (admission_number) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  phone = EXCLUDED.phone,
  email = EXCLUDED.email,
  status = EXCLUDED.status;

-- 3. Insert 8 loans: 3 returned, 2 overdue, 3 active
-- Guarded by NOT EXISTS to guarantee idempotent re-runs.

-- Loan 1 (Returned): Alice borrowed Clean Code
INSERT INTO loans (book_id, member_id, issued_at, due_date, returned_at)
SELECT b.id, m.id, NOW() - INTERVAL '30 days', NOW() - INTERVAL '16 days', NOW() - INTERVAL '18 days'
FROM books b, members m
WHERE b.isbn = '978-0132350884' AND m.admission_number = 'ADM-2024-001'
  AND NOT EXISTS (
    SELECT 1 FROM loans l WHERE l.book_id = b.id AND l.member_id = m.id AND l.returned_at IS NOT NULL
  );

-- Loan 2 (Returned): Bob borrowed Introduction to Algorithms
INSERT INTO loans (book_id, member_id, issued_at, due_date, returned_at)
SELECT b.id, m.id, NOW() - INTERVAL '25 days', NOW() - INTERVAL '11 days', NOW() - INTERVAL '12 days'
FROM books b, members m
WHERE b.isbn = '978-0262033848' AND m.admission_number = 'ADM-2024-002'
  AND NOT EXISTS (
    SELECT 1 FROM loans l WHERE l.book_id = b.id AND l.member_id = m.id AND l.returned_at IS NOT NULL
  );

-- Loan 3 (Returned): Carol borrowed Designing Data-Intensive Applications
INSERT INTO loans (book_id, member_id, issued_at, due_date, returned_at)
SELECT b.id, m.id, NOW() - INTERVAL '14 days', NOW() - INTERVAL '1 day', NOW() - INTERVAL '2 days'
FROM books b, members m
WHERE b.isbn = '978-1449373320' AND m.admission_number = 'ADM-2024-003'
  AND NOT EXISTS (
    SELECT 1 FROM loans l WHERE l.book_id = b.id AND l.member_id = m.id AND l.returned_at IS NOT NULL
  );

-- Loan 4 (Overdue): David borrowed The Pragmatic Programmer (due 7 days ago)
INSERT INTO loans (book_id, member_id, issued_at, due_date, returned_at)
SELECT b.id, m.id, NOW() - INTERVAL '21 days', NOW() - INTERVAL '7 days', NULL
FROM books b, members m
WHERE b.isbn = '978-0135957059' AND m.admission_number = 'ADM-2024-004'
  AND NOT EXISTS (
    SELECT 1 FROM loans l WHERE l.book_id = b.id AND l.member_id = m.id AND l.returned_at IS NULL
  );

-- Loan 5 (Overdue): Eva borrowed Deep Learning (due 4 days ago)
INSERT INTO loans (book_id, member_id, issued_at, due_date, returned_at)
SELECT b.id, m.id, NOW() - INTERVAL '18 days', NOW() - INTERVAL '4 days', NULL
FROM books b, members m
WHERE b.isbn = '978-0262035613' AND m.admission_number = 'ADM-2024-005'
  AND NOT EXISTS (
    SELECT 1 FROM loans l WHERE l.book_id = b.id AND l.member_id = m.id AND l.returned_at IS NULL
  );

-- Loan 6 (Active): Alice borrowed Clean Architecture (due in 11 days)
INSERT INTO loans (book_id, member_id, issued_at, due_date, returned_at)
SELECT b.id, m.id, NOW() - INTERVAL '3 days', NOW() + INTERVAL '11 days', NULL
FROM books b, members m
WHERE b.isbn = '978-0134494166' AND m.admission_number = 'ADM-2024-001'
  AND NOT EXISTS (
    SELECT 1 FROM loans l WHERE l.book_id = b.id AND l.member_id = m.id AND l.returned_at IS NULL
  );

-- Loan 7 (Active): Frank borrowed Computer Networks (due in 12 days)
INSERT INTO loans (book_id, member_id, issued_at, due_date, returned_at)
SELECT b.id, m.id, NOW() - INTERVAL '2 days', NOW() + INTERVAL '12 days', NULL
FROM books b, members m
WHERE b.isbn = '978-0133594140' AND m.admission_number = 'ADM-2024-006'
  AND NOT EXISTS (
    SELECT 1 FROM loans l WHERE l.book_id = b.id AND l.member_id = m.id AND l.returned_at IS NULL
  );

-- Loan 8 (Active): Grace borrowed Hands-On Machine Learning (due in 13 days)
INSERT INTO loans (book_id, member_id, issued_at, due_date, returned_at)
SELECT b.id, m.id, NOW() - INTERVAL '1 day', NOW() + INTERVAL '13 days', NULL
FROM books b, members m
WHERE b.isbn = '978-1492032649' AND m.admission_number = 'ADM-2024-007'
  AND NOT EXISTS (
    SELECT 1 FROM loans l WHERE l.book_id = b.id AND l.member_id = m.id AND l.returned_at IS NULL
  );

-- 4. Synchronize available_copies for all books based on unreturned loans
UPDATE books b
SET available_copies = b.total_copies - COALESCE(
  (SELECT COUNT(*)::int FROM loans l WHERE l.book_id = b.id AND l.returned_at IS NULL),
  0
);

