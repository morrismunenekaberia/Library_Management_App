Rules for every task in this project:
1. Read the relevant files before editing them. Never assume a file, class, endpoint or field exists. If you cannot find something, write "NOT FOUND" and stop to ask me.
2. Never invent API endpoints, request fields or response shapes. Take them only from /docs/api-contract.md or the backend source code.
3. Do only the task I give. Do not refactor, rename or restyle anything outside it.
4. Do not change domain entities or repository signatures unless the task says so. If you think you must, stop and ask.
5. No new packages unless I approve.
6. Keep clean architecture: domain, data, presentation. No HTTP in domain, no business logic in widgets.
7. At the end: list the files changed, run flutter analyze, and tell me anything you were unsure about, marked "UNVERIFIED".
