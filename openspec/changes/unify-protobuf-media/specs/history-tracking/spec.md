## MODIFIED Requirements

### Requirement: Display Real History Data
The system SHALL present a list of previously generated and persisted records on the 'History' tab of the application, ordered by most recent first. A click on any item SHALL initiate an edit session instead of just opening the PDF.

#### Scenario: User navigates to the History screen
- **WHEN** the user opens the History tab
- **THEN** the system fetches records from the local Isar database and displays them dynamically in the UI instead of placeholder data

#### Scenario: User clicks on a history item
- **WHEN** the user clicks on a history record card
- **THEN** the system reads the `protobufPath` from the Isar record
- **THEN** the system opens the `ExpressFormScreen` passing the `id_sessao` to allow restoring the edit mode from the session bundle
