# API Contract

Base URL default: `http://localhost:3000/api` (Android emulator: `http://10.0.2.2:3000/api`)
All authenticated endpoints require header: `Authorization: Bearer <token>`
Errors shape: `{"error": "<message>"}`

## Endpoints

### Health
- `GET /api/health` -> `200 OK` `{"status": "ok", "database": true}`

### Auth
- `POST /api/auth/login` (Body: `username`, `password`) -> `200 OK` `{"token": string, "user": {"id": int, "username": string, "role": "librarian"|"member", "memberId": int|null}}`
- `POST /api/auth/logout` -> `200 OK` `{"message": "Logged out successfully"}`
- `GET /api/auth/me` (Auth) -> `200 OK` `{"user": {"id": int, "username": string|null, "role": string, "memberId": int|null}}`

### Books
- `GET /api/books?search=` (Auth) -> `200 OK` `[{"id": int, "isbn": string, "title": string, "author": string, "category": string|null, "totalCopies": int, "availableCopies": int}]`
- `GET /api/books/:id` (Auth) -> `200 OK` Book object
- `POST /api/books` (Auth: librarian) (Body: `isbn`, `title`, `author`, `category`?, `totalCopies`, `availableCopies`?) -> `201 Created` Book object
- `PUT /api/books/:id` (Auth: librarian) (Body: at least one of `isbn`, `title`, `author`, `category`, `totalCopies`) -> `200 OK` Book object
- `DELETE /api/books/:id` (Auth: librarian) -> `200 OK` `{"message": "Book deleted successfully"}` (409 if active loans exist)

### Members
- `GET /api/members?search=` (Auth: librarian) -> `200 OK` `[{"id": int, "fullName": string, "admissionNumber": string, "phone": string|null, "email": string|null, "joinedAt": ISOString, "status": "active"|"suspended"}]`
- `GET /api/members/:id` (Auth: librarian) -> `200 OK` Member object
- `POST /api/members` (Auth: librarian) (Body: `fullName`, `admissionNumber`, `phone`?, `email`?, `status`?, `createUser`? bool) -> `201 Created` Member object + optional `temporaryPassword` (if `createUser: true`)
- `PUT /api/members/:id` (Auth: librarian) (Body: at least one field) -> `200 OK` Member object
- `DELETE /api/members/:id` (Auth: librarian) -> `200 OK` `{"message": "Member deleted successfully"}` (409 if active loans exist)

### Loans
- `GET /api/loans?status=&memberId=` (Auth: both roles; members automatically scoped to own memberId) (status: `"active"`|"overdue"|"returned"`) -> `200 OK` `[{"id": int, "bookId": int, "memberId": int, "issuedAt": ISOString, "dueDate": ISOString, "returnedAt": ISOString|null, "bookTitle": string|null, "memberName": string|null}]`
- `POST /api/loans` (Auth: librarian) (Body: `bookId`, `memberId`, `dueDate`?) -> `201 Created` Loan object (Rules: member max 3 loans, member active, book available copies > 0)
- `POST /api/loans/:id/return` (Auth: librarian) -> `200 OK` Loan object (increments book availableCopies)

