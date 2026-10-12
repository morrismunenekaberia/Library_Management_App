-- ============================================================
-- Library Management App – Database Schema
-- Run with: npm run db:init
-- ============================================================

-- Drop tables in reverse dependency order so the script is re-runnable
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS members;

-- ============================================================
-- MEMBERS – library patrons (students / staff)
-- ============================================================
CREATE TABLE members (
  id               SERIAL       PRIMARY KEY,                        -- auto-incrementing surrogate key
  full_name        VARCHAR(200) NOT NULL,                           -- display name
  admission_number VARCHAR(50)  UNIQUE NOT NULL,                    -- university ID, must be unique
  phone            VARCHAR(20),                                     -- optional contact number
  email            VARCHAR(200),                                    -- optional email
  joined_at        TIMESTAMP    NOT NULL DEFAULT NOW(),             -- when the member registered
  status           VARCHAR(20)  NOT NULL DEFAULT 'active'           -- soft status flag (active / suspended)
);

-- ============================================================
-- USERS – authentication accounts
-- ============================================================
CREATE TABLE users (
  id            SERIAL       PRIMARY KEY,
  username      VARCHAR(100) UNIQUE NOT NULL,                       -- login name, must be unique
  password_hash VARCHAR(200) NOT NULL,                              -- bcrypt hash, never plain text
  role          VARCHAR(20)  NOT NULL CHECK (role IN ('librarian', 'member')),  -- restricts role to known values
  member_id     INTEGER      REFERENCES members(id) ON DELETE SET NULL          -- nullable; librarians may not have a member record
);

-- ============================================================
-- BOOKS – catalogue of library holdings
-- ============================================================
CREATE TABLE books (
  id               SERIAL       PRIMARY KEY,
  isbn             VARCHAR(20)  UNIQUE NOT NULL,                    -- International Standard Book Number, unique per title
  title            VARCHAR(300) NOT NULL,                           -- book title
  author           VARCHAR(300) NOT NULL,                           -- author name(s)
  category         VARCHAR(100),                                    -- genre / subject area
  total_copies     INTEGER      NOT NULL CHECK (total_copies >= 0), -- cannot own negative copies
  available_copies INTEGER      NOT NULL CHECK (available_copies >= 0),          -- cannot have negative availability
  CONSTRAINT available_lte_total CHECK (available_copies <= total_copies)        -- available can never exceed total
);

-- ============================================================
-- LOANS – tracks which member borrowed which book
-- ============================================================
CREATE TABLE loans (
  id          SERIAL    PRIMARY KEY,
  book_id     INTEGER   NOT NULL REFERENCES books(id) ON DELETE CASCADE,    -- which book was borrowed
  member_id   INTEGER   NOT NULL REFERENCES members(id) ON DELETE CASCADE,  -- who borrowed it
  issued_at   TIMESTAMP NOT NULL DEFAULT NOW(),                             -- checkout timestamp
  due_date    TIMESTAMP NOT NULL,                                           -- when the book is due back
  returned_at TIMESTAMP                                                     -- null while still on loan
);

-- ============================================================
-- INDEXES – speed up the most common look-ups
-- ============================================================
CREATE INDEX idx_loans_member_id ON loans(member_id);   -- find all loans for a member
CREATE INDEX idx_loans_book_id   ON loans(book_id);     -- find all loans for a book
CREATE INDEX idx_books_title     ON books(title);       -- search / sort books by title

