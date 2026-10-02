# AI Agent Backend Development Guidelines

## Document Purpose and Scope

This document establishes comprehensive, mandatory standards and best practices that ALL AI agents must follow when working on ANY backend project. This document is **language-agnostic** and **framework-agnostic**, applying universally to all backend technologies including Node.js, Python, Java, Go, Ruby, PHP, .NET, Rust, and any other backend platform.

This document **complements** the main AI Agent Development Guidelines (ai-agents.md) and focuses specifically on backend concerns including API design, data management, security, scalability, performance, and operational excellence.

**These are NON-NEGOTIABLE rules for backend development excellence.**

---

## 1. Backend Architecture Principles

### 1.1 Layered Architecture

**Mandatory Separation of Concerns**:
- **Presentation Layer**: API routes, controllers, request/response handling
- **Business Logic Layer**: Core application logic, domain models, business rules
- **Data Access Layer**: Database operations, ORM/query builders, repositories
- **Infrastructure Layer**: External services, third-party integrations, messaging

**Rules**:
- NEVER mix database queries with business logic
- NEVER put business logic in controllers/route handlers
- NEVER access external services directly from controllers
- Each layer must ONLY communicate with adjacent layers
- Dependencies must flow inward (presentation → business → data)

**Example Violations to AVOID**:
```
❌ Controller with database queries
❌ Business logic with HTTP response formatting
❌ Data layer with business validation rules
❌ Direct database access from route handlers
```

### 1.2 Service-Oriented Design

**Service Principles**:
- Each service represents a cohesive business capability
- Services are stateless and independently deployable
- Services communicate through well-defined interfaces
- Services own their data and expose it through APIs
- Services can fail independently without cascading failures

**Service Characteristics**:
- **Single Responsibility**: Each service does ONE thing well
- **Autonomy**: Services can be developed, deployed, and scaled independently
- **Bounded Context**: Clear boundaries around what the service owns
- **Contract-First**: Define interfaces before implementation
- **Resilience**: Design for failure at every level

### 1.3 Domain-Driven Design (DDD)

**Core Concepts for Backend**:
- **Entities**: Objects with unique identity that persist over time
- **Value Objects**: Immutable objects defined by their attributes
- **Aggregates**: Clusters of entities/value objects treated as a unit
- **Repositories**: Abstract data persistence, provide collection-like interface
- **Domain Services**: Business logic that doesn't belong to a single entity
- **Domain Events**: Capture significant occurrences in the domain

**Application**:
- Model your domain explicitly in code
- Use ubiquitous language consistently
- Protect aggregate boundaries
- Make implicit concepts explicit
- Isolate domain logic from infrastructure

---

## 2. API Design Excellence

### 2.1 RESTful API Standards

**HTTP Methods (Proper Usage)**:
- **GET**: Retrieve resources (must be idempotent, no side effects)
- **POST**: Create new resources (not idempotent)
- **PUT**: Replace entire resource (idempotent)
- **PATCH**: Partial update of resource (may or may not be idempotent)
- **DELETE**: Remove resource (idempotent)
- **OPTIONS**: Describe available methods
- **HEAD**: GET without response body

**URL Design Rules**:
- Use nouns, not verbs: `/users` not `/getUsers`
- Use plural nouns: `/products` not `/product`
- Use hierarchical structure: `/users/{id}/orders/{orderId}`
- Use lowercase and hyphens: `/order-items` not `/orderItems` or `/OrderItems`
- Version your APIs: `/v1/users`, `/v2/users`
- Keep URLs simple and predictable
- Use query parameters for filtering, sorting, pagination: `/users?role=admin&sort=name&page=2`

**HTTP Status Codes (Correct Usage)**:
- **200 OK**: Successful GET, PUT, PATCH, DELETE
- **201 Created**: Successful POST with resource creation
- **204 No Content**: Successful request with no response body
- **400 Bad Request**: Client error, invalid input
- **401 Unauthorized**: Authentication required or failed
- **403 Forbidden**: Authenticated but not authorized
- **404 Not Found**: Resource doesn't exist
- **409 Conflict**: Request conflicts with current state
- **422 Unprocessable Entity**: Validation errors
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: Server error (use sparingly)
- **503 Service Unavailable**: Temporary unavailability

### 2.2 GraphQL API Standards (When Applicable)

**Schema Design**:
- Define clear, strongly-typed schemas
- Use meaningful names for types, fields, and arguments
- Group related functionality
- Implement proper pagination (relay-style or offset-based)
- Use interfaces for polymorphic types
- Design mutations to return the modified object

**Query Complexity**:
- Implement query complexity analysis
- Set maximum query depth limits
- Prevent n+1 query problems with DataLoader pattern
- Implement query cost limits
- Monitor and log expensive queries

**Error Handling**:
- Return structured errors with error codes
- Provide helpful error messages
- Include field-level errors
- Don't expose internal implementation details

### 2.3 API Versioning

**Versioning Strategies**:
- **URI Versioning**: `/v1/users`, `/v2/users` (recommended for REST)
- **Header Versioning**: `Accept: application/vnd.api.v1+json`
- **Query Parameter**: `/users?version=1` (least recommended)

