# Comprehensive Specification: Agentic Rebuild of Spamgourmet

## 1. Introduction
Spamgourmet is a specialized email forwarding service that allows users to create disposable email addresses on the fly. These addresses automatically expire after a user-defined number of messages have been received. This specification details the existing system's architecture and modules, and proposes a modern, agentic rebuild.

## 2. Existing System Architecture

### 2.1 Overview
The current system is a Perl-based application utilizing a MySQL database. It consists of three primary entry points:
1.  **Mail Handling**: Triggered by incoming SMTP mail (via `.forward` or aliases).
2.  **Web Management**: A CGI-based web interface for user configuration.
3.  **Support Services**: Standalone daemons and client-side utilities.

### 2.2 Core Modules (`modules/Mail/Spamgourmet/`)

| Module | Responsibility | Valuable Features |
| :--- | :--- | :--- |
| `Config.pm` | Global configuration management. | Centralized settings; DB connection pooling/retry logic; custom debug logging with date formatting; feature flag definitions. |
| `Util.pm` | Low-level utility functions. | Address parsing and normalization; bitwise-style feature flag management; "Roman-to-Number" conversion (e.g., 'a' = 1); MD5-based short hash generation for address verification. |
| `Session.pm` | Authentication and session state. | User login via password or hash code; BCrypt password hashing; session token management; CAPTCHA integration; automatic language detection (via `HTTP_ACCEPT_LANGUAGE`). |
| `WebUtil.pm` | Web-specific utilities. | HTML sanitization and "de-scripting"; URL encoding; XML escaping; complex SQL search restriction generation; email format validation (`looksRight`). |
| `Dialogs.pm` | Internationalization (i18n). | Localized string management; multi-tier caching (Memory -> File -> DB) for performance; dynamic tag replacement within strings. |
| `Page.pm` | Template engine. | HTML/Text template loading and caching; recursive tag replacement; content-type and charset management. |
| `MessageIdChecker.pm` | Duplicate/Loop prevention. | File-based tracking of `Message-ID`s with automatic cleanup; hierarchical directory storage to handle large volumes of IDs. |
| `WebMessages.pm` | System email generation. | Templated system messages for password resets and email change confirmations; ROT13 encoding for administrative reply addresses. |
| `CommandLineMailer.pm` | SMTP via system pipe. | Integration with local MTAs (e.g., Sendmail/Postfix) using standard CLI flags. |
| `SocketMailer.pm` | Direct SMTP communication. | Raw socket-based SMTP delivery (HELO/MAIL FROM/RCPT TO/DATA) with fallback to CLI mailer. |
| `UserStore.pm` | Test data management. | Programmatic creation of test users and addresses for development/testing. |
| `MBoxParser.pm` | Mail format parsing. | Basic parsing of MBox-formatted mail into headers and body. |

### 2.3 Core Scripts and Services

#### Mail Handlers (`mailhandler/`)
-   **`spameater`**: The primary processor for incoming mail.
    -   **Parsing**: Extracts `From`, `To`, `Cc`, and `Delivered-To` headers.
    -   **Validation**: Checks `Message-ID` for duplicates.
    -   **Logic**: Determines if an address is new (auto-creation), active (count > 0), or expired. Handles watchwords and trusted sender lists.
    -   **Forwarding**: Rewrites headers and forwards mail to the user's real address.
-   **`outbound`**: Handles "reply-through" functionality.
    -   Allows users to reply to forwarded mail such that the reply appears to come from their disposable address.
    -   Uses a hashed redirection address to map replies back to the original recipient.

#### Web Controller (`web/html/`)
-   **`index.pl`**: The central CGI controller.
    -   Manages user registration, account settings, and the "Advanced" vs. "No-Brainer" UI modes.
    -   Provides detailed statistics (forwarded/eaten counts) and searchable address logs.
    -   Generates XML exports of user data.

#### CAPTCHA Server (`captchasrv/`)
-   **`captchasrv.pl`**: A standalone Perl daemon.
    -   Generates CAPTCHA images using ImageMagick's `convert`.
    -   Uses a dictionary-based word generator with random offsets.
    -   Communicates with `Session.pm` via a simple TCP socket protocol.

#### Obfuscation Tools (`addressscrambler/` & `sgmailto/`)
-   Client-side JavaScript utilities to scramble email addresses in the browser, preventing simple harvesting by bots while remaining clickable for users.

### 2.4 Data Flow and Dependencies
1.  **Incoming Mail**: `MTA` -> `spameater` -> `Config`/`Util`/`MessageIdChecker` -> `DB` -> `Mailer`.
2.  **Web Request**: `Apache` -> `index.pl` -> `Session` -> `Dialogs`/`Page` -> `DB` -> `Template`.
3.  **User Registration**: `index.pl` -> `Session` -> `captchasrv` (Socket) -> `index.pl` (HTML).

---

## 3. Proposed Agentic Rebuild

### 3.1 Architecture Shift
-   **Backend**: Python 3.11+ with **FastAPI**. Use `Pydantic` for strict data validation.
-   **Asynchronous Processing**: Use `Celery` or `ARQ` with `Redis` to handle mail processing outside the SMTP transaction window.
-   **Database**: **PostgreSQL** with `SQLAlchemy` or `Tortoise-ORM`.
-   **Mail Engine**: **Aiosmtpd** for receiving and **FastAPI-Mail** (or direct SES/SendGrid integration) for sending.

### 3.2 Enhanced Legacy Features
-   **Granular Throttling**: Implement Leaky Bucket or Token Bucket algorithms for receive/send/create rates.
-   **Dynamic i18n**: Use `GNU gettext` or a modern equivalent like `Fluent` for more powerful localization.
-   **Template Engine**: Shift to `Jinja2` for safer and more flexible UI/Email generation.

### 3.3 Agentic AI Features (The "Agent")
The rebuild will integrate an "Agent" that acts as an autonomous steward for the user's inbox.

#### A. Intelligent Spam Defense
-   **Beyond Blacklists**: Use a local LLM or a specialized service (like SpamAssassin but AI-augmented) to analyze the *intent* of an email.
-   **Contextual Whitelisting**: The agent can autonomously whitelist a sender if it recognizes a requested transaction or conversation thread.

#### B. Autonomous Address Management
-   **Adaptive Expiration**: Instead of a hard count, the agent can observe interaction patterns. If a "disposable" address starts receiving high-value correspondence, the agent can suggest converting it to a permanent alias.
-   **Auto-Cleanup**: Autonomously deactivate addresses that only receive high-volume marketing with zero user engagement.

#### C. Natural Language Management (ChatOps)
-   Users can interact with their "Gourmet Agent" via Telegram, Slack, or a web-chat:
    -   *"Agent, give me a new address for 'Amazon' with a count of 5."*
    -   *"Show me a summary of the mail eaten today."*
    -   *"Why was the mail from 'jules@example.com' blocked?"*

#### D. Content Summarization
-   Instead of losing "eaten" mail entirely, the agent provides a daily "Digest of the Eaten," summarizing blocked emails to ensure no "false positives" (like a misidentified receipt) are missed.

### 3.4 Security Rebirth
-   **MFA**: Built-in support for TOTP/WebAuthn.
-   **PGP/GPG Integration**: Option for the agent to encrypt forwarded mail automatically before it leaves the server.
-   **Auditability**: Structured JSON logging for every decision made by the AI agent.
