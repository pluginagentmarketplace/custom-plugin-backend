# Microservices Architecture - Building Scalable Distributed Systems

## 📋 Table of Contents
- [Introduction](#introduction)
- [Core Principles](#core-principles)
- [Service Decomposition](#service-decomposition)
- [Communication Patterns](#communication-patterns)
- [Data Management](#data-management)
- [Service Discovery](#service-discovery)
- [API Gateway](#api-gateway)
- [Deployment Patterns](#deployment-patterns)
- [Observability](#observability)
- [Resilience Patterns](#resilience-patterns)
- [Service Mesh](#service-mesh)

---

## Introduction

### What are Microservices?

> "Microservices are small, autonomous services that work together."
> — Sam Newman

```
MONOLITH                    MICROSERVICES
┌─────────────────┐         ┌────┐ ┌────┐ ┌────┐
│                 │         │Svc1│ │Svc2│ │Svc3│
│   All Features  │   →     ├────┤ ├────┤ ├────┤
│                 │         │DB1 │ │DB2 │ │DB3 │
│   Database      │         └────┘ └────┘ └────┘
└─────────────────┘
```

### Characteristics

```
┌─────────────────────────────────────────────┐
│      Microservices Characteristics          │
├─────────────────────────────────────────────┤
│ ✓ Componentization via services             │
│ ✓ Organized around business capabilities    │
│ ✓ Products not projects                     │
│ ✓ Smart endpoints, dumb pipes               │
│ ✓ Decentralized governance                  │
│ ✓ Decentralized data management             │
│ ✓ Infrastructure automation                 │
│ ✓ Design for failure                        │
│ ✓ Evolutionary design                       │
└─────────────────────────────────────────────┘
```

---

## Core Principles

### 1. Single Responsibility

Each microservice should focus on doing one thing well.

```
┌──────────────────────────────────────────┐
│         Service Boundaries               │
├──────────────────────────────────────────┤
│                                          │
│  ┌────────────┐  ┌──────────────┐      │
│  │   User     │  │   Product    │      │
│  │  Service   │  │   Service    │      │
│  ├────────────┤  ├──────────────┤      │
│  │ - Auth     │  │ - Catalog    │      │
│  │ - Profile  │  │ - Inventory  │      │
│  │ - Prefs    │  │ - Pricing    │      │
│  └────────────┘  └──────────────┘      │
│                                          │
│  ┌────────────┐  ┌──────────────┐      │
│  │   Order    │  │   Payment    │      │
│  │  Service   │  │   Service    │      │
│  ├────────────┤  ├──────────────┤      │
│  │ - Cart     │  │ - Process    │      │
│  │ - Checkout │  │ - Refund     │      │
│  │ - History  │  │ - Validate   │      │
│  └────────────┘  └──────────────┘      │
└──────────────────────────────────────────┘
```

### 2. Autonomy

Services are independently deployable and scalable.

```typescript
// Each service is autonomous
class UserService {
  // Own database
  private userRepository: UserRepository;

  // Own business logic
  async createUser(userData: UserData) {
    const user = await this.userRepository.save(userData);
    // Publish event - async communication
    await this.eventBus.publish('user.created', user);
    return user;
  }
}

class OrderService {
  // Listens to user events but remains autonomous
  async onUserCreated(event: UserCreatedEvent) {
    // Initialize order-related data for new user
    await this.orderRepository.createUserProfile(event.userId);
  }

  async createOrder(orderData: OrderData) {
    // Independent operation
    const order = await this.orderRepository.save(orderData);
    return order;
  }
}
```

### 3. Decentralization

```
CENTRALIZED (Monolith)       DECENTRALIZED (Microservices)
┌────────────────┐           ┌────┐  ┌────┐  ┌────┐
│  Single DB     │           │DB1 │  │DB2 │  │DB3 │
│  Single Lang   │     →     │JS  │  │Go  │  │Java│
│  Single Team   │           │T1  │  │T2  │  │T3  │
└────────────────┘           └────┘  └────┘  └────┘
```

---

## Service Decomposition

### Decomposition Strategies

#### 1. By Business Capability

```
E-COMMERCE BUSINESS CAPABILITIES
┌─────────────────────────────────────────┐
│                                         │
│  ┌──────────────┐  ┌─────────────┐     │
│  │   Customer   │  │   Product   │     │
│  │  Management  │  │  Catalog    │     │
│  └──────────────┘  └─────────────┘     │
│                                         │
│  ┌──────────────┐  ┌─────────────┐     │
│  │    Order     │  │   Payment   │     │
│  │  Processing  │  │  Processing │     │
│  └──────────────┘  └─────────────┘     │
│                                         │
│  ┌──────────────┐  ┌─────────────┐     │
│  │   Shipping   │  │ Notification│     │
│  │  Management  │  │   Service   │     │
│  └──────────────┘  └─────────────┘     │
└─────────────────────────────────────────┘
```

#### 2. By Subdomain (DDD)

```typescript
// Core Domain: Order Management
class OrderService {
  async placeOrder(order: Order): Promise<OrderResult> {
    // Core business logic
    const validatedOrder = await this.validateOrder(order);
    const reservedInventory = await this.inventoryClient.reserve(
      validatedOrder.items
    );
    const paymentResult = await this.paymentClient.process(
      validatedOrder.total
    );

    if (paymentResult.success) {
      const placedOrder = await this.orderRepository.save(validatedOrder);
      await this.eventBus.publish('order.placed', placedOrder);
      return { success: true, orderId: placedOrder.id };
    }

    await this.inventoryClient.release(reservedInventory);
    return { success: false, error: 'Payment failed' };
  }
}

// Supporting Domain: Notification
class NotificationService {
  async onOrderPlaced(event: OrderPlacedEvent) {
    await this.sendOrderConfirmation(event.userId, event.orderId);
  }

  private async sendOrderConfirmation(userId: string, orderId: string) {
    const user = await this.userClient.getUser(userId);
    await this.emailService.send({
      to: user.email,
      subject: 'Order Confirmation',
      template: 'order-confirmation',
      data: { orderId }
    });
  }
}

// Generic Domain: Authentication (use off-the-shelf)
// Could use Auth0, Keycloak, etc.
```

#### 3. By Technical Capability

```
┌─────────────────────────────────────────┐
│           API Gateway                   │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────┐  ┌─────────────┐     │
│  │   BFF Web    │  │  BFF Mobile │     │
│  │   Service    │  │   Service   │     │
│  └──────────────┘  └─────────────┘     │
│                                         │
│  ┌──────────────────────────────┐      │
│  │     Business Services        │      │
│  └──────────────────────────────┘      │
│                                         │
│  ┌──────────────┐  ┌─────────────┐     │
│  │    Cache     │  │   Search    │     │
│  │   Service    │  │   Service   │     │
│  └──────────────┘  └─────────────┘     │
└─────────────────────────────────────────┘
```

### Service Size Guidelines

```
TOO LARGE                    JUST RIGHT               TOO SMALL
┌────────────────┐          ┌──────────┐            ┌───┐ ┌───┐
│                │          │          │            │ 1 │ │ 2 │
│   Monolith     │    →     │ Service  │      ✗     ├───┤ ├───┤
│                │          │          │            │ 3 │ │ 4 │
└────────────────┘          └──────────┘            ├───┤ ├───┤
                                                    │...│ │100│
"Distributed                 "Just right             └───┘ └───┘
 Monolith"                    team size"            "Nano-services"
```

**Guidelines**:
- Team can maintain 3-5 services
- Service fits in developer's head
- Can be rewritten in 2 weeks
- Has single, clear purpose
- Independent deployment

---

## Communication Patterns

### 1. Synchronous - REST

```typescript
// User Service REST API
import express from 'express';

const app = express();

interface User {
  id: string;
  name: string;
  email: string;
}

// GET /api/users/:id
app.get('/api/users/:id', async (req, res) => {
  try {
    const user = await userRepository.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        error: 'User not found'
      });
    }

    res.json(user);
  } catch (error) {
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

// POST /api/users
app.post('/api/users', async (req, res) => {
  try {
    const userData = req.body;
    const user = await userRepository.create(userData);

    res.status(201).json(user);
  } catch (error) {
    res.status(400).json({
      error: error.message
    });
  }
});

// Order Service calling User Service
class OrderService {
  constructor(private httpClient: HttpClient) {}

  async createOrder(orderData: OrderData) {
    // Synchronous call to User Service
    const user = await this.httpClient.get(
      `http://user-service/api/users/${orderData.userId}`
    );

    if (!user) {
      throw new Error('User not found');
    }

    // Create order
    const order = await this.orderRepository.save({
      ...orderData,
      userName: user.name,
      userEmail: user.email
    });

    return order;
  }
}

// Pros: Simple, request-response, easy to understand
// Cons: Tight coupling, synchronous, cascading failures
```

### 2. Synchronous - gRPC

```protobuf
// user.proto
syntax = "proto3";

service UserService {
  rpc GetUser (GetUserRequest) returns (User);
  rpc CreateUser (CreateUserRequest) returns (User);
  rpc ListUsers (ListUsersRequest) returns (ListUsersResponse);
}

message User {
  string id = 1;
  string name = 2;
  string email = 3;
  int32 age = 4;
}

message GetUserRequest {
  string id = 1;
}

message CreateUserRequest {
  string name = 1;
  string email = 2;
  int32 age = 3;
}

message ListUsersRequest {
  int32 page = 1;
  int32 page_size = 2;
}

message ListUsersResponse {
  repeated User users = 1;
  int32 total = 2;
}
```

```typescript
// Server implementation
import * as grpc from '@grpc/grpc-js';
import * as protoLoader from '@grpc/proto-loader';

const packageDefinition = protoLoader.loadSync('user.proto');
const userProto = grpc.loadPackageDefinition(packageDefinition);

class UserServiceImpl {
  async getUser(call: any, callback: any) {
    const userId = call.request.id;

    try {
      const user = await userRepository.findById(userId);
      callback(null, user);
    } catch (error) {
      callback({
        code: grpc.status.NOT_FOUND,
        message: 'User not found'
      });
    }
  }

  async createUser(call: any, callback: any) {
    try {
      const userData = call.request;
      const user = await userRepository.create(userData);
      callback(null, user);
    } catch (error) {
      callback({
        code: grpc.status.INVALID_ARGUMENT,
        message: error.message
      });
    }
  }
}

// Start server
const server = new grpc.Server();
server.addService(userProto.UserService.service, new UserServiceImpl());
server.bindAsync(
  '0.0.0.0:50051',
  grpc.ServerCredentials.createInsecure(),
  () => {
    server.start();
    console.log('gRPC server running on port 50051');
  }
);

// Client
class OrderService {
  private userClient: any;

  constructor() {
    this.userClient = new userProto.UserService(
      'user-service:50051',
      grpc.credentials.createInsecure()
    );
  }

  async createOrder(orderData: OrderData) {
    return new Promise((resolve, reject) => {
      this.userClient.getUser(
        { id: orderData.userId },
        (error: any, user: User) => {
          if (error) {
            reject(error);
          } else {
            // Create order with user data
            resolve(this.orderRepository.save({
              ...orderData,
              userName: user.name
            }));
          }
        }
      );
    });
  }
}

// Pros: Fast, type-safe, streaming support
// Cons: More complex, less human-readable
```

### 3. Asynchronous - Message Queue

```typescript
// Event-driven with RabbitMQ
import amqp from 'amqplib';

// Publisher (Order Service)
class OrderService {
  private channel: amqp.Channel;

  async publishOrderPlaced(order: Order) {
    const event = {
      eventType: 'order.placed',
      timestamp: new Date(),
      data: {
        orderId: order.id,
        userId: order.userId,
        total: order.total,
        items: order.items
      }
    };

    this.channel.publish(
      'orders',              // exchange
      'order.placed',        // routing key
      Buffer.from(JSON.stringify(event))
    );

    console.log('Published order.placed event');
  }
}

// Consumer (Notification Service)
class NotificationService {
  async subscribeToOrderEvents() {
    const connection = await amqp.connect('amqp://localhost');
    const channel = await connection.createChannel();

    await channel.assertExchange('orders', 'topic', { durable: true });
    await channel.assertQueue('notifications.orders', { durable: true });
    await channel.bindQueue('notifications.orders', 'orders', 'order.*');

    channel.consume('notifications.orders', async (msg) => {
      if (msg) {
        const event = JSON.parse(msg.content.toString());

        if (event.eventType === 'order.placed') {
          await this.handleOrderPlaced(event.data);
        }

        channel.ack(msg);
      }
    });
  }

  async handleOrderPlaced(data: any) {
    console.log(`Sending order confirmation for order ${data.orderId}`);
    await this.emailService.send({
      to: data.userEmail,
      subject: 'Order Confirmation',
      body: `Your order ${data.orderId} has been placed!`
    });
  }
}

// Consumer (Inventory Service)
class InventoryService {
  async subscribeToOrderEvents() {
    const connection = await amqp.connect('amqp://localhost');
    const channel = await connection.createChannel();

    await channel.assertExchange('orders', 'topic', { durable: true });
    await channel.assertQueue('inventory.orders', { durable: true });
    await channel.bindQueue('inventory.orders', 'orders', 'order.placed');

    channel.consume('inventory.orders', async (msg) => {
      if (msg) {
        const event = JSON.parse(msg.content.toString());
        await this.handleOrderPlaced(event.data);
        channel.ack(msg);
      }
    });
  }

  async handleOrderPlaced(data: any) {
    console.log(`Updating inventory for order ${data.orderId}`);

    for (const item of data.items) {
      await this.inventoryRepository.decreaseStock(
        item.productId,
        item.quantity
      );
    }
  }
}

// Pros: Loose coupling, async, resilient
// Cons: Eventual consistency, complexity, debugging harder
```

### 4. Event Streaming - Apache Kafka

```typescript
import { Kafka } from 'kafkajs';

const kafka = new Kafka({
  clientId: 'order-service',
  brokers: ['kafka:9092']
});

// Producer
class OrderService {
  private producer = kafka.producer();

  async init() {
    await this.producer.connect();
  }

  async placeOrder(orderData: OrderData) {
    const order = await this.orderRepository.save(orderData);

    // Publish event to Kafka
    await this.producer.send({
      topic: 'orders',
      messages: [{
        key: order.id,
        value: JSON.stringify({
          eventType: 'OrderPlaced',
          orderId: order.id,
          userId: order.userId,
          total: order.total,
          timestamp: new Date()
        })
      }]
    });

    return order;
  }
}

// Consumer
class AnalyticsService {
  private consumer = kafka.consumer({ groupId: 'analytics-group' });

  async start() {
    await this.consumer.connect();
    await this.consumer.subscribe({ topic: 'orders', fromBeginning: true });

    await this.consumer.run({
      eachMessage: async ({ topic, partition, message }) => {
        const event = JSON.parse(message.value.toString());

        if (event.eventType === 'OrderPlaced') {
          await this.updateAnalytics(event);
        }
      }
    });
  }

  async updateAnalytics(event: any) {
    // Update analytics dashboard
    await this.analyticsRepository.incrementOrderCount();
    await this.analyticsRepository.addRevenue(event.total);
  }
}

// Pros: High throughput, event replay, durability
// Cons: Operational complexity, eventual consistency
```

---

## Data Management

### 1. Database per Service

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   User       │  │   Order      │  │   Product    │
│  Service     │  │  Service     │  │   Service    │
├──────────────┤  ├──────────────┤  ├──────────────┤
│   Users DB   │  │  Orders DB   │  │ Products DB  │
│  (Postgres)  │  │  (MongoDB)   │  │ (Postgres)   │
└──────────────┘  └──────────────┘  └──────────────┘

Each service owns its data
Can choose optimal database type
```

**Implementation**:

```typescript
// User Service - owns users table
class UserService {
  constructor(private userDb: PostgresDatabase) {}

  async getUser(id: string): Promise<User> {
    // Only User Service can access users table
    return await this.userDb.query(
      'SELECT * FROM users WHERE id = $1',
      [id]
    );
  }
}

// Order Service - owns orders table
class OrderService {
  constructor(
    private orderDb: MongoDatabase,
    private userServiceClient: HttpClient
  ) {}

  async getOrder(id: string) {
    // Order Service accesses its own database
    const order = await this.orderDb.collection('orders')
      .findOne({ _id: id });

    // Gets user data via User Service API (not direct DB access!)
    const user = await this.userServiceClient.get(
      `/users/${order.userId}`
    );

    return {
      ...order,
      user
    };
  }
}
```

**Benefits**:
- ✅ Loose coupling
- ✅ Can choose optimal database per service
- ✅ Independent scaling
- ✅ Failure isolation

**Challenges**:
- ❌ No ACID transactions across services
- ❌ Queries across services complex
- ❌ Data consistency challenges

### 2. Saga Pattern

For distributed transactions:

```typescript
// Choreography-based Saga
class OrderService {
  async createOrder(orderData: OrderData) {
    // 1. Create order in pending state
    const order = await this.orderRepository.save({
      ...orderData,
      status: 'PENDING'
    });

    // 2. Publish event
    await this.eventBus.publish('order.created', {
      orderId: order.id,
      userId: orderData.userId,
      items: orderData.items,
      total: orderData.total
    });

    return order;
  }

  async onPaymentSucceeded(event: PaymentSucceededEvent) {
    // 3. Update order status
    await this.orderRepository.updateStatus(
      event.orderId,
      'CONFIRMED'
    );

    // 4. Publish next event
    await this.eventBus.publish('order.confirmed', {
      orderId: event.orderId
    });
  }

  async onPaymentFailed(event: PaymentFailedEvent) {
    // Compensating transaction
    await this.orderRepository.updateStatus(
      event.orderId,
      'CANCELLED'
    );
  }
}

class PaymentService {
  async onOrderCreated(event: OrderCreatedEvent) {
    try {
      // Attempt payment
      const paymentResult = await this.processPayment(
        event.userId,
        event.total
      );

      if (paymentResult.success) {
        await this.eventBus.publish('payment.succeeded', {
          orderId: event.orderId,
          transactionId: paymentResult.transactionId
        });
      } else {
        await this.eventBus.publish('payment.failed', {
          orderId: event.orderId,
          reason: paymentResult.error
        });
      }
    } catch (error) {
      await this.eventBus.publish('payment.failed', {
        orderId: event.orderId,
        reason: error.message
      });
    }
  }
}

class InventoryService {
  async onOrderConfirmed(event: OrderConfirmedEvent) {
    // Reserve inventory
    await this.reserveItems(event.items);

    await this.eventBus.publish('inventory.reserved', {
      orderId: event.orderId
    });
  }

  async onOrderCancelled(event: OrderCancelledEvent) {
    // Compensating transaction - release inventory
    await this.releaseItems(event.items);
  }
}

// Orchestration-based Saga
class OrderSagaOrchestrator {
  async executeOrderSaga(orderData: OrderData) {
    const saga = new SagaInstance();

    try {
      // Step 1: Create order
      const order = await this.orderService.createOrder(orderData);
      saga.addCompensation(() => this.orderService.cancelOrder(order.id));

      // Step 2: Process payment
      const payment = await this.paymentService.processPayment(
        orderData.userId,
        orderData.total
      );
      saga.addCompensation(() => this.paymentService.refund(payment.id));

      // Step 3: Reserve inventory
      await this.inventoryService.reserveItems(orderData.items);
      saga.addCompensation(() => this.inventoryService.releaseItems(orderData.items));

      // Step 4: Confirm order
      await this.orderService.confirmOrder(order.id);

      return { success: true, orderId: order.id };
    } catch (error) {
      // Execute compensating transactions in reverse order
      await saga.compensate();
      return { success: false, error: error.message };
    }
  }
}

class SagaInstance {
  private compensations: (() => Promise<void>)[] = [];

  addCompensation(compensation: () => Promise<void>) {
    this.compensations.push(compensation);
  }

  async compensate() {
    // Execute in reverse order
    for (const compensation of this.compensations.reverse()) {
      try {
        await compensation();
      } catch (error) {
        console.error('Compensation failed:', error);
      }
    }
  }
}
```

### 3. CQRS Pattern

```typescript
// Command side - writes
class ProductCommandService {
  async createProduct(command: CreateProductCommand) {
    const product = new Product(
      command.id,
      command.name,
      command.price
    );

    await this.productRepository.save(product);

    // Publish event
    await this.eventBus.publish('product.created', product);
  }

  async updatePrice(command: UpdatePriceCommand) {
    const product = await this.productRepository.findById(command.id);
    product.updatePrice(command.newPrice);

    await this.productRepository.save(product);
    await this.eventBus.publish('product.price_updated', {
      productId: product.id,
      oldPrice: command.oldPrice,
      newPrice: command.newPrice
    });
  }
}

// Query side - reads
class ProductQueryService {
  async onProductCreated(event: ProductCreatedEvent) {
    // Update read model
    await this.productReadRepository.insert({
      id: event.id,
      name: event.name,
      price: event.price,
      category: event.category,
      inStock: true,
      rating: 0,
      reviewCount: 0
    });

    // Update denormalized search index
    await this.searchIndex.index({
      id: event.id,
      name: event.name,
      price: event.price,
      category: event.category
    });
  }

  async getProduct(id: string) {
    // Read from optimized read model
    return await this.productReadRepository.findById(id);
  }

  async searchProducts(query: SearchQuery) {
    // Use specialized search index
    return await this.searchIndex.search(query);
  }
}
```

---

## Service Discovery

### Client-Side Discovery

```typescript
// Service Registry (Consul, Eureka)
interface ServiceRegistry {
  register(service: ServiceInfo): Promise<void>;
  deregister(serviceId: string): Promise<void>;
  getInstances(serviceName: string): Promise<ServiceInstance[]>;
  healthCheck(serviceId: string): Promise<boolean>;
}

class ConsulServiceRegistry implements ServiceRegistry {
  async register(service: ServiceInfo) {
    await this.consulClient.agent.service.register({
      id: service.id,
      name: service.name,
      address: service.address,
      port: service.port,
      check: {
        http: `http://${service.address}:${service.port}/health`,
        interval: '10s'
      }
    });
  }

  async getInstances(serviceName: string): Promise<ServiceInstance[]> {
    const services = await this.consulClient.health.service({
      service: serviceName,
      passing: true
    });

    return services.map(s => ({
      id: s.Service.ID,
      address: s.Service.Address,
      port: s.Service.Port
    }));
  }
}

// Service registration on startup
class UserService {
  async start() {
    const port = process.env.PORT || 3000;
    const serviceInfo = {
      id: `user-service-${process.env.HOSTNAME}`,
      name: 'user-service',
      address: process.env.HOST || 'localhost',
      port: parseInt(port)
    };

    await this.serviceRegistry.register(serviceInfo);

    // Health check endpoint
    this.app.get('/health', (req, res) => {
      res.json({ status: 'healthy' });
    });

    this.app.listen(port);
  }
}

// Client with load balancing
class OrderService {
  async callUserService(userId: string) {
    // Discover instances
    const instances = await this.serviceRegistry.getInstances('user-service');

    if (instances.length === 0) {
      throw new Error('No user-service instances available');
    }

    // Load balance (round-robin)
    const instance = instances[this.currentIndex % instances.length];
    this.currentIndex++;

    // Make request
    const response = await this.httpClient.get(
      `http://${instance.address}:${instance.port}/users/${userId}`
    );

    return response.data;
  }
}
```

### Server-Side Discovery

```
┌─────────┐      ┌────────────┐      ┌──────────┐
│ Client  │─────▶│Load Balancer│─────▶│Service A1│
└─────────┘      │(Nginx/ELB) │      ├──────────┤
                 │            │─────▶│Service A2│
                 │            │      ├──────────┤
                 │  Queries   │─────▶│Service A3│
                 │  Registry  │      └──────────┘
                 └─────┬──────┘
                       │
                       ▼
                 ┌──────────┐
                 │ Registry │
                 │(Consul)  │
                 └──────────┘
```

---

## API Gateway

```typescript
// API Gateway with Express
import express from 'express';
import { createProxyMiddleware } from 'http-proxy-middleware';

const app = express();

// Authentication middleware
app.use(async (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    const decoded = await this.jwtService.verify(token);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

// Rate limiting
const rateLimit = require('express-rate-limit');
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Routing to services
app.use('/api/users', createProxyMiddleware({
  target: 'http://user-service:3001',
  changeOrigin: true,
  pathRewrite: {
    '^/api/users': '/users'
  }
}));

app.use('/api/orders', createProxyMiddleware({
  target: 'http://order-service:3002',
  changeOrigin: true,
  pathRewrite: {
    '^/api/orders': '/orders'
  }
}));

app.use('/api/products', createProxyMiddleware({
  target: 'http://product-service:3003',
  changeOrigin: true
}));

// Request aggregation
app.get('/api/dashboard', async (req, res) => {
  const userId = req.user.id;

  // Parallel requests to multiple services
  const [user, orders, recommendations] = await Promise.all([
    this.httpClient.get(`http://user-service/users/${userId}`),
    this.httpClient.get(`http://order-service/orders?userId=${userId}`),
    this.httpClient.get(`http://recommendation-service/recommendations/${userId}`)
  ]);

  res.json({
    user: user.data,
    recentOrders: orders.data.slice(0, 5),
    recommendations: recommendations.data
  });
});

app.listen(8080, () => {
  console.log('API Gateway listening on port 8080');
});
```

---

## Summary

Microservices architecture provides:
- **Scalability**: Independent scaling of services
- **Flexibility**: Technology diversity
- **Resilience**: Fault isolation
- **Speed**: Independent deployment

**Challenges**:
- Distributed system complexity
- Data consistency
- Network latency
- Operational overhead

**Duration**: 50 hours
**Next**: Proceed to `event-driven-cqrs.md`