**Rules**:
- ALWAYS version your APIs from day one
- Maintain backward compatibility within a major version
- Deprecate old versions gradually with clear timelines
- Document breaking changes thoroughly
- Support at least N-1 versions
- Never remove a version without migration path

### 2.4 Request/Response Standards

**Request Validation**:
- Validate ALL inputs at API boundary
- Use schema validation libraries
- Validate data types, formats, ranges, patterns
- Sanitize inputs to prevent injection attacks
- Return clear, actionable validation errors
- Fail fast on invalid input

**Response Format**:
```json
{
  "data": { /* actual response data */ },
  "meta": {
    "timestamp": "2026-02-01T12:00:00Z",
    "version": "1.0",
    "requestId": "uuid"
  },
  "pagination": { /* if applicable */ },
  "errors": [ /* if applicable */ ]
}
```

**Error Response Format**:
```json
{
  "errors": [
    {
      "code": "VALIDATION_ERROR",
      "message": "Email address is invalid",
      "field": "email",
      "details": {}
    }
  ],
  "meta": {
    "timestamp": "2026-02-01T12:00:00Z",
    "requestId": "uuid"
  }
}
```

### 2.5 API Documentation

**Documentation Requirements**:
- Document EVERY endpoint before implementation
- Include request/response examples
- Document all parameters, headers, query strings
- Specify authentication requirements
- List all possible error responses
- Provide code examples in multiple languages
- Keep documentation synchronized with code (automate when possible)

**Tools**:
- OpenAPI/Swagger for REST APIs
- GraphQL introspection for GraphQL APIs
- Postman collections for testing
- Interactive API explorers

---

## 3. Data Management and Persistence

### 3.1 Database Design Principles

**Normalization vs. Denormalization**:
- Normalize to at least 3rd normal form by default
- Denormalize intentionally for performance, not by accident
- Document all denormalization decisions with rationale
- Use materialized views for complex queries
- Keep transaction boundaries small and focused

**Indexing Strategy**:
- Index foreign keys ALWAYS
- Index columns used in WHERE clauses frequently
- Index columns used in JOIN conditions
- Index columns used in ORDER BY
- Use composite indexes for multi-column queries
- Monitor index usage and remove unused indexes
- Understand index types (B-tree, Hash, GIN, GiST, etc.)

**Schema Versioning**:
- Use migration tools ALWAYS (never manual schema changes)
- Migrations must be reversible (up and down scripts)
- Test migrations in staging environment first
- Keep migrations small and atomic
- Never delete migrations that have been deployed
- Include data migrations when necessary

### 3.2 Query Optimization

**Query Performance Rules**:
- NEVER use `SELECT *` in production code
- Avoid N+1 query problems (use eager loading, joins)
- Use query analysis tools (EXPLAIN, query plans)
- Set query timeout limits
- Paginate large result sets ALWAYS
- Use connection pooling
- Monitor slow query logs
- Cache frequently accessed data appropriately

**ORM Best Practices**:
- Understand the SQL your ORM generates
- Use raw queries for complex operations when needed
- Lazy load relationships carefully (avoid N+1)
- Batch operations when possible
- Use transactions appropriately
- Monitor ORM-generated query performance

### 3.3 Data Integrity

**Constraints**:
- Use database constraints, not just application-level validation
- Implement foreign key constraints
- Use unique constraints where appropriate
- Use check constraints for data validation
- Use NOT NULL constraints appropriately
- Let the database enforce data integrity

**Transactions**:
- Use transactions for multi-step operations
- Keep transactions as short as possible
- Use appropriate isolation levels
- Handle transaction failures gracefully
- Implement retry logic for transient failures
- Use distributed transactions cautiously (2PC, SAGA pattern)

**ACID Compliance**:
- Understand when you need ACID guarantees
- Use appropriate database technologies for use case
- Design for consistency where needed
- Accept eventual consistency where appropriate
- Document consistency guarantees

### 3.4 Data Access Patterns

**Repository Pattern**:
- Abstract data access behind repository interfaces
- Repositories return domain objects, not database records
- Keep repositories focused on single aggregate
- Don't leak database concepts through repository API
- Make repositories testable with mock implementations

**Unit of Work Pattern**:
- Track changes to objects during a business transaction
- Coordinate writing changes to database
- Ensure atomicity of business operations
- Manage transaction boundaries explicitly

**CQRS (Command Query Responsibility Segregation)**:
- Separate read and write operations when beneficial
- Optimize read models for queries
- Optimize write models for commands
- Use eventual consistency between read and write models
- Implement event sourcing where appropriate

---

## 4. Security Standards (Backend-Specific)

### 4.1 Authentication and Authorization

**Authentication**:
- NEVER store passwords in plain text (use bcrypt, argon2, or similar)
- Implement proper password policies
- Use multi-factor authentication where appropriate
- Implement account lockout after failed attempts
- Use secure session management
- Implement proper token expiration and refresh
- Support OAuth 2.0 / OpenID Connect for third-party authentication

