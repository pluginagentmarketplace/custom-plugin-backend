# Event-Driven Architecture & CQRS - Async Communication Patterns

## 📋 Table of Contents
- [Event-Driven Architecture](#event-driven-architecture)
- [Event Patterns](#event-patterns)
- [CQRS](#cqrs-command-query-responsibility-segregation)
- [Event Sourcing](#event-sourcing)
- [Message Queues](#message-queues)
- [Event Streaming](#event-streaming)
- [Eventual Consistency](#eventual-consistency)
- [Implementation Patterns](#implementation-patterns)
- [Best Practices](#best-practices)

---

## Event-Driven Architecture

### What is Event-Driven Architecture?

```
TRADITIONAL (Request-Response)     EVENT-DRIVEN (Publish-Subscribe)
┌─────────┐                        ┌─────────┐
│Service A│──────▶┌─────────┐      │Service A│────┐
└─────────┘       │Service B│      └─────────┘    │ publishes
                  └─────────┘                      ▼
    Direct coupling               ┌─────────────────────┐
    Synchronous                   │   Event Channel     │
    Tight dependency              │   (Message Bus)     │
                                  └─────────────────────┘
                                    │         │        │
                                    │         │        │ subscribes
                                    ▼         ▼        ▼
                                ┌────┐    ┌────┐  ┌────┐
                                │Svc1│    │Svc2│  │Svc3│
                                └────┘    └────┘  └────┘
                                  Loose coupling
                                  Asynchronous
                                  Independent
```

### Core Components

```typescript
// Event
interface DomainEvent {
  eventId: string;
  eventType: string;
  aggregateId: string;
  timestamp: Date;
  version: number;
  data: any;
  metadata?: {
    userId?: string;
    correlationId?: string;
    causationId?: string;
  };
}

// Example events
class OrderPlacedEvent implements DomainEvent {
  constructor(
    public eventId: string,
    public eventType: 'OrderPlaced',
    public aggregateId: string, // orderId
    public timestamp: Date,
    public version: number,
    public data: {
      userId: string;
      items: OrderItem[];
      total: number;
      shippingAddress: Address;
    },
    public metadata?: any
  ) {}
}

class PaymentProcessedEvent implements DomainEvent {
  constructor(
    public eventId: string,
    public eventType: 'PaymentProcessed',
    public aggregateId: string, // paymentId
    public timestamp: Date,
    public version: number,
    public data: {
      orderId: string;
      amount: number;
      paymentMethod: string;
      transactionId: string;
    }
  ) {}
}

// Event Producer
class OrderService {
  constructor(private eventBus: EventBus) {}

  async placeOrder(orderData: OrderData): Promise<Order> {
    // Create order
    const order = await this.orderRepository.save(orderData);

    // Publish event
    const event = new OrderPlacedEvent(
      uuidv4(),
      'OrderPlaced',
      order.id,
      new Date(),
      1,
      {
        userId: order.userId,
        items: order.items,
        total: order.total,
        shippingAddress: order.shippingAddress
      },
      {
        correlationId: uuidv4(),
        userId: order.userId
      }
    );

    await this.eventBus.publish(event);

    return order;
  }
}

// Event Consumer
class NotificationService {
  constructor(private eventBus: EventBus) {
    this.subscribeToEvents();
  }

  private subscribeToEvents() {
    this.eventBus.subscribe('OrderPlaced', this.handleOrderPlaced.bind(this));
    this.eventBus.subscribe('PaymentProcessed', this.handlePaymentProcessed.bind(this));
  }

  private async handleOrderPlaced(event: OrderPlacedEvent) {
    console.log(`Sending order confirmation for order ${event.aggregateId}`);

    await this.emailService.send({
      to: await this.getUserEmail(event.data.userId),
      subject: 'Order Confirmation',
      template: 'order-confirmation',
      data: {
        orderId: event.aggregateId,
        items: event.data.items,
        total: event.data.total
      }
    });
  }

  private async handlePaymentProcessed(event: PaymentProcessedEvent) {
    console.log(`Payment processed for order ${event.data.orderId}`);

    await this.smsService.send({
      to: await this.getUserPhone(event.data.orderId),
      message: `Payment of $${event.data.amount} received. Transaction ID: ${event.data.transactionId}`
    });
  }
}
```

---

## Event Patterns

### 1. Event Notification

Notify other systems that something happened.

```typescript
// Event contains minimal data
interface UserRegisteredEvent {
  eventType: 'UserRegistered';
  userId: string;
  timestamp: Date;
  // Minimal data - consumers fetch details if needed
}

// Publisher
class UserService {
  async registerUser(userData: UserData) {
    const user = await this.userRepository.save(userData);

    // Publish notification
    await this.eventBus.publish({
      eventType: 'UserRegistered',
      userId: user.id,
      timestamp: new Date()
    });

    return user;
  }
}

// Consumer fetches details if needed
class WelcomeEmailService {
  async onUserRegistered(event: UserRegisteredEvent) {
    // Fetch user details
    const user = await this.userClient.getUser(event.userId);

    await this.sendWelcomeEmail(user);
  }
}

// Pros: Loose coupling, small events
// Cons: Additional network calls
```

### 2. Event-Carried State Transfer

Event contains all data consumers need.

```typescript
// Event contains full data
interface UserRegisteredEvent {
  eventType: 'UserRegistered';
  userId: string;
  timestamp: Date;
  data: {
    name: string;
    email: string;
    phoneNumber: string;
    address: Address;
    preferences: UserPreferences;
  };
}

// Publisher
class UserService {
  async registerUser(userData: UserData) {
    const user = await this.userRepository.save(userData);

    // Publish with full data
    await this.eventBus.publish({
      eventType: 'UserRegistered',
      userId: user.id,
      timestamp: new Date(),
      data: {
        name: user.name,
        email: user.email,
        phoneNumber: user.phoneNumber,
        address: user.address,
        preferences: user.preferences
      }
    });

    return user;
  }
}

// Consumer has all data
class WelcomeEmailService {
  async onUserRegistered(event: UserRegisteredEvent) {
    // No need to fetch - all data in event
    await this.sendWelcomeEmail({
      to: event.data.email,
      name: event.data.name
    });
  }
}

// Consumer maintains local copy
class UserProfileService {
  async onUserRegistered(event: UserRegisteredEvent) {
    // Store local copy
    await this.localUserRepository.save({
      userId: event.userId,
      name: event.data.name,
      email: event.data.email,
      // ... other fields
    });
  }

  async getUserProfile(userId: string) {
    // Read from local copy - no network call!
    return await this.localUserRepository.findById(userId);
  }
}

// Pros: Consumers are autonomous, no additional calls
// Cons: Larger events, data duplication
```

### 3. Event Sourcing

Store all changes as sequence of events.

```typescript
// Events represent state changes
class AccountCreatedEvent {
  constructor(
    public accountId: string,
    public ownerId: string,
    public initialBalance: number,
    public timestamp: Date
  ) {}
}

class MoneyDepositedEvent {
  constructor(
    public accountId: string,
    public amount: number,
    public timestamp: Date
  ) {}
}

class MoneyWithdrawnEvent {
  constructor(
    public accountId: string,
    public amount: number,
    public timestamp: Date
  ) {}
}

// Aggregate rebuilds state from events
class Account {
  private id: string;
  private balance: number = 0;
  private isActive: boolean = false;
  private version: number = 0;

  // Load from events
  static fromEvents(events: DomainEvent[]): Account {
    const account = new Account();

    for (const event of events) {
      account.apply(event);
    }

    return account;
  }

  private apply(event: DomainEvent) {
    if (event instanceof AccountCreatedEvent) {
      this.id = event.accountId;
      this.balance = event.initialBalance;
      this.isActive = true;
    } else if (event instanceof MoneyDepositedEvent) {
      this.balance += event.amount;
    } else if (event instanceof MoneyWithdrawnEvent) {
      this.balance -= event.amount;
    }

    this.version++;
  }

  // Command methods create events
  deposit(amount: number): MoneyDepositedEvent {
    if (!this.isActive) {
      throw new Error('Account is not active');
    }

    if (amount <= 0) {
      throw new Error('Amount must be positive');
    }

    return new MoneyDepositedEvent(this.id, amount, new Date());
  }

  withdraw(amount: number): MoneyWithdrawnEvent {
    if (!this.isActive) {
      throw new Error('Account is not active');
    }

    if (amount <= 0) {
      throw new Error('Amount must be positive');
    }

    if (this.balance < amount) {
      throw new Error('Insufficient funds');
    }

    return new MoneyWithdrawnEvent(this.id, amount, new Date());
  }

  getBalance(): number {
    return this.balance;
  }
}

// Event store
class EventStore {
  private events: Map<string, DomainEvent[]> = new Map();

  async save(aggregateId: string, event: DomainEvent) {
    const events = this.events.get(aggregateId) || [];
    events.push(event);
    this.events.set(aggregateId, events);
  }

  async getEvents(aggregateId: string): Promise<DomainEvent[]> {
    return this.events.get(aggregateId) || [];
  }
}

// Repository
class AccountRepository {
  constructor(private eventStore: EventStore) {}

  async findById(accountId: string): Promise<Account> {
    const events = await this.eventStore.getEvents(accountId);
    return Account.fromEvents(events);
  }

  async save(account: Account, event: DomainEvent) {
    await this.eventStore.save(account.getId(), event);
  }
}

// Usage
const eventStore = new EventStore();
const repository = new AccountRepository(eventStore);

// Create account
const createEvent = new AccountCreatedEvent('acc-1', 'user-1', 1000, new Date());
await eventStore.save('acc-1', createEvent);

// Load account
let account = await repository.findById('acc-1');
console.log(account.getBalance()); // 1000

// Deposit
const depositEvent = account.deposit(500);
await repository.save(account, depositEvent);

// Reload
account = await repository.findById('acc-1');
console.log(account.getBalance()); // 1500

// Withdraw
const withdrawEvent = account.withdraw(200);
await repository.save(account, withdrawEvent);

// Reload
account = await repository.findById('acc-1');
console.log(account.getBalance()); // 1300

// Pros: Complete audit trail, temporal queries, event replay
// Cons: Complex, event versioning, need snapshots for performance
```

---

## CQRS (Command Query Responsibility Segregation)

### Concept

```
TRADITIONAL                         CQRS
┌────────────┐                     ┌─────────────┐
│            │                     │  Commands   │
│   Service  │                     │   (Write)   │
│            │                     └──────┬──────┘
│  Read/Write│                            │
│            │                            ▼
│  Database  │                     ┌─────────────┐
└────────────┘                     │ Write Model │
                                   │  (Domain)   │
Same model for                     └──────┬──────┘
read and write                            │ events
                                          ▼
                                   ┌─────────────┐
                                   │   Queries   │
                                   │   (Read)    │
                                   └──────┬──────┘
                                          │
                                          ▼
                                   ┌─────────────┐
                                   │  Read Model │
                                   │ (Denormal.) │
                                   └─────────────┘

                                   Separate models
                                   Optimized independently
```

### Implementation

```typescript
// Commands (write side)
interface Command {
  commandId: string;
  timestamp: Date;
  userId: string;
}

class CreateProductCommand implements Command {
  constructor(
    public commandId: string,
    public timestamp: Date,
    public userId: string,
    public productId: string,
    public name: string,
    public description: string,
    public price: number,
    public category: string
  ) {}
}

class UpdateProductPriceCommand implements Command {
  constructor(
    public commandId: string,
    public timestamp: Date,
    public userId: string,
    public productId: string,
    public newPrice: number
  ) {}
}

// Command handlers (write model)
class ProductCommandHandler {
  constructor(
    private repository: ProductRepository,
    private eventBus: EventBus
  ) {}

  async handle(command: CreateProductCommand) {
    // Validate
    if (command.price <= 0) {
      throw new Error('Price must be positive');
    }

    // Create product
    const product = new Product(
      command.productId,
      command.name,
      command.description,
      command.price,
      command.category
    );

    await this.repository.save(product);

    // Publish event
    await this.eventBus.publish(new ProductCreatedEvent(
      product.id,
      product.name,
      product.price,
      product.category,
      new Date()
    ));
  }

  async handleUpdatePrice(command: UpdateProductPriceCommand) {
    const product = await this.repository.findById(command.productId);

    const oldPrice = product.price;
    product.updatePrice(command.newPrice);

    await this.repository.save(product);

    await this.eventBus.publish(new ProductPriceUpdatedEvent(
      product.id,
      oldPrice,
      command.newPrice,
      new Date()
    ));
  }
}

// Queries (read side)
interface Query {
  queryId: string;
  userId?: string;
}

class GetProductQuery implements Query {
  constructor(
    public queryId: string,
    public productId: string,
    public userId?: string
  ) {}
}

class SearchProductsQuery implements Query {
  constructor(
    public queryId: string,
    public searchTerm: string,
    public category?: string,
    public minPrice?: number,
    public maxPrice?: number,
    public page: number = 1,
    public pageSize: number = 20,
    public userId?: string
  ) {}
}

// Read models (denormalized for queries)
interface ProductReadModel {
  id: string;
  name: string;
  description: string;
  price: number;
  category: string;
  categoryName: string; // denormalized
  brand: string;
  brandName: string; // denormalized
  averageRating: number; // computed
  reviewCount: number; // computed
  inStock: boolean;
  tags: string[];
  imageUrls: string[];
  createdAt: Date;
  updatedAt: Date;
}

interface ProductSearchModel {
  id: string;
  name: string;
  price: number;
  category: string;
  brand: string;
  rating: number;
  reviewCount: number;
  inStock: boolean;
  searchText: string; // for full-text search
}

// Query handlers (read model)
class ProductQueryHandler {
  constructor(
    private readRepository: ProductReadRepository,
    private searchIndex: ProductSearchIndex
  ) {}

  async handle(query: GetProductQuery): Promise<ProductReadModel> {
    // Read from optimized read model
    return await this.readRepository.findById(query.productId);
  }

  async handleSearch(query: SearchProductsQuery): Promise<{
    products: ProductSearchModel[];
    total: number;
    page: number;
    pageSize: number;
  }> {
    // Use specialized search index
    const result = await this.searchIndex.search({
      searchTerm: query.searchTerm,
      category: query.category,
      minPrice: query.minPrice,
      maxPrice: query.maxPrice,
      page: query.page,
      pageSize: query.pageSize
    });

    return result;
  }
}

// Event handlers update read models
class ProductReadModelUpdater {
  constructor(
    private readRepository: ProductReadRepository,
    private searchIndex: ProductSearchIndex,
    private eventBus: EventBus
  ) {
    this.subscribeToEvents();
  }

  private subscribeToEvents() {
    this.eventBus.subscribe('ProductCreated', this.onProductCreated.bind(this));
    this.eventBus.subscribe('ProductPriceUpdated', this.onPriceUpdated.bind(this));
  }

  private async onProductCreated(event: ProductCreatedEvent) {
    // Update read model
    await this.readRepository.insert({
      id: event.productId,
      name: event.name,
      price: event.price,
      category: event.category,
      categoryName: await this.getCategoryName(event.category),
      averageRating: 0,
      reviewCount: 0,
      inStock: true,
      tags: [],
      imageUrls: [],
      createdAt: event.timestamp,
      updatedAt: event.timestamp
    });

    // Update search index
    await this.searchIndex.index({
      id: event.productId,
      name: event.name,
      price: event.price,
      category: event.category,
      searchText: `${event.name} ${event.category}`.toLowerCase()
    });
  }

  private async onPriceUpdated(event: ProductPriceUpdatedEvent) {
    // Update read model
    await this.readRepository.updatePrice(
      event.productId,
      event.newPrice
    );

    // Update search index
    await this.searchIndex.updatePrice(
      event.productId,
      event.newPrice
    );
  }
}

// API layer
class ProductController {
  constructor(
    private commandHandler: ProductCommandHandler,
    private queryHandler: ProductQueryHandler
  ) {}

  // Command endpoint (write)
  async createProduct(req: Request, res: Response) {
    const command = new CreateProductCommand(
      uuidv4(),
      new Date(),
      req.user.id,
      uuidv4(),
      req.body.name,
      req.body.description,
      req.body.price,
      req.body.category
    );

    await this.commandHandler.handle(command);

    res.status(202).json({
      message: 'Product creation initiated',
      productId: command.productId
    });
  }

  // Query endpoint (read)
  async getProduct(req: Request, res: Response) {
    const query = new GetProductQuery(
      uuidv4(),
      req.params.id,
      req.user?.id
    );

    const product = await this.queryHandler.handle(query);

    res.json(product);
  }

  // Query endpoint (search)
  async searchProducts(req: Request, res: Response) {
    const query = new SearchProductsQuery(
      uuidv4(),
      req.query.q as string,
      req.query.category as string,
      req.query.minPrice ? parseFloat(req.query.minPrice as string) : undefined,
      req.query.maxPrice ? parseFloat(req.query.maxPrice as string) : undefined,
      parseInt(req.query.page as string) || 1,
      parseInt(req.query.pageSize as string) || 20,
      req.user?.id
    );

    const results = await this.queryHandler.handleSearch(query);

    res.json(results);
  }
}
```

**Benefits**:
- ✅ Optimized read and write models separately
- ✅ Scalability (scale reads independently of writes)
- ✅ Flexibility (different technologies for read/write)
- ✅ Better performance

**Challenges**:
- ❌ Eventual consistency
- ❌ Increased complexity
- ❌ Data synchronization

---

## Message Queues

### RabbitMQ Implementation

```typescript
import amqp, { Channel, Connection } from 'amqplib';

// Message queue configuration
interface QueueConfig {
  queueName: string;
  durable: boolean;
  exchange?: string;
  exchangeType?: 'direct' | 'topic' | 'fanout';
  routingKey?: string;
}

// Message broker
class RabbitMQBroker {
  private connection: Connection;
  private channel: Channel;

  async connect(url: string = 'amqp://localhost') {
    this.connection = await amqp.connect(url);
    this.channel = await this.connection.createChannel();
  }

  async createQueue(config: QueueConfig) {
    // Declare queue
    await this.channel.assertQueue(config.queueName, {
      durable: config.durable
    });

    // Declare exchange if specified
    if (config.exchange) {
      await this.channel.assertExchange(
        config.exchange,
        config.exchangeType || 'direct',
        { durable: true }
      );

      // Bind queue to exchange
      await this.channel.bindQueue(
        config.queueName,
        config.exchange,
        config.routingKey || ''
      );
    }
  }

  async publish(
    exchange: string,
    routingKey: string,
    message: any,
    options?: any
  ) {
    const content = Buffer.from(JSON.stringify(message));

    this.channel.publish(
      exchange,
      routingKey,
      content,
      {
        persistent: true,
        timestamp: Date.now(),
        ...options
      }
    );
  }

  async sendToQueue(queueName: string, message: any, options?: any) {
    const content = Buffer.from(JSON.stringify(message));

    this.channel.sendToQueue(
      queueName,
      content,
      {
        persistent: true,
        timestamp: Date.now(),
        ...options
      }
    );
  }

  async consume(
    queueName: string,
    handler: (message: any) => Promise<void>,
    options?: any
  ) {
    await this.channel.consume(
      queueName,
      async (msg) => {
        if (msg) {
          try {
            const content = JSON.parse(msg.content.toString());
            await handler(content);

            // Acknowledge message
            this.channel.ack(msg);
          } catch (error) {
            console.error('Error processing message:', error);

            // Reject and requeue
            this.channel.nack(msg, false, true);
          }
        }
      },
      options
    );
  }

  async close() {
    await this.channel.close();
    await this.connection.close();
  }
}

// Publisher
class OrderService {
  constructor(private broker: RabbitMQBroker) {}

  async placeOrder(orderData: OrderData) {
    const order = await this.orderRepository.save(orderData);

    // Publish to exchange
    await this.broker.publish(
      'orders',             // exchange
      'order.placed',       // routing key
      {
        eventType: 'OrderPlaced',
        orderId: order.id,
        userId: order.userId,
        items: order.items,
        total: order.total,
        timestamp: new Date()
      }
    );

    return order;
  }
}

// Consumer
class EmailNotificationService {
  constructor(private broker: RabbitMQBroker) {}

  async start() {
    // Create queue
    await this.broker.createQueue({
      queueName: 'email.notifications',
      durable: true,
      exchange: 'orders',
      exchangeType: 'topic',
      routingKey: 'order.*'
    });

    // Consume messages
    await this.broker.consume(
      'email.notifications',
      this.handleMessage.bind(this)
    );

    console.log('Email notification service started');
  }

  private async handleMessage(message: any) {
    if (message.eventType === 'OrderPlaced') {
      await this.sendOrderConfirmation(message);
    } else if (message.eventType === 'OrderShipped') {
      await this.sendShippingNotification(message);
    }
  }

  private async sendOrderConfirmation(event: any) {
    console.log(`Sending order confirmation for ${event.orderId}`);
    // Send email logic
  }
}

// Dead Letter Queue pattern
class OrderProcessingService {
  constructor(private broker: RabbitMQBroker) {}

  async start() {
    // Create dead letter exchange
    await this.broker.createQueue({
      queueName: 'orders.dlq',
      durable: true,
      exchange: 'orders.dlx',
      exchangeType: 'direct'
    });

    // Create main queue with DLQ
    await this.channel.assertQueue('orders.processing', {
      durable: true,
      deadLetterExchange: 'orders.dlx',
      deadLetterRoutingKey: 'dead-letter'
    });

    await this.broker.consume(
      'orders.processing',
      this.processOrder.bind(this),
      { prefetch: 1 } // Process one at a time
    );
  }

  private async processOrder(message: any) {
    try {
      // Process order with retries
      await this.processWithRetry(message);
    } catch (error) {
      console.error('Order processing failed:', error);
      throw error; // Will go to DLQ after retries
    }
  }

  private async processWithRetry(message: any, maxRetries = 3) {
    const retries = message.retryCount || 0;

    if (retries >= maxRetries) {
      throw new Error('Max retries exceeded');
    }

    try {
      // Processing logic
      await this.orderRepository.process(message.orderId);
    } catch (error) {
      // Increment retry count and re-queue
      message.retryCount = retries + 1;

      await this.broker.sendToQueue('orders.processing', message, {
        delay: Math.pow(2, retries) * 1000 // Exponential backoff
      });

      throw error;
    }
  }
}
```

---

## Best Practices

### 1. Event Design

```typescript
// Good event design
interface OrderPlacedEvent {
  // Event metadata
  eventId: string;           // Unique ID
  eventType: 'OrderPlaced';  // Type
  aggregateId: string;       // Order ID
  timestamp: Date;           // When it happened
  version: number;           // Event version

  // Event data
  data: {
    userId: string;
    items: OrderItem[];
    total: number;
    shippingAddress: Address;
  };

  // Tracing metadata
  metadata: {
    correlationId: string;   // Track related events
    causationId: string;     // What caused this event
    userId: string;          // Who initiated
  };
}

// Event naming conventions
// Past tense: OrderPlaced, PaymentProcessed, UserRegistered
// Not: PlaceOrder, ProcessPayment, RegisterUser
```

### 2. Idempotency

```typescript
// Idempotent event handler
class PaymentProcessor {
  private processedEvents: Set<string> = new Set();

  async handlePaymentRequested(event: PaymentRequestedEvent) {
    // Check if already processed
    if (this.processedEvents.has(event.eventId)) {
      console.log(`Event ${event.eventId} already processed, skipping`);
      return;
    }

    // Process payment
    const result = await this.processPayment(event.data);

    // Mark as processed
    this.processedEvents.add(event.eventId);

    // Or use database
    await this.eventRepository.markAsProcessed(event.eventId);
  }
}
```

### 3. Error Handling

```typescript
// Resilient event handler
class OrderProcessor {
  async handleEvent(event: DomainEvent) {
    try {
      await this.process(event);
    } catch (error) {
      if (error instanceof RetryableError) {
        // Retry with exponential backoff
        await this.retryWithBackoff(event, error);
      } else if (error instanceof PermanentError) {
        // Move to dead letter queue
        await this.moveToDeadLetterQueue(event, error);
      } else {
        // Unknown error - log and alert
        await this.logError(event, error);
        await this.alertOps(event, error);
      }
    }
  }

  private async retryWithBackoff(
    event: DomainEvent,
    error: Error,
    attempt = 1,
    maxAttempts = 5
  ) {
    if (attempt > maxAttempts) {
      await this.moveToDeadLetterQueue(event, error);
      return;
    }

    const delay = Math.pow(2, attempt) * 1000; // Exponential backoff
    await new Promise(resolve => setTimeout(resolve, delay));

    try {
      await this.process(event);
    } catch (retryError) {
      await this.retryWithBackoff(event, retryError, attempt + 1);
    }
  }
}
```

---

## Summary

Event-Driven Architecture provides:
- **Loose Coupling**: Services communicate through events
- **Scalability**: Async processing, independent scaling
- **Resilience**: Failure isolation
- **Flexibility**: Easy to add new consumers

**CQRS Benefits**:
- Optimized read and write models
- Independent scaling
- Better performance

**Challenges**:
- Eventual consistency
- Debugging complexity
- Event versioning

**Duration**: 50 hours
**Completion**: All architecture pattern skills completed!
