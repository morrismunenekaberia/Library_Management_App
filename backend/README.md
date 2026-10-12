# Library Management Backend API

Node.js + Express backend service with PostgreSQL for the Library Management system, built following Clean Architecture principles.

---

## Quick Start

### 1. Prerequisites
- Node.js (v18+)
- PostgreSQL (v14+) running locally

### 2. Environment Configuration
Copy `.env.example` to `.env` and adjust your local PostgreSQL settings:
```bash
cp .env.example .env
```

Default local `.env` values:
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=library_app
DB_USER=library_user
DB_PASSWORD=1234
JWT_SECRET=dev_secret_change_me
ADMIN_PASSWORD=admin123
PORT=3000
```

### 3. Database Management Scripts

| Command | Description | Safety / Re-run |
|---|---|---|
| `npm run db:init` | Creates schema, baseline seed (3 members, 5 books), and admin user | Safe on clean setup |
| `npm run db:demo` | Seeds 25 books (5 categories), 10 active members + linked user accounts, and 8 loans | **Safe to re-run** (idempotent, no duplicates) |
| `npm run db:reset` | Drops and recreates all tables, then applies schema, baseline seed, admin user, and demo data | **Refuses to run** when `NODE_ENV=production` |

### 4. Running the Server & Tests
```bash
# Production start
npm start

# Development mode with watch
npm run dev

# Run unit tests
npm test
```

---

## Demo Accounts & Test Data

The database includes preconfigured demo accounts for testing and presentation:

### Librarian (Admin) Account
- **Username**: `admin`
- **Password**: `admin123` (or configured via `ADMIN_PASSWORD` in `.env`)
- **Role**: `librarian`
- **Permissions**: Full access to browse, search, add, edit, and delete books; manage members; issue and return loans.

### Member Accounts
All 10 members have active accounts and can sign in to view their account profile and loan history:
- **Default Password for all demo members**: `Member123!` (or configured via `DEMO_MEMBER_PASSWORD`)
- **Role**: `member`
- **Status**: `active`

| Full Name | Admission Number / Username | Password | Role | Loans Status in Demo Data |
|---|---|---|---|---|
| Alice Johnson | `ADM-2024-001` | `Member123!` | member | 1 Active loan, 1 Returned loan |
| Bob Smith | `ADM-2024-002` | `Member123!` | member | 1 Returned loan |
| Carol Williams | `ADM-2024-003` | `Member123!` | member | 1 Returned loan |
| David Brown | `ADM-2024-004` | `Member123!` | member | **1 Overdue loan** (7 days overdue) |
| Eva Davis | `ADM-2024-005` | `Member123!` | member | **1 Overdue loan** (4 days overdue) |
| Frank Miller | `ADM-2024-006` | `Member123!` | member | 1 Active loan (12 days remaining) |
| Grace Wilson | `ADM-2024-007` | `Member123!` | member | 1 Active loan (13 days remaining) |
| Henry Taylor | `ADM-2024-008` | `Member123!` | member | 0 loans (Eligible to borrow up to 3) |
| Ivy Anderson | `ADM-2024-009` | `Member123!` | member | 0 loans (Eligible to borrow up to 3) |
| Jack Thomas | `ADM-2024-010` | `Member123!` | member | 0 loans (Eligible to borrow up to 3) |

---

## Demo Books Catalogue (25 Books Across 5 Categories)

1. **Computer Science** (5 titles):
   - *Introduction to Algorithms* (Cormen et al.) – Total: 6 copies
   - *The Pragmatic Programmer* (Hunt & Thomas) – Total: 5 copies (1 on loan, overdue)
   - *The C Programming Language* (Kernighan & Ritchie) – Total: 4 copies
   - *Structure and Interpretation of Computer Programs* (Abelson & Sussman) – Total: 3 copies
   - *Effective Java* (Bloch) – Total: 4 copies

2. **Software Engineering** (5 titles):
   - *Clean Code* (Martin) – Total: 7 copies
   - *Design Patterns* (Gamma et al.) – Total: 5 copies
   - *Clean Architecture* (Martin) – Total: 5 copies (1 on loan, active)
   - *Domain-Driven Design* (Evans) – Total: 3 copies
   - *Refactoring* (Fowler) – Total: 4 copies

3. **Database & Cloud** (5 titles):
   - *Database System Concepts* (Silberschatz et al.) – Total: 5 copies
   - *Designing Data-Intensive Applications* (Kleppmann) – Total: 6 copies
   - *Building Microservices* (Newman) – Total: 4 copies
   - *Cloud Native Patterns* (Davis) – Total: 3 copies
   - *Learning SQL* (Beaulieu) – Total: 3 copies

4. **Mathematics & AI** (5 titles):
   - *Deep Learning* (Goodfellow et al.) – Total: 5 copies (1 on loan, overdue)
   - *Artificial Intelligence: A Modern Approach* (Russell & Norvig) – Total: 4 copies
   - *Hands-On Machine Learning* (Géron) – Total: 5 copies (1 on loan, active)
   - *Linear Algebra and Its Applications* (Strang) – Total: 4 copies
   - *Pattern Recognition and Machine Learning* (Bishop) – Total: 3 copies

5. **Cybersecurity & Networks** (5 titles):
   - *Computer Networks* (Tanenbaum & Wetherall) – Total: 5 copies (1 on loan, active)
   - *The Web Application Hacker's Handbook* (Stuttard & Pinto) – Total: 3 copies
   - *Practical Malware Analysis* (Sikorski & Honig) – Total: 2 copies
   - *Cryptography and Network Security* (Stallings) – Total: 4 copies
   - *The Linux Command Line* (Shotts) – Total: 3 copies

---

## Demo Loans (8 Loans Total)

- **3 Active Loans**:
  - Alice Johnson (`ADM-2024-001`) borrowed *Clean Architecture* (due in 11 days)
  - Frank Miller (`ADM-2024-006`) borrowed *Computer Networks* (due in 12 days)
  - Grace Wilson (`ADM-2024-007`) borrowed *Hands-On Machine Learning* (due in 13 days)
- **2 Overdue Loans**:
  - David Brown (`ADM-2024-004`) borrowed *The Pragmatic Programmer* (overdue by 7 days)
  - Eva Davis (`ADM-2024-005`) borrowed *Deep Learning* (overdue by 4 days)
- **3 Returned Loans**:
  - Alice Johnson (`ADM-2024-001`) returned *Clean Code*
  - Bob Smith (`ADM-2024-002`) returned *Introduction to Algorithms*
  - Carol Williams (`ADM-2024-003`) returned *Designing Data-Intensive Applications*

