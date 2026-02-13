---
name: setup-dotnet-integration-tests
description: "Scaffolds .NET integration tests using WebApplicationFactory, Testcontainers, WireMock, and xUnit. Use when creating integration test projects or setting up test infrastructure for ASP.NET Core APIs."
---

# Writing .NET Integration Tests

## Workflow

### 1. Understand the system under test

- Identify the host app's `Program` class (needed for `WebApplicationFactory<Program>`)
- Check if the module is conditionally loaded (e.g., `#if` flags) — if so, register it explicitly in the test factory
- Map all external dependencies: databases, HTTP clients, message brokers, auth

### 2. Scaffold the test project

Create the project with these core packages:

```xml
<PackageReference Include="xunit" />
<PackageReference Include="xunit.runner.visualstudio" />
<PackageReference Include="Microsoft.NET.Test.Sdk" />
<PackageReference Include="Microsoft.AspNetCore.Mvc.Testing" />
<PackageReference Include="Testcontainers.PostgreSql" />
<PackageReference Include="Respawn" />
<PackageReference Include="WireMock.Net" />
<PackageReference Include="NSubstitute" />
```

Add `AssemblyInfo.cs` to disable parallel test execution:
```csharp
[assembly: CollectionBehavior(DisableTestParallelization = true)]
```

### 3. Build the infrastructure (bottom-up)

Follow this class hierarchy:

| Class | Responsibility |
|---|---|
| `TestContainers` | Static class, starts DB containers once per test run |
| `WebApplicationFactory` subclass | DI overrides: test DBs, WireMock URLs, test auth, mocked services |
| `Fixture : IAsyncLifetime` | Owns factory + WireMock + HttpClient, runs DB migrations |
| `TestBase : IAsyncLifetime` | Per-test cleanup: Respawn DB reset + WireMock reset |
| `Collection` | xUnit `ICollectionFixture<Fixture>` binding |

### 4. Replace dependencies in the factory

In `ConfigureWebHost`, replace dependencies in this order:

1. **Remove hosted services** — prevent background services from starting
2. **Register the module** — if conditionally compiled, call the module registration explicitly
3. **Replace databases** — point DbContexts at Testcontainers, preserve production options (lazy loading, naming conventions, interceptors)
4. **Override HTTP client URLs** — point all base URLs at WireMock
5. **Configure auth** — symmetric key JWT with no issuer/audience/lifetime validation
6. **Replace external service interfaces** — NSubstitute mocks for services not under test
7. **Replace messaging** — mock event publishers to avoid native library dependencies (e.g., librdkafka)


## Auth Patterns

### JWT claims required by Illumina auth pipeline

The `GssConfigureAuthContextWithLoggingFilter` (via `AuthContext.CreateUserIdentityContext`) requires these claims:

| Claim | Purpose | Required for |
|---|---|---|
| `sub` | Subject | All authenticated requests |
| `scope` | Authorization scopes (comma-separated) | Scope-based authorization |
| `uid` | User ID | Full auth (filter creates `UserIdentityContext`) |
| `tid` | Tenant ID | Full auth |
| `tns` | Tenant namespace | Full auth |
| `mem` | Membership JSON | Full auth |

Three levels of auth in tests:

```csharp
// Level 1: No auth → 401
var request = new HttpRequestMessage(HttpMethod.Post, url)
    .WithJsonContent(body);

// Level 2: Wrong scope → 403 (only sub + scope needed)
var jwt = new JwtClaimsBuilder()
    .WithSub("test-user")
    .WithScopes("wrong.scope")
    .GenerateJwt();

// Level 3: Full auth → passes through to endpoint logic
var jwt = new JwtClaimsBuilder()
    .WithSub("test-user")
    .WithScopes("required.scope")
    .WithClaim("uid", "test-user")
    .WithClaim("tid", "test-tenant")
    .WithClaim("tns", "test-tenant")
    .WithClaim("mem", "{ 'tid:test-tenant': '*'}")
    .GenerateJwt();
```

### IJwtValidator override

The host app registers `IJwtValidator` with the production signing key. The test factory must also override it with the test key, otherwise `GssConfigureAuthContextWithLoggingFilter` rejects test JWTs:

```csharp
services.RemoveAll<IJwtValidator>();
services.AddSingleton<IJwtValidator>(_ => new JwtValidator(tokenValidationParameters, false));
```

## Common Pitfalls

### Missing request body fields
Endpoint `Request` models have `[Required]` attributes. Always check the model and include all required fields, or the test gets 400 instead of the expected status.

### Database extensions (citext)
If a DbContext uses PostgreSQL extensions like `citext`, run `CREATE EXTENSION IF NOT EXISTS citext;` on the test database **before** calling `EnsureCreated()`.

### Respawn configuration
Reset with `SchemasToInclude = ["public"]`, `DbAdapter = DbAdapter.Postgres`, and `TablesToIgnore` for migration history tables.

## Debugging test failures

Set the factory environment to `"Development"` temporarily to get detailed exception info in response bodies instead of generic 500 messages:
```csharp
builder.UseEnvironment("Development");
```
Read the response body to see the real exception:
```csharp
var body = await response.Content.ReadAsStringAsync();
```
Revert to `"Test"` after debugging.
