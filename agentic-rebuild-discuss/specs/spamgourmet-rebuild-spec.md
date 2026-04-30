# Specification: Agentic Rebuild of Spamgourmet

## 1. Introduction
Spamgourmet is a long-standing service providing disposable email addresses that automatically expire after a certain number of messages. This specification outlines a modern, "agentic" rebuild of the service, leveraging contemporary technologies and AI to enhance user experience and spam protection.

## 2. Current System Analysis
The existing system is built primarily in Perl, using MySQL for data storage. Key components include:
- **Mail Handler (`spameater`)**: Processes incoming emails, manages counts, and handles forwarding/dropping.
- **Web Interface**: Allows users to manage their account, view statistics, and configure settings.
- **Data Model**: Centered around Users, Emails (disposable addresses), Watchwords, and Permitted (trusted) senders.
- **Addressing Scheme**: `word.number.user@domain.com` or `word.user@domain.com`.

## 3. Proposed Architecture
A modern rebuild will utilize:
- **Language**: Python 3.11+ for its rich ecosystem and AI libraries.
- **Web Framework**: FastAPI for a high-performance, asynchronous API.
- **Database**: PostgreSQL for robust relational data management.
- **Cache/Queue**: Redis for session management and task queuing.
- **Mail Server**: Integration with Postfix or a cloud-based SMTP service (e.g., AWS SES, SendGrid).
- **Containerization**: Docker and Kubernetes for scalability and ease of deployment.

## 4. Data Model Improvements
- **Users**: Extended profiles, MFA support, and API key management.
- **Disposable Addresses**: Support for custom domains, granular expiration rules (time-based, count-based, or both).
- **Audit Logs**: Enhanced logging for all actions and email processing events.
- **Tags**: Allow users to tag addresses for better organization.

## 5. Agentic AI Features
The "agentic" aspect introduces AI-driven autonomy:
- **Intelligent Spam Classification**: Use LLMs or specialized NLP models to analyze incoming mail beyond simple blacklists/whitelists.
- **Automated Address Management**: AI can suggest when to delete an address or increase its count based on the user's historical behavior.
- **Natural Language Interface**: A chat-based interface (e.g., via Slack, Discord, or a web widget) to manage addresses and query logs using natural language.
- **Sender Reputation Engine**: Autonomously track and adjust trust levels for senders across the entire platform.
- **Automatic Content Summarization**: Provide daily/weekly summaries of "eaten" messages to ensure no important information was lost.

## 6. API Design
- **RESTful API**: Full coverage of all user and administrative functions.
- **Webhooks**: Notify external systems of incoming mail or address expiration.
- **SDKs**: Official libraries for popular languages (Python, JS, Go).

## 7. Security and Scalability
- **Rate Limiting**: Sophisticated rate limiting at both the API and SMTP levels.
- **Encryption**: At-rest and in-transit encryption for all sensitive data.
- **Scalable Mail Processing**: Decouple mail reception from processing using a distributed task queue (Celery/RabbitMQ).

## 8. Migration Plan
- Provide tools to import existing Spamgourmet accounts and addresses.
- Support legacy addressing formats for a transitional period.