**JWT (JSON Web Tokens)**:
- Sign tokens with strong algorithms (RS256, ES256)
- Set appropriate expiration times (short-lived access tokens)
- Use refresh tokens for long-lived sessions
- Validate tokens on EVERY request
- Store sensitive claims encrypted
- Implement token revocation mechanism
- Never store sensitive data in JWT payload

**Authorization**:
- Implement role-based access control (RBAC)
- Use attribute-based access control (ABAC) for complex scenarios
- Check permissions at multiple levels (route, service, data)
- Use principle of least privilege
- Implement row-level security where needed
- Audit authorization decisions

### 4.2 Input Validation and Sanitization

**Rules**:
- Validate ALL inputs at API boundary
- Use allowlists, not denylists
- Validate data types, formats, lengths, ranges
- Sanitize inputs to prevent injection attacks
- Use parameterized queries ALWAYS (prevent SQL injection)
- Escape output appropriately for context
- Validate file uploads (type, size, content)

**Common Injection Prevention**:
- **SQL Injection**: Use parameterized queries, ORM safely
- **NoSQL Injection**: Validate and sanitize NoSQL queries
- **Command Injection**: Never execute user input as commands
- **LDAP Injection**: Escape LDAP queries properly
- **XML Injection**: Use safe XML parsers
- **XSS**: Sanitize output (though primarily frontend concern)

### 4.3 Secrets Management

**Secrets Handling**:
- NEVER hardcode secrets in code
- NEVER commit secrets to version control
- Use environment variables for configuration
- Use dedicated secret management tools (Vault, AWS Secrets Manager, etc.)
- Rotate secrets regularly
- Encrypt secrets at rest
- Audit secret access
- Use different secrets per environment

**API Keys and Tokens**:
- Generate cryptographically secure random keys
- Hash API keys before storage
- Implement key rotation
- Support multiple active keys for rotation
- Log API key usage
- Implement rate limiting per key

### 4.4 Data Protection

**Encryption**:
- Encrypt sensitive data at rest
- Use TLS/SSL for data in transit ALWAYS
- Use strong encryption algorithms (AES-256)
- Manage encryption keys properly
- Implement field-level encryption for sensitive data
- Use database-level encryption where appropriate

