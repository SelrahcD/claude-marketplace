# Database Testing

Guidelines for tests that interact with databases.

## Unit Tests vs Integration Tests

**Unit tests** should NOT touch a real database. Instead:

- Use in-memory fake repositories
- Test business logic in isolation
- External dependencies behind interfaces (hexagonal architecture)

**Integration tests** verify database interactions work correctly.

## Unit Testing with Fake Repositories

With hexagonal architecture, database access is behind a port (interface). Create an in-memory implementation for tests.

```typescript
// Port (interface)
interface UserRepository {
  save(user: User): Promise<void>;
  findById(id: string): Promise<User | null>;
  findByEmail(email: string): Promise<User | null>;
}

// Production adapter
class PostgresUserRepository implements UserRepository {
  async findById(id: string): Promise<User | null> {
    const row = await this.db.query('SELECT * FROM users WHERE id = $1', [id]);
    return row ? mapToUser(row) : null;
  }
  // ...
}

// Test fake
class InMemoryUserRepository implements UserRepository {
  private users = new Map<string, User>();

  async save(user: User): Promise<void> {
    this.users.set(user.id, user);
  }

  async findById(id: string): Promise<User | null> {
    return this.users.get(id) || null;
  }

  async findByEmail(email: string): Promise<User | null> {
    for (const user of this.users.values()) {
      if (user.email === email) return user;
    }
    return null;
  }

  // Test helper
  givenUser(user: User): void {
    this.users.set(user.id, user);
  }

  clear(): void {
    this.users.clear();
  }
}
```

### Using Fake Repository in Tests

```typescript
test('returns null when user not found', async () => {
  const repository = new InMemoryUserRepository();
  const service = new UserService(repository);

  const result = await service.getUser('unknown-id');

  expect(result).toBeNull();
});

test('updates existing user', async () => {
  const repository = new InMemoryUserRepository();
  const existingUser = createUser({ id: '123', name: 'Alice' });
  repository.givenUser(existingUser);
  const service = new UserService(repository);

  await service.updateName('123', 'Bob');

  const updated = await repository.findById('123');
  expect(updated?.name).toBe('Bob');
});
```

## Integration Tests with Real Database

When you need to test actual database behavior:

### 1. Use Test Containers

Spin up a real database in a container for tests.

```typescript
import { PostgreSqlContainer } from '@testcontainers/postgresql';

describe('UserRepository Integration', () => {
  let container: PostgreSqlContainer;
  let db: Database;

  beforeAll(async () => {
    container = await new PostgreSqlContainer().start();
    db = await connectToDatabase(container.getConnectionUri());
    await runMigrations(db);
  });

  afterAll(async () => {
    await db.close();
    await container.stop();
  });

  // Tests use real database
});
```

### 2. Isolate Test Data

Each test should create its own data and clean up after.

```typescript
// ❌ Bad: Tests share data
beforeAll(async () => {
  await db.query("INSERT INTO users VALUES ('shared-user', 'Alice')");
});

test('finds user', async () => {
  const user = await repo.findById('shared-user');
  expect(user).toBeDefined();
});

test('updates user', async () => {
  await repo.update('shared-user', { name: 'Bob' });
  // Affects other tests!
});

// ✅ Good: Each test has isolated data
test('finds user by id', async () => {
  const userId = randomId();
  await db.query('INSERT INTO users VALUES ($1, $2)', [userId, 'Alice']);

  const user = await repo.findById(userId);

  expect(user?.name).toBe('Alice');
});

test('updates user name', async () => {
  const userId = randomId();
  await db.query('INSERT INTO users VALUES ($1, $2)', [userId, 'Alice']);

  await repo.update(userId, { name: 'Bob' });

  const updated = await repo.findById(userId);
  expect(updated?.name).toBe('Bob');
});
```

### 3. Use Transactions for Cleanup

Wrap each test in a transaction that rolls back.

```typescript
describe('UserRepository', () => {
  let transaction: Transaction;

  beforeEach(async () => {
    transaction = await db.beginTransaction();
  });

  afterEach(async () => {
    await transaction.rollback();
  });

  test('saves user', async () => {
    const repo = new UserRepository(transaction);
    const user = createUser();

    await repo.save(user);

    const saved = await repo.findById(user.id);
    expect(saved).toEqual(user);
    // Transaction rolls back - no cleanup needed
  });
});
```

## Parallel Execution with Databases

Database tests must be safe to run in parallel.

### Use Unique Identifiers

```typescript
// ✅ Good: Random IDs prevent collisions
test('creates order', async () => {
  const orderId = randomId();
  const userId = randomId();

  await createUser({ id: userId });
  await createOrder({ id: orderId, userId });

  const order = await orderRepo.findById(orderId);
  expect(order?.userId).toBe(userId);
});
```

### Use Schema Isolation

Each test file or worker gets its own schema.

```typescript
// In test setup
const schemaName = `test_${process.env.VITEST_POOL_ID}`;
await db.query(`CREATE SCHEMA IF NOT EXISTS ${schemaName}`);
await db.query(`SET search_path TO ${schemaName}`);
```

### Use Separate Databases

For complete isolation, each worker uses a different database.

```typescript
const dbName = `test_db_${process.env.VITEST_POOL_ID}`;
const connectionString = `postgresql://localhost/${dbName}`;
```

## Test Data Builders for Database Tests

Create builders that handle database insertion.

```typescript
class UserBuilder {
  private data: Partial<User> = {};

  withName(name: string): this {
    this.data.name = name;
    return this;
  }

  withEmail(email: string): this {
    this.data.email = email;
    return this;
  }

  async create(db: Database): Promise<User> {
    const user = {
      id: randomId(),
      name: this.data.name ?? randomName(),
      email: this.data.email ?? randomEmail(),
      createdAt: new Date(),
    };
    await db.query('INSERT INTO users (id, name, email, created_at) VALUES ($1, $2, $3, $4)', [
      user.id,
      user.name,
      user.email,
      user.createdAt,
    ]);
    return user;
  }
}

// Usage
test('finds user by email', async () => {
  const email = 'test@example.com';
  await new UserBuilder().withEmail(email).create(db);

  const user = await repo.findByEmail(email);

  expect(user?.email).toBe(email);
});
```

## Checklist

- [ ] Unit tests use fake repositories, not real database
- [ ] In-memory repository implements same interface as production
- [ ] Integration tests use test containers or dedicated test DB
- [ ] Each test creates its own isolated data
- [ ] Tests don't depend on pre-existing data
- [ ] Transactions used for automatic cleanup
- [ ] Random IDs used to prevent collisions
- [ ] Tests safe to run in parallel
- [ ] Test data builders handle DB insertion
