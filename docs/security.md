# Security

## MVP Requirements

- All production communication must use HTTPS or WSS.
- Access tokens must be stored through a Keychain abstraction on macOS.
- Tokens must not be written to logs, UserDefaults, JSON files, or SQLite plaintext columns.
- High-risk actions must produce `task.requires_approval`.
- Approval decisions must be sent to Gateway and audited server-side.
- System notification bodies must avoid sensitive content by default.

## High-Risk Actions

These actions require explicit approval:

- Sending email.
- Deleting files.
- Executing shell commands.
- Modifying production environments.
- Sending payments.
- Publishing content.
- Accessing sensitive files.
- Calling external APIs with irreversible effects.

## Audit Fields

Approval audit records should include:

- Approval id.
- Task id.
- User id.
- Device id.
- Decision.
- Decision timestamp.
- Result event id.

