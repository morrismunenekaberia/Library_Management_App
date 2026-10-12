# Library Management App

A university course project (Mobile Application 2) implementing a Library Management system built with **Clean Architecture**.

- **Frontend**: Flutter / Dart (Android) with Material 3, `go_router`, and `provider`.
- **Backend**: Node.js, Express, and `pg` (PostgreSQL client).
- **Database**: PostgreSQL with parameterized queries and relational constraints.

---

## Repository Structure

```text
.
├── backend/
│   ├── db/
│   │   ├── schema.sql         # Table schemas, constraints, and indexes
│   │   ├── seed.sql           # Initial data seed (books, members)
│   │   └── init.js            # DB initialization script (npm run db:init)
│   ├── src/
│   │   ├── config/            # Environment variables and PostgreSQL pool
│   │   ├── domain/            # Entities, repository interfaces, custom errors
│   │   ├── usecases/          # Business logic use cases (framework-independent)
│   │   ├── infrastructure/    # PostgreSQL repository implementations
│   │   ├── interfaces/http/   # Express controllers, routes, and middlewares
│   │   ├── app.js             # Express application assembly
│   │   └── server.js          # HTTP server entrypoint
│   └── test/                  # Node.js native unit tests
└── mobile/
    ├── lib/
    │   ├── core/              # ApiClient, TokenStorage, AppTheme, AppRouter, exceptions
    │   ├── features/
    │   │   ├── auth/          # Authentication slice (login, logout, session restoration)
    │   │   └── books/         # Books slice (catalogue, search, add, edit, delete)
    │   └── main.dart          # Dependency injection and application root
    └── test/                  # Unit and widget test suite
```

---

## 1. Backend Setup

### Prerequisites
- Node.js (v18+)
- PostgreSQL (v14+) running locally

### Step-by-Step Instructions

1. **Navigate to the backend directory**:
   ```bash
   cd backend
   npm install
   ```

2. **Configure Environment Variables**:
   Copy the example environment file and configure your PostgreSQL credentials:
   ```bash
   cp .env.example .env
   ```
   Edit `.env` with your database credentials and secrets:
   ```env
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=library_app
   DB_USER=library_user
   DB_PASSWORD=your_password
   JWT_SECRET=your_jwt_secret_key_here
   PORT=3000
   SEED_ADMIN_PASSWORD=admin123
   ```

3. **Initialize the Database**:
   Ensure PostgreSQL is running and the database specified in `DB_NAME` exists.
   Then execute the database schema and seed script:
   ```bash
   npm run db:init
   ```
   This script will:
   - Create tables: `members`, `users`, `books`, and `loans`.
   - Seed one admin librarian (`admin` / password from `SEED_ADMIN_PASSWORD`).
   - Seed 5 sample books and 3 sample members.

4. **Start the Backend Server**:
   - Production mode:
     ```bash
     npm start
     ```
   - Development mode with auto-reload:
     ```bash
     npm run dev
     ```
   The API server will listen on `http://localhost:3000`.

5. **Verify Backend Health**:
   ```bash
   curl http://localhost:3000/api/health
   # Response: {"status":"healthy","database":"connected"}
   ```

6. **Run Backend Tests**:
   ```bash
   npm test
   ```

---

## 2. Mobile App Setup (Flutter / Android)

### Prerequisites
- Flutter SDK (v3.13+)
- Android Studio or Android SDK command-line tools configured

### Step-by-Step Instructions

1. **Navigate to the mobile directory**:
   ```bash
   cd mobile
   flutter pub get
   ```

2. **Configure API Base URL**:
   The mobile app connects to the backend REST API via `--dart-define=API_BASE_URL=...`.

   - **Emulator**:
     ```bash
     flutter run
     ```
     *(Defaults to `http://10.0.2.2:3000/api`)*

   - **Physical Android Device (via Wi-Fi / LAN)**:
     ```bash
     flutter run --dart-define=API_BASE_URL=http://192.168.137.171:3000/api
     ```

   - **Release APK**:
     ```bash
     flutter build apk --release --dart-define=API_BASE_URL=http://192.168.137.171:3000/api
     ```

   > **Note**: The IP address (`192.168.137.171`) is your computer's local LAN IP and must be updated whenever your network or IP address changes. Ensure that both your computer running the Node.js API and your physical phone are connected to the same Wi-Fi network.

3. **Run Mobile Static Analysis & Tests**:
   ```bash
   flutter analyze
   flutter test
   ```

---

## 3. Application Features & Access Control

### Roles & Permissions
- **Librarian (`admin`)**:
  - Full access to browse catalogue, search books, add books, edit books, and delete books.
  - Floating Action Button ("Add Book") and Edit/Delete options are visible.
- **Member**:
  - Read-only access to browse and search catalogue.
  - Add, edit, and delete controls are automatically hidden.

### Hardening & Resilience
- **Automatic Logout on 401**: Any API response returning `401 Unauthorized` automatically invalidates the stored session and redirects to the login screen.
- **Error Handling with Retry**: Network disconnections and server errors display clear human-readable messages along with a dedicated "Retry" action.
- **Input Validation Alignment**: Client form validators match PostgreSQL schema constraints (`VARCHAR` limits, integer checks) preventing unexpected runtime errors.
- **Security**: Passwords hashed with `bcrypt`, authentication via signed JWTs, parameterized SQL queries against SQL injection, and zero credentials committed to version control.

