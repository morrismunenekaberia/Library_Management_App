-- ============================================================
-- Seed data – 3 members and 5 books
-- The admin (librarian) user is inserted by the init script
-- because its password must be bcrypt-hashed at runtime.
-- ============================================================

-- Sample members
INSERT INTO members (full_name, admission_number, phone, email) VALUES
  ('Alice Johnson',   'ADM-2024-001', '0712000001', 'alice.johnson@university.ac.ke'),
  ('Bob Smith',       'ADM-2024-002', '0712000002', 'bob.smith@university.ac.ke'),
  ('Carol Williams',  'ADM-2024-003', '0712000003', 'carol.williams@university.ac.ke');

-- Sample books
INSERT INTO books (isbn, title, author, category, total_copies, available_copies) VALUES
  ('978-0132350884', 'Clean Code',                  'Robert C. Martin',            'Programming',          3, 3),
  ('978-0135957059', 'The Pragmatic Programmer',     'Andrew Hunt, David Thomas',   'Programming',          2, 2),
  ('978-0262033848', 'Introduction to Algorithms',   'Thomas H. Cormen',            'Computer Science',     4, 4),
  ('978-0073523323', 'Database System Concepts',     'Abraham Silberschatz',        'Database',             3, 3),
  ('978-0201633610', 'Design Patterns',              'Erich Gamma et al.',          'Software Engineering', 2, 2);

