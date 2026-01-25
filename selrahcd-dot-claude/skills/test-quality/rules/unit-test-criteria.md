# Unit Test Criteria

A test is a **unit test** if it meets these criteria (based on Michael Feathers' definition).

## The Criteria

A unit test:

1. **Runs fast** - Milliseconds, not seconds
2. **Doesn't talk to database** - No real DB connections
3. **Doesn't communicate across network** - No HTTP, WebSocket, etc.
4. **Doesn't touch file system** - No reading/writing files
5. **Doesn't require special environment setup** - No env vars, config files
6. **Can run concurrently** - No shared state between tests

Tests that violate these are **integration tests** - still valuable, but serve a different purpose.

## Fast Execution

Unit tests should run in milliseconds. If a test is slow, it's probably not a unit test.

```typescript
// ❌ Slow: Real delay
test('retries after timeout', async () => {
  await service.callWithRetry(); // Waits for actual timeout
}, 30000);

// ✅ Fast: Controlled time via injected clock or explicit duration
test('retries after timeout duration', async () => {
  const clock = new ControllableClock();
  const service = new RetryService(clock);

  const promise = service.callWithRetry();
  clock.advance(5000);

  await expect(promise).resolves.toBeDefined();
});
```

## No Database

Unit tests don't connect to real databases. See [database.md](./database.md) for testing with databases.

```typescript
// ❌ Integration test: Real database
test('saves user to database', async () => {
  const db = await connectToDatabase();
  await userRepository.save(user);
  const saved = await db.query('SELECT * FROM users WHERE id = ?', [user.id]);
  expect(saved).toBeDefined();
});

// ✅ Unit test: In-memory fake repository
test('saves user to repository', async () => {
  const repository = new InMemoryUserRepository();
  const service = new UserService(repository);

  await service.createUser({ name: 'Alice', email: 'alice@example.com' });

  const saved = await repository.findByEmail('alice@example.com');
  expect(saved?.name).toBe('Alice');
});
```

## No Network

Unit tests don't make real network calls.

```typescript
// ❌ Integration test: Real HTTP
test('fetches weather data', async () => {
  const weather = await weatherService.getCurrent('Paris');
  expect(weather.temperature).toBeDefined();
});

// ✅ Unit test: Stub HTTP client
test('parses weather API response', async () => {
  const httpClient = new StubHttpClient();
  httpClient.givenResponse('/weather/Paris', {
    temp: 22,
    conditions: 'sunny',
  });
  const service = new WeatherService(httpClient);

  const weather = await service.getCurrent('Paris');

  expect(weather.temperature).toBe(22);
  expect(weather.conditions).toBe('sunny');
});
```

## No File System

Unit tests don't read or write files.

```typescript
// ❌ Integration test: Real file system
test('reads config file', () => {
  const config = loadConfig('./config.json');
  expect(config.apiKey).toBeDefined();
});

// ✅ Unit test: Stub file reader
test('parses config from JSON content', () => {
  const fileReader = new StubFileReader();
  fileReader.givenContent('./config.json', '{"apiKey": "secret123"}');
  const configLoader = new ConfigLoader(fileReader);

  const config = configLoader.load('./config.json');

  expect(config.apiKey).toBe('secret123');
});
```

## No Special Environment

Unit tests work without environment variables or external config.

```typescript
// ❌ Environment-dependent
test('uses API key from environment', () => {
  const service = createService(); // Reads process.env.API_KEY
  expect(service.apiKey).toBeDefined();
});

// ✅ Explicit dependencies
test('service uses provided API key', () => {
  const apiKey = 'test-key-123';
  const service = createService({ apiKey });

  expect(service.apiKey).toBe(apiKey);
});
```

## Concurrent Execution

Unit tests can run in parallel without interference.

```typescript
// ❌ Shared mutable state - can't run concurrently
let globalCounter = 0;

test('increments counter', () => {
  globalCounter++;
  expect(globalCounter).toBe(1);
});

test('counter is at expected value', () => {
  expect(globalCounter).toBe(1); // Fails if tests run in different order
});

// ✅ Isolated state - safe for parallel execution
test('counter starts at zero', () => {
  const counter = createCounter();

  expect(counter.value).toBe(0);
});

test('increment increases counter', () => {
  const counter = createCounter();

  counter.increment();

  expect(counter.value).toBe(1);
});
```

## Checklist

- [ ] Test runs in milliseconds
- [ ] No database connections
- [ ] No HTTP/network calls
- [ ] No file system access
- [ ] No environment variable dependencies
- [ ] No shared mutable state
- [ ] Can run in parallel with other tests
- [ ] Can run in isolation
