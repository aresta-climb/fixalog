# History Tracking

## Requirement: Save Express Report to History
The system SHALL persist a local database record (SubmissionRecord) immediately after an express report PDF is successfully generated and signed.

### Scenario: Successful generation triggers persistence
- **WHEN** the generation process finishes successfully and the PDF file is written to the output path
- **THEN** a new record is saved to the Isar database containing the protocol ID, name, date, and file paths

## Requirement: Display Real History Data
The system SHALL present a list of previously generated and persisted records on the 'History' tab of the application, ordered by most recent first.

### Scenario: User navigates to the History screen
- **WHEN** the user opens the History tab
- **THEN** the system fetches records from the local Isar database and displays them dynamically in the UI instead of placeholder data