**Data Privacy**:
- Implement data minimization (collect only what's needed)
- Support data anonymization and pseudonymization
- Implement right to be forgotten (GDPR compliance)
- Provide data export functionality
- Log data access for audit trails
- Implement data retention policies

**PII (Personally Identifiable Information)**:
- Identify and classify PII
- Minimize PII collection and storage
- Encrypt PII at rest and in transit
- Implement access controls for PII
- Audit PII access
- Support data subject rights (GDPR, CCPA)

### 4.5 API Security

**Rate Limiting**:
- Implement rate limiting on ALL public endpoints
- Use different limits for different user tiers
- Return appropriate headers (X-RateLimit-*)
- Implement distributed rate limiting for scaled systems
- Monitor for rate limit abuse

**CORS (Cross-Origin Resource Sharing)**:
- Configure CORS policies explicitly
- Use allowlists for origins
- Don't use wildcard (*) in production
- Validate origin headers
- Configure appropriate methods and headers

**Security Headers**:
- Implement all relevant security headers
- Use HSTS (HTTP Strict Transport Security)
- Implement CSP (Content Security Policy)
- Use X-Frame-Options
- Use X-Content-Type-Options
- Implement proper CORS headers

---

## 5. Performance and Scalability

### 5.1 Caching Strategies

**Caching Layers**:
- **Application Cache**: In-memory cache (Redis, Memcached)
- **Database Cache**: Query result caching
- **CDN Cache**: Static assets and API responses
- **Browser Cache**: HTTP caching headers

**Caching Rules**:
- Cache read-heavy, infrequently changing data
- Implement cache invalidation strategies
- Use appropriate TTL (Time To Live) values
- Implement cache warming for critical data
- Monitor cache hit rates
- Handle cache failures gracefully (cache stampede prevention)

**Cache Invalidation Patterns**:
- Time-based expiration (TTL)
- Event-based invalidation
- Write-through caching
- Cache-aside pattern
- Read-through caching

### 5.2 Asynchronous Processing

**When to Use Async**:
- Long-running operations
- Background jobs
- Email sending
- File processing
- Third-party API calls
- Batch operations
- Scheduled tasks

**Message Queue Patterns**:
- Use message queues for decoupling (RabbitMQ, Kafka, SQS, etc.)
- Implement idempotent message handlers
- Use dead letter queues for failed messages
- Implement retry logic with exponential backoff
- Monitor queue depth and processing time
- Implement proper message acknowledgment

**Background Job Processing**:
- Use job queues (Sidekiq, Celery, Bull, etc.)
- Implement job priority levels
- Set appropriate timeouts
- Implement job retry logic
- Monitor job success/failure rates
- Implement job deduplication

### 5.3 Database Performance

**Connection Pooling**:
- ALWAYS use connection pooling
- Configure appropriate pool sizes
- Monitor connection usage
- Implement connection timeout
- Handle pool exhaustion gracefully

**Read/Write Splitting**:
- Route reads to read replicas
- Route writes to primary database
- Handle replication lag appropriately
- Implement failover strategies
- Monitor replication status

**Sharding and Partitioning**:
- Partition large tables appropriately
- Implement sharding for horizontal scaling
- Choose appropriate shard keys
- Minimize cross-shard queries
- Document sharding strategy

### 5.4 API Performance

**Response Time Optimization**:
- Set and monitor SLA for API response times
- Target <200ms for simple operations
- Target <1s for complex operations
- Use async processing for long operations
- Implement timeout for all external calls

**Pagination**:
- ALWAYS paginate large result sets
- Implement cursor-based pagination for large datasets
- Provide page size limits
- Return total count when appropriate
- Support different pagination strategies

**Compression**:
- Enable response compression (gzip, brotli)
- Compress large payloads
- Set appropriate compression levels
- Monitor compression ratio vs. CPU usage

---

## 6. Observability and Monitoring

### 6.1 Logging Standards

**Logging Levels (Correct Usage)**:
- **DEBUG**: Detailed information for debugging (disabled in production)
- **INFO**: General informational messages
- **WARN**: Warning messages, potential issues
- **ERROR**: Error messages, handled exceptions
- **FATAL**: Critical errors, application cannot continue

**Logging Best Practices**:
- Use structured logging (JSON format)
- Include correlation/request IDs in all logs
- Log at appropriate levels
- Don't log sensitive information (PII, passwords, tokens)
- Include relevant context in log messages
- Use consistent log message formats
- Implement log aggregation (ELK, Splunk, CloudWatch, etc.)

**What to Log**:
- Application startup/shutdown
- Authentication attempts (success/failure)
- Authorization failures
- API requests/responses (sanitized)
- Database queries (slow queries)
- External API calls
- Errors and exceptions with stack traces
- Performance metrics
- Business-critical operations

### 6.2 Metrics and Monitoring

**Application Metrics**:
- Request rate (requests per second)
- Response time (p50, p95, p99)
- Error rate (4xx, 5xx responses)
- Active connections
- Queue depth
- Cache hit rate
- Database query performance

**Infrastructure Metrics**:
- CPU utilization
- Memory usage
- Disk I/O
- Network I/O
- Database connections
- Thread pool utilization

**Business Metrics**:
- User signups
- Transactions processed
- Revenue metrics
- Conversion rates
- Feature usage

**Monitoring Tools**:
- Use APM tools (New Relic, DataDog, AppDynamics)
- Implement health check endpoints
- Set up alerting for critical metrics
- Create dashboards for visibility
- Monitor trends, not just current values

### 6.3 Distributed Tracing

**Tracing Requirements**:
- Implement distributed tracing for microservices
- Use correlation IDs across service boundaries
- Trace requests end-to-end
- Instrument critical code paths
- Use tracing tools (Jaeger, Zipkin, X-Ray)
- Monitor trace performance overhead

### 6.4 Health Checks and Readiness

**Health Check Endpoints**:
- Implement `/health` endpoint (liveness probe)
- Implement `/ready` endpoint (readiness probe)
- Check database connectivity
- Check external service dependencies
- Return appropriate status codes (200, 503)
- Include version information
- Make checks fast (<1s)

---

## 7. Error Handling and Resilience

### 7.1 Error Handling Principles

**Error Handling Rules**:
- NEVER swallow exceptions silently
- Log all errors with full context
- Return appropriate HTTP status codes
- Provide helpful error messages to clients
- Don't expose internal implementation details
- Use error codes for programmatic handling
- Implement global error handlers
- Handle errors at appropriate levels

**Error Categories**:
- **Client Errors (4xx)**: User can fix (validation, authentication)
- **Server Errors (5xx)**: System issues (database down, external API failure)
- **Transient Errors**: Temporary issues (timeout, rate limit)
- **Permanent Errors**: Cannot be retried successfully

### 7.2 Circuit Breaker Pattern

**Implementation**:
- Wrap external service calls with circuit breaker
- Monitor failure rates
- Open circuit after threshold failures
- Implement half-open state for recovery
- Provide fallback responses
- Use libraries (Hystrix, resilience4j, Polly)

**Configuration**:
- Set appropriate failure thresholds
- Configure timeout values
- Set circuit reset timeout
- Implement graceful degradation
- Monitor circuit breaker states

### 7.3 Retry Logic

**Retry Strategies**:
- Implement exponential backoff
- Set maximum retry attempts
- Only retry transient failures
- Implement jitter to prevent thundering herd
- Don't retry non-idempotent operations blindly
- Log retry attempts

**Idempotency**:
- Design operations to be idempotent when possible
- Use idempotency keys for critical operations
- Store idempotency keys with expiration
- Return cached response for duplicate requests

### 7.4 Timeout Management

**Timeout Strategy**:
- Set timeouts on ALL external calls
- Set timeouts on database queries
- Set timeouts on HTTP requests
- Use cascading timeouts (shorter at each level)
- Make timeouts configurable
- Monitor timeout occurrences

---

## 8. Testing for Backend Systems

### 8.1 Unit Testing (Backend-Specific)

**What to Test**:
- Business logic functions
- Validation logic
- Data transformations
- Utility functions
- Domain models
- Service methods (with mocked dependencies)

**Testing Rules**:
- Mock all external dependencies (databases, APIs, file systems)
- Test edge cases and error conditions
- Test boundary conditions
- Use test data builders/factories
- Keep tests fast (<100ms per test)
- Make tests deterministic

### 8.2 Integration Testing

**Database Integration Tests**:
- Use test databases (SQLite in-memory, Docker containers)
- Test actual database queries
- Test transactions and rollbacks
- Test database constraints
- Clean up test data after each test
- Test migrations

**API Integration Tests**:
- Test actual HTTP endpoints
- Test authentication and authorization
- Test request/response formats
- Test error scenarios
- Test rate limiting
- Use tools like Supertest, RestAssured

**External Service Integration Tests**:
- Mock external APIs (use tools like WireMock, nock)
- Test error handling when external services fail
- Test timeout scenarios
- Test retry logic
- Use contract testing when possible

### 8.3 Contract Testing

**Provider Contract Tests**:
- Test that your API adheres to its contract
- Use tools like Pact, Spring Cloud Contract
- Version contracts
- Test backward compatibility
- Share contracts with consumers

**Consumer Contract Tests**:
- Test that you use external APIs correctly
- Verify assumptions about external API behavior
- Detect breaking changes early

### 8.4 Load and Performance Testing

**Load Testing**:
- Test system under expected load
- Test system under peak load
- Test system under stress (beyond capacity)
- Identify bottlenecks
- Measure response times under load
- Use tools like JMeter, Gatling, k6, Artillery

**Performance Benchmarks**:
- Establish baseline performance metrics
- Monitor performance over time
- Detect performance regressions
- Test with realistic data volumes
- Test with realistic user scenarios

### 8.5 Security Testing

**Security Test Requirements**:
- Test authentication mechanisms
- Test authorization rules
- Test input validation
- Test for injection vulnerabilities
- Test rate limiting
- Test for exposed secrets
- Use SAST/DAST tools
- Perform penetration testing

---

## 9. Deployment and DevOps

### 9.1 Containerization

**Docker Best Practices**:
- Use official base images
- Create multi-stage builds
- Minimize image size
- Don't run as root user
- Use .dockerignore
- Pin dependency versions
- Implement health checks in Dockerfile
- Tag images appropriately

**Container Security**:
- Scan images for vulnerabilities
- Use minimal base images
- Don't include secrets in images
- Update base images regularly
- Use read-only file systems where possible

### 9.2 Infrastructure as Code

**IaC Principles**:
- Define ALL infrastructure in code
- Version control infrastructure definitions
- Use tools like Terraform, CloudFormation, Pulumi
- Make infrastructure reproducible
- Test infrastructure changes
- Implement proper state management

### 9.3 CI/CD Pipeline

**Pipeline Stages**:
1. **Build**: Compile, dependency installation
2. **Test**: Run all tests (unit, integration)
3. **Security Scan**: SAST, dependency scanning
4. **Build Artifacts**: Create deployable artifacts
5. **Deploy to Staging**: Automated deployment
6. **Smoke Tests**: Basic validation
7. **Deploy to Production**: Manual or automated
8. **Post-Deployment Tests**: Verify deployment

**Pipeline Requirements**:
- Fail fast on errors
- Run tests in parallel where possible
- Cache dependencies
- Implement deployment rollback
- Notify team of failures
- Track deployment metrics

### 9.4 Database Migrations

**Migration Strategy**:
- Use migration tools (Flyway, Liquibase, Alembic, etc.)
- Test migrations in staging first
- Implement backward-compatible migrations
- Plan for zero-downtime deployments
- Version migrations
- Include rollback scripts
- Separate schema and data migrations

**Migration Best Practices**:
- Keep migrations small and focused
- Test migrations with production-like data
- Back up database before migrations
- Monitor migration execution time
- Handle migration failures gracefully

### 9.5 Blue-Green Deployments

**Implementation**:
- Maintain two identical environments
- Route traffic to active environment
- Deploy to inactive environment
- Smoke test inactive environment
- Switch traffic to new environment
- Keep old environment for quick rollback

### 9.6 Feature Flags

**Feature Flag Usage**:
- Decouple deployment from release
- Test features in production safely
- Implement gradual rollouts
- A/B test new features
- Quick rollback without redeployment
- Use feature flag management tools

---

## 10. Microservices Patterns

### 10.1 Service Communication

**Synchronous Communication**:
- REST APIs for request-response
- gRPC for high-performance RPC
- GraphQL for flexible queries
- Implement circuit breakers
- Set appropriate timeouts
- Handle partial failures

**Asynchronous Communication**:
- Message queues for decoupling
- Event-driven architecture
- Pub/sub patterns
- Event sourcing where appropriate
- Implement idempotent consumers
- Handle message failures

### 10.2 Service Discovery

**Discovery Mechanisms**:
- Use service registry (Consul, Eureka, etcd)
- Implement health checks
- Handle service failures gracefully
- Use client-side or server-side discovery
- Implement service mesh where appropriate

### 10.3 API Gateway Pattern

**Gateway Responsibilities**:
- Routing and load balancing
- Authentication and authorization
- Rate limiting and throttling
- Request/response transformation
- Protocol translation
- Aggregation of responses
- Caching
- Logging and monitoring

### 10.4 Data Consistency

**Consistency Patterns**:
- **Strong Consistency**: Use when critical (financial transactions)
- **Eventual Consistency**: Accept for non-critical data
- **SAGA Pattern**: Manage distributed transactions
- **Two-Phase Commit**: Use cautiously (performance impact)
- **Event Sourcing**: Store events, rebuild state

**Handling Distributed Transactions**:
- Avoid distributed transactions when possible
- Use SAGA pattern for long-running transactions
- Implement compensating transactions
- Design for idempotency
- Monitor for orphaned transactions

---

## 11. API Gateway and Backend for Frontend (BFF)

### 11.1 API Gateway Pattern

**Responsibilities**:
- Single entry point for clients
- Request routing to appropriate services
- Authentication and authorization
- Rate limiting and throttling
- Request/response aggregation
- Protocol translation (REST to gRPC)
- Caching frequently accessed data
- Load balancing

**Implementation Considerations**:
- Don't put business logic in gateway
- Keep gateway thin and focused
- Implement proper error handling
- Monitor gateway performance
- Scale gateway independently
- Implement circuit breakers
- Use proven gateway solutions (Kong, API Gateway, Nginx)

### 11.2 Backend for Frontend (BFF)

**BFF Pattern**:
- Create separate backends for different client types (web, mobile, IoT)
- Tailor API responses to client needs
- Aggregate data from multiple services
- Reduce client complexity
- Optimize for specific client requirements
- Handle client-specific logic

**BFF Best Practices**:
- Keep BFF thin, delegate to services
- Don't duplicate business logic across BFFs
- Version BFFs independently
- Monitor BFF performance separately
- Implement proper caching

---

## 12. Event-Driven Architecture

### 12.1 Event Design

**Event Characteristics**:
- Events represent facts that occurred
- Events are immutable
- Events should be self-contained
- Events should include relevant context
- Events should have unique identifiers
- Events should be versioned

**Event Naming Conventions**:
- Use past tense: `UserCreated`, `OrderPlaced`, `PaymentProcessed`
- Include domain context: `Billing.PaymentReceived`
- Be specific and descriptive
- Use consistent naming patterns

### 12.2 Event Sourcing

**Event Sourcing Principles**:
- Store events as source of truth
- Rebuild state by replaying events
- Events are append-only
- Support temporal queries (state at any point in time)
- Enable audit trails automatically
- Support what-if scenarios

**Implementation Considerations**:
- Use event store (EventStore, Kafka, custom)
- Implement snapshots for performance
- Handle event schema evolution
- Implement event upcasting for old events
- Consider storage requirements

### 12.3 CQRS (Command Query Responsibility Segregation)

**CQRS Pattern**:
- Separate write model (commands) from read model (queries)
- Optimize each model independently
- Use eventual consistency between models
- Scale reads and writes independently
- Support complex queries efficiently

**When to Use CQRS**:
- Complex domain with different read/write patterns
- High read-to-write ratio
- Need for different data models for reads/writes
- Scalability requirements differ

---

## 13. Backend-Specific Best Practices

### 13.1 Configuration Management

**Configuration Rules**:
- NEVER hardcode configuration
- Use environment variables for environment-specific config
- Use configuration files for application config
- Validate configuration at startup
- Fail fast on invalid configuration
- Document all configuration options
- Provide sensible defaults
- Support configuration reload without restart (where appropriate)

**Configuration Hierarchy**:
1. Default values in code
2. Configuration files
3. Environment variables
4. Runtime configuration (feature flags, remote config)

### 13.2 Dependency Injection

**DI Principles**:
- Use DI for managing dependencies
- Inject interfaces, not implementations
- Configure DI container at application startup
- Use constructor injection by default
- Avoid service locator pattern
- Make dependencies explicit
- Use DI framework appropriate for your language

### 13.3 Middleware and Interceptors

**Middleware Usage**:
- Authentication and authorization
- Request logging
- Error handling
- Request validation
- Response transformation
- Compression
- CORS handling
- Rate limiting

**Middleware Best Practices**:
- Keep middleware focused and single-purpose
- Order middleware carefully
- Make middleware reusable
- Test middleware independently
- Document middleware purpose

### 13.4 Background Jobs and Scheduled Tasks

**Job Processing**:
- Use job queues for background processing
- Make jobs idempotent
- Implement job retry logic
- Set job timeouts
- Monitor job success/failure
- Implement job prioritization
- Use dead letter queues

**Scheduled Tasks**:
- Use cron or scheduler libraries
- Don't use cron for critical business logic
- Make scheduled tasks idempotent
- Prevent concurrent execution of same task
- Log scheduled task execution
- Monitor scheduled task failures

### 13.5 File Upload and Processing

**File Upload Best Practices**:
- Validate file type, size, content
- Scan files for malware
- Store files outside web root
- Use unique, non-predictable file names
- Implement upload rate limiting
- Stream large file uploads
- Provide upload progress for large files
- Clean up failed/incomplete uploads

**File Storage**:
- Use object storage (S3, Azure Blob, GCS) for scalability
- Implement file retention policies
- Encrypt sensitive files at rest
- Generate signed URLs for access control
- Implement CDN for file delivery
- Back up files regularly

---

## 14. Third-Party Integration Standards

### 14.1 External API Integration

**Integration Best Practices**:
- Abstract external APIs behind interfaces
- Implement retry logic with exponential backoff
- Set appropriate timeouts
- Use circuit breakers
- Cache responses where appropriate
- Log all external API calls
- Monitor external API health and performance
- Handle rate limits gracefully
- Implement webhook handling for callbacks

**API Client Design**:
- Create dedicated client classes/modules
- Version API clients
- Handle API changes gracefully
- Mock external APIs in tests
- Document external API dependencies
- Monitor API quotas and usage

### 14.2 Webhook Handling

**Webhook Best Practices**:
- Validate webhook signatures
- Process webhooks asynchronously
- Implement idempotency for webhook processing
- Return 200 status quickly
- Retry failed webhook processing
- Log all webhook events
- Monitor webhook delivery failures

### 14.3 Payment Gateway Integration

**Payment Processing**:
- NEVER store credit card numbers (PCI compliance)
- Use tokenization for recurring payments
- Implement proper error handling for payment failures
- Log all payment transactions
- Implement idempotency for payments
- Handle refunds and chargebacks
- Support multiple payment methods
- Implement fraud detection
- Test with sandbox environments

---

## 15. Compliance and Regulations

### 15.1 GDPR Compliance (EU)

**Requirements**:
- Obtain explicit user consent
- Support right to access (data export)
- Support right to be forgotten (data deletion)
- Implement data minimization
- Maintain processing records
- Report data breaches within 72 hours
- Implement privacy by design
- Conduct privacy impact assessments

### 15.2 CCPA Compliance (California)

**Requirements**:
- Disclose data collection and usage
- Support right to access
- Support right to delete
- Support right to opt-out of data sale
- Implement "Do Not Sell My Personal Information"
- Provide clear privacy policy

### 15.3 PCI DSS (Payment Card Industry)

**Requirements**:
- Encrypt cardholder data in transit and at rest
- Use and regularly update anti-virus software
- Develop and maintain secure systems
- Restrict access to cardholder data
- Regularly test security systems
- Maintain information security policy

### 15.4 HIPAA (Healthcare)

**Requirements**:
- Encrypt PHI (Protected Health Information)
- Implement access controls
- Maintain audit logs
- Implement data backup and recovery
- Develop contingency plans
- Conduct risk assessments

### 15.5 SOC 2 Compliance

**Requirements**:
- Implement security controls
- Ensure availability of systems
- Maintain processing integrity
- Ensure confidentiality
- Protect privacy
- Document policies and procedures
- Conduct regular audits

---

## 16. Disaster Recovery and Business Continuity

### 16.1 Backup Strategy

**Backup Requirements**:
- Implement automated backups
- Test backup restoration regularly
- Store backups in multiple locations
- Encrypt backups
- Implement backup retention policies
- Document backup procedures
- Monitor backup success/failure

**Backup Types**:
- Full backups (weekly)
- Incremental backups (daily)
- Point-in-time recovery for databases
- Configuration backups
- Code repository backups

### 16.2 Disaster Recovery Plan

**DR Plan Components**:
- Define RPO (Recovery Point Objective)
- Define RTO (Recovery Time Objective)
- Document recovery procedures
- Identify critical systems
- Establish communication protocols
- Assign responsibilities
- Test DR plan regularly

**Failover Strategies**:
- Active-passive failover
- Active-active failover
- Multi-region deployment
- Database replication
- Automated failover where possible

### 16.3 High Availability

**HA Principles**:
- Eliminate single points of failure
- Implement redundancy at all levels
- Use load balancing
- Implement health checks
- Automate recovery processes
- Monitor system availability
- Design for graceful degradation

---

## 17. Documentation Requirements

### 17.1 API Documentation

**Required Documentation**:
- All endpoints with descriptions
- Request/response examples
- Authentication requirements
- Rate limits
- Error codes and messages
- Versioning information
- Changelog for API versions
- Getting started guide
- Code examples

### 17.2 Architecture Documentation

**Required Documentation**:
- System architecture diagrams
- Component interactions
- Data flow diagrams
- Deployment architecture
- Technology stack
- Design decisions and rationale
- Scalability considerations
- Security architecture

### 17.3 Operational Documentation

**Required Documentation**:
- Deployment procedures
- Configuration guide
- Monitoring and alerting setup
- Incident response procedures
- Backup and recovery procedures
- Scaling procedures
- Common troubleshooting scenarios
- Runbooks for operational tasks

### 17.4 Developer Documentation

**Required Documentation**:
- Setup and installation guide
- Development environment setup
- Coding standards and conventions
- Testing guidelines
- Debugging procedures
- Common development tasks
- Architecture patterns used
- Dependency documentation

---

## 18. Performance Optimization Checklist

### 18.1 Database Optimization

- [ ] Queries are indexed appropriately
- [ ] Slow queries are identified and optimized
- [ ] N+1 query problems are eliminated
- [ ] Connection pooling is configured
- [ ] Query timeout is set
- [ ] Database caching is implemented
- [ ] Appropriate isolation levels are used
- [ ] Batch operations are used where applicable

### 18.2 API Optimization

- [ ] Response payloads are minimized
- [ ] Compression is enabled
- [ ] Pagination is implemented
- [ ] Caching headers are set appropriately
- [ ] Unnecessary data is not returned
- [ ] Response time SLAs are defined and monitored
- [ ] Rate limiting is implemented
- [ ] CDN is used for static content

### 18.3 Code Optimization

- [ ] Algorithms are efficient
- [ ] Unnecessary computations are avoided
- [ ] Resource cleanup is performed
- [ ] Memory leaks are prevented
- [ ] Lazy loading is used appropriately
- [ ] Object pooling is used where beneficial
- [ ] Profiling is performed regularly

---

## 19. Common Backend Anti-Patterns to AVOID

### 19.1 The God Service

**Problem**: Single service that does everything
**Solution**: Break into smaller, focused services

### 19.2 Chatty APIs

**Problem**: Multiple API calls required for single operation
**Solution**: Provide aggregated endpoints, use GraphQL, implement BFF

### 19.3 Database as Integration Point

**Problem**: Multiple services accessing same database
**Solution**: Each service owns its data, communicate via APIs/events

### 19.4 Distributed Monolith

**Problem**: Microservices that are tightly coupled
**Solution**: Define clear boundaries, use async communication, implement proper contracts

### 19.5 Premature Optimization

**Problem**: Optimizing before identifying actual bottlenecks
**Solution**: Measure first, optimize based on data

### 19.6 Ignoring Transactionality

**Problem**: Not considering transaction boundaries in distributed systems
**Solution**: Implement SAGA pattern, design for eventual consistency, use idempotency

### 19.7 Silent Failures

**Problem**: Errors are caught but not logged or handled
**Solution**: Log all errors, implement proper error handling, alert on critical errors

---

## 20. Enforcement and Continuous Improvement

### 20.1 Code Review Checklist

Backend-specific code review requirements:
- [ ] Architecture follows layered approach
- [ ] SOLID principles are applied
- [ ] All database queries are optimized and indexed
- [ ] Proper error handling is implemented
- [ ] Security best practices are followed
- [ ] API design follows REST/GraphQL standards
- [ ] Tests cover all critical paths
- [ ] Logging is implemented appropriately
- [ ] Configuration is externalized
- [ ] Documentation is updated

### 20.2 Automated Checks

**Mandatory CI/CD Checks**:
- [ ] All tests pass (unit, integration)
- [ ] Code coverage meets minimum threshold (80%)
- [ ] Static analysis passes (no critical issues)
- [ ] Security scan passes (no high/critical vulnerabilities)
- [ ] Performance tests pass
- [ ] API contract tests pass
- [ ] Code formatting is correct
- [ ] No secrets in code

### 20.3 Metrics and KPIs

**Track These Metrics**:
- API response time (p50, p95, p99)
- Error rate (4xx, 5xx)
- Throughput (requests per second)
- Database query performance
- Cache hit rate
- Service availability (uptime)
- Deployment frequency
- Mean time to recovery (MTTR)
- Code coverage percentage
- Technical debt ratio

---

## 21. Conclusion

This backend development guide complements the general AI Agent Development Guidelines (ai-agents.md) by providing specific, actionable standards for backend development. Together, these documents establish a comprehensive framework for building professional, scalable, secure, and maintainable backend systems.

**Core Backend Principles**:

1. **Separation of Concerns**: Always maintain clear boundaries between layers
2. **API-First Design**: Design and document APIs before implementation
3. **Security by Default**: Build security into every layer
4. **Design for Failure**: Expect and handle failures gracefully
5. **Performance Matters**: Monitor, measure, and optimize
6. **Data Integrity**: Protect data at all costs
7. **Observability**: Make systems transparent and debuggable
8. **Scalability**: Design for growth from day one
9. **Testability**: Test everything, automate testing
10. **Documentation**: Document for your future self and others

**Remember**: Backend systems are the foundation of applications. They handle critical data, business logic, and integrations. The quality of backend code directly impacts system reliability, security, performance, and maintainability. These guidelines ensure that every backend system we build is production-ready, professional, and built to last.

---

**Document Version**: 1.0  
**Last Updated**: February 2026  
**Applies To**: All backend projects, all backend technologies, all backend team members, all AI agents  
**Companion Document**: ai-agents.md (General AI Agent Development Guidelines)  
**Status**: Active and Enforced  
**Review Cycle**: Quarterly