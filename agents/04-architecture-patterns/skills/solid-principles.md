# SOLID Principles - The Foundation of Clean Architecture

## 📋 Table of Contents
- [Introduction](#introduction)
- [Single Responsibility Principle (SRP)](#single-responsibility-principle-srp)
- [Open/Closed Principle (OCP)](#openclosed-principle-ocp)
- [Liskov Substitution Principle (LSP)](#liskov-substitution-principle-lsp)
- [Interface Segregation Principle (ISP)](#interface-segregation-principle-isp)
- [Dependency Inversion Principle (DIP)](#dependency-inversion-principle-dip)
- [SOLID in Practice](#solid-in-practice)
- [Common Violations](#common-violations)
- [Exercises](#exercises)

---

## Introduction

### What is SOLID?

SOLID is an acronym for five design principles that make software designs more understandable, flexible, and maintainable. These principles were introduced by Robert C. Martin (Uncle Bob).

```
 _____ _____ __    _____ ____
|   __|     |  |  |     |    \
|__   |  |  |  |__|  |  |  |  |
|_____|_____|_____|_____|____/

S - Single Responsibility Principle
O - Open/Closed Principle
L - Liskov Substitution Principle
I - Interface Segregation Principle
D - Dependency Inversion Principle
```

### Why SOLID Matters

```
WITHOUT SOLID          →          WITH SOLID
┌──────────────┐                 ┌──────────────┐
│  Rigid       │                 │  Flexible    │
│  Fragile     │       →         │  Robust      │
│  Immobile    │                 │  Reusable    │
│  Complex     │                 │  Simple      │
└──────────────┘                 └──────────────┘
```

---

## Single Responsibility Principle (SRP)

### Definition
> "A class should have only one reason to change."
> — Robert C. Martin

A class should have only one job or responsibility. If a class has more than one responsibility, it becomes coupled. A change to one responsibility results in modification of another responsibility.

### Why It Matters
```
┌─────────────────────────────────────────┐
│         Single Responsibility           │
├─────────────────────────────────────────┤
│ ✓ Easier to understand                  │
│ ✓ Easier to test                        │
│ ✓ Lower coupling                        │
│ ✓ Better organization                   │
│ ✓ Reduced risk of bugs                  │
└─────────────────────────────────────────┘
```

### ❌ Bad Example - Violating SRP

```javascript
// BAD: UserManager has too many responsibilities
class UserManager {
  constructor() {
    this.db = new Database();
    this.emailService = new EmailService();
    this.logger = new Logger();
  }

  // Responsibility 1: User validation
  validateUser(user) {
    if (!user.email || !user.email.includes('@')) {
      throw new Error('Invalid email');
    }
    if (user.password.length < 8) {
      throw new Error('Password too short');
    }
    return true;
  }

  // Responsibility 2: Database operations
  saveUser(user) {
    this.validateUser(user);
    const query = `INSERT INTO users (email, password, name)
                   VALUES ('${user.email}', '${user.password}', '${user.name}')`;
    this.db.execute(query);
    this.logger.log(`User ${user.email} saved to database`);
  }

  // Responsibility 3: Email operations
  sendWelcomeEmail(user) {
    const subject = 'Welcome!';
    const body = `Hello ${user.name}, welcome to our platform!`;
    this.emailService.send(user.email, subject, body);
    this.logger.log(`Welcome email sent to ${user.email}`);
  }

  // Responsibility 4: Reporting
  generateUserReport(userId) {
    const user = this.db.query(`SELECT * FROM users WHERE id = ${userId}`);
    const report = {
      name: user.name,
      email: user.email,
      joinDate: user.created_at,
      totalOrders: this.db.query(`SELECT COUNT(*) FROM orders WHERE user_id = ${userId}`)
    };
    return JSON.stringify(report, null, 2);
  }

  // Responsibility 5: Password management
  resetPassword(email) {
    const newPassword = Math.random().toString(36).slice(-8);
    this.db.execute(`UPDATE users SET password = '${newPassword}' WHERE email = '${email}'`);
    this.sendPasswordResetEmail(email, newPassword);
  }

  sendPasswordResetEmail(email, newPassword) {
    this.emailService.send(
      email,
      'Password Reset',
      `Your new password is: ${newPassword}`
    );
  }
}

// Problems:
// 1. Changes to email logic require changing UserManager
// 2. Changes to validation require changing UserManager
// 3. Changes to database schema require changing UserManager
// 4. Difficult to test individual responsibilities
// 5. Violates separation of concerns
```

### ✅ Good Example - Following SRP

```javascript
// GOOD: Each class has a single responsibility

// Responsibility 1: User validation
class UserValidator {
  validate(user) {
    const errors = [];

    if (!user.email || !user.email.includes('@')) {
      errors.push('Invalid email format');
    }

    if (!user.password || user.password.length < 8) {
      errors.push('Password must be at least 8 characters');
    }

    if (!user.name || user.name.trim().length === 0) {
      errors.push('Name is required');
    }

    if (errors.length > 0) {
      throw new ValidationError(errors);
    }

    return true;
  }

  validateEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  validatePassword(password) {
    return password && password.length >= 8;
  }
}

// Responsibility 2: Database operations
class UserRepository {
  constructor(database) {
    this.db = database;
  }

  async save(user) {
    const query = {
      text: 'INSERT INTO users (email, password, name, created_at) VALUES ($1, $2, $3, $4) RETURNING *',
      values: [user.email, user.password, user.name, new Date()]
    };
    return await this.db.query(query);
  }

  async findById(id) {
    const query = {
      text: 'SELECT * FROM users WHERE id = $1',
      values: [id]
    };
    const result = await this.db.query(query);
    return result.rows[0];
  }

  async findByEmail(email) {
    const query = {
      text: 'SELECT * FROM users WHERE email = $1',
      values: [email]
    };
    const result = await this.db.query(query);
    return result.rows[0];
  }

  async updatePassword(userId, newPassword) {
    const query = {
      text: 'UPDATE users SET password = $1, updated_at = $2 WHERE id = $3',
      values: [newPassword, new Date(), userId]
    };
    return await this.db.query(query);
  }
}

// Responsibility 3: Email operations
class EmailService {
  constructor(emailProvider) {
    this.provider = emailProvider;
  }

  async sendWelcomeEmail(user) {
    const template = this.getWelcomeTemplate(user);
    return await this.send(user.email, 'Welcome!', template);
  }

  async sendPasswordResetEmail(user, resetToken) {
    const template = this.getPasswordResetTemplate(user, resetToken);
    return await this.send(user.email, 'Password Reset', template);
  }

  async send(to, subject, body) {
    return await this.provider.send({
      to,
      subject,
      body,
      from: 'noreply@example.com'
    });
  }

  getWelcomeTemplate(user) {
    return `
      <h1>Welcome, ${user.name}!</h1>
      <p>Thank you for joining our platform.</p>
    `;
  }

  getPasswordResetTemplate(user, resetToken) {
    return `
      <h1>Password Reset</h1>
      <p>Click the link below to reset your password:</p>
      <a href="https://example.com/reset?token=${resetToken}">Reset Password</a>
    `;
  }
}

// Responsibility 4: Password management
class PasswordService {
  constructor(userRepository) {
    this.userRepository = userRepository;
  }

  async hashPassword(plainPassword) {
    const bcrypt = require('bcrypt');
    return await bcrypt.hash(plainPassword, 10);
  }

  async verifyPassword(plainPassword, hashedPassword) {
    const bcrypt = require('bcrypt');
    return await bcrypt.compare(plainPassword, hashedPassword);
  }

  generateResetToken() {
    const crypto = require('crypto');
    return crypto.randomBytes(32).toString('hex');
  }

  async resetPassword(email) {
    const user = await this.userRepository.findByEmail(email);
    if (!user) {
      throw new Error('User not found');
    }

    const resetToken = this.generateResetToken();
    // Store token with expiration
    await this.userRepository.saveResetToken(user.id, resetToken, new Date(Date.now() + 3600000));

    return resetToken;
  }
}

// Responsibility 5: Reporting
class UserReportGenerator {
  constructor(userRepository, orderRepository) {
    this.userRepository = userRepository;
    this.orderRepository = orderRepository;
  }

  async generateReport(userId) {
    const user = await this.userRepository.findById(userId);
    const orderCount = await this.orderRepository.countByUserId(userId);

    return {
      id: user.id,
      name: user.name,
      email: user.email,
      joinDate: user.created_at,
      totalOrders: orderCount,
      accountStatus: this.getAccountStatus(user)
    };
  }

  getAccountStatus(user) {
    if (user.is_active) return 'Active';
    if (user.is_suspended) return 'Suspended';
    return 'Inactive';
  }

  async exportToJSON(userId) {
    const report = await this.generateReport(userId);
    return JSON.stringify(report, null, 2);
  }

  async exportToCSV(userId) {
    const report = await this.generateReport(userId);
    return Object.entries(report)
      .map(([key, value]) => `${key},${value}`)
      .join('\n');
  }
}

// Orchestration layer (Application Service)
class UserService {
  constructor(validator, repository, emailService, passwordService) {
    this.validator = validator;
    this.repository = repository;
    this.emailService = emailService;
    this.passwordService = passwordService;
  }

  async registerUser(userData) {
    // Validate
    this.validator.validate(userData);

    // Hash password
    const hashedPassword = await this.passwordService.hashPassword(userData.password);

    // Save user
    const user = await this.repository.save({
      ...userData,
      password: hashedPassword
    });

    // Send welcome email
    await this.emailService.sendWelcomeEmail(user);

    return user;
  }

  async resetUserPassword(email) {
    const resetToken = await this.passwordService.resetPassword(email);
    const user = await this.repository.findByEmail(email);
    await this.emailService.sendPasswordResetEmail(user, resetToken);
    return { message: 'Password reset email sent' };
  }
}

// Benefits:
// ✓ Each class has one reason to change
// ✓ Easy to test in isolation
// ✓ Can swap implementations easily
// ✓ Clear separation of concerns
// ✓ Reusable components
```

### SRP Checklist

```
When reviewing a class, ask:
□ Does this class have more than one reason to change?
□ Can I describe the class purpose in one sentence without "and" or "or"?
□ Are there methods that operate on different data?
□ Would changes to business logic, UI, or database all require modifying this class?
□ Can I split this class into smaller, focused classes?
```

---

## Open/Closed Principle (OCP)

### Definition
> "Software entities should be open for extension but closed for modification."
> — Bertrand Meyer

You should be able to extend a class's behavior without modifying it. This is achieved through abstraction and polymorphism.

### Why It Matters
```
┌─────────────────────────────────────────┐
│          Open/Closed Principle          │
├─────────────────────────────────────────┤
│ ✓ Reduces risk of breaking existing code│
│ ✓ Promotes code reuse                   │
│ ✓ Easier to add new features            │
│ ✓ Better for testing                    │
│ ✓ Supports plugin architectures         │
└─────────────────────────────────────────┘
```

### ❌ Bad Example - Violating OCP

```javascript
// BAD: Adding new payment methods requires modifying the class

class PaymentProcessor {
  processPayment(paymentType, amount, details) {
    if (paymentType === 'credit_card') {
      // Validate credit card
      if (!details.cardNumber || !details.cvv || !details.expiryDate) {
        throw new Error('Invalid credit card details');
      }

      // Process credit card payment
      console.log(`Processing credit card payment of $${amount}`);
      // API call to payment gateway
      return this.chargeCreditCard(details, amount);

    } else if (paymentType === 'paypal') {
      // Validate PayPal
      if (!details.email || !details.password) {
        throw new Error('Invalid PayPal credentials');
      }

      // Process PayPal payment
      console.log(`Processing PayPal payment of $${amount}`);
      // API call to PayPal
      return this.chargePayPal(details, amount);

    } else if (paymentType === 'bitcoin') {
      // Validate Bitcoin
      if (!details.walletAddress) {
        throw new Error('Invalid Bitcoin wallet');
      }

      // Process Bitcoin payment
      console.log(`Processing Bitcoin payment of $${amount}`);
      // API call to Bitcoin network
      return this.chargeBitcoin(details, amount);

    } else if (paymentType === 'bank_transfer') {
      // Every new payment method requires modifying this class!
      if (!details.accountNumber || !details.routingNumber) {
        throw new Error('Invalid bank details');
      }

      console.log(`Processing bank transfer of $${amount}`);
      return this.processBankTransfer(details, amount);

    } else {
      throw new Error(`Unsupported payment type: ${paymentType}`);
    }
  }

  chargeCreditCard(details, amount) { /* ... */ }
  chargePayPal(details, amount) { /* ... */ }
  chargeBitcoin(details, amount) { /* ... */ }
  processBankTransfer(details, amount) { /* ... */ }
}

// Problems:
// 1. Adding new payment method requires modifying PaymentProcessor
// 2. Violates OCP - not closed for modification
// 3. Growing if-else chain
// 4. Difficult to test individual payment methods
// 5. High risk of breaking existing functionality
```

### ✅ Good Example - Following OCP

```javascript
// GOOD: Use abstraction to allow extension without modification

// Abstract payment method interface
class PaymentMethod {
  validate(details) {
    throw new Error('validate() must be implemented');
  }

  process(amount, details) {
    throw new Error('process() must be implemented');
  }

  getMethodName() {
    throw new Error('getMethodName() must be implemented');
  }
}

// Concrete implementation: Credit Card
class CreditCardPayment extends PaymentMethod {
  validate(details) {
    if (!details.cardNumber) {
      throw new Error('Card number is required');
    }
    if (!details.cvv || details.cvv.length !== 3) {
      throw new Error('Valid CVV is required');
    }
    if (!details.expiryDate) {
      throw new Error('Expiry date is required');
    }

    // Additional validation: Luhn algorithm
    if (!this.luhnCheck(details.cardNumber)) {
      throw new Error('Invalid card number');
    }

    return true;
  }

  async process(amount, details) {
    this.validate(details);

    console.log(`Processing credit card payment of $${amount}`);

    // Call payment gateway API
    const gateway = new PaymentGateway();
    const result = await gateway.chargeCreditCard({
      cardNumber: details.cardNumber,
      cvv: details.cvv,
      expiryDate: details.expiryDate,
      amount: amount
    });

    return {
      success: result.approved,
      transactionId: result.transactionId,
      method: this.getMethodName()
    };
  }

  getMethodName() {
    return 'Credit Card';
  }

  luhnCheck(cardNumber) {
    // Luhn algorithm implementation
    const digits = cardNumber.replace(/\s/g, '').split('').map(Number);
    let sum = 0;
    let isEven = false;

    for (let i = digits.length - 1; i >= 0; i--) {
      let digit = digits[i];

      if (isEven) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }

      sum += digit;
      isEven = !isEven;
    }

    return sum % 10 === 0;
  }
}

// Concrete implementation: PayPal
class PayPalPayment extends PaymentMethod {
  validate(details) {
    if (!details.email || !details.email.includes('@')) {
      throw new Error('Valid email is required');
    }
    if (!details.password) {
      throw new Error('Password is required');
    }
    return true;
  }

  async process(amount, details) {
    this.validate(details);

    console.log(`Processing PayPal payment of $${amount}`);

    const paypalAPI = new PayPalAPI();
    const result = await paypalAPI.createPayment({
      email: details.email,
      password: details.password,
      amount: amount,
      currency: 'USD'
    });

    return {
      success: result.status === 'COMPLETED',
      transactionId: result.id,
      method: this.getMethodName()
    };
  }

  getMethodName() {
    return 'PayPal';
  }
}

// Concrete implementation: Bitcoin
class BitcoinPayment extends PaymentMethod {
  validate(details) {
    if (!details.walletAddress) {
      throw new Error('Bitcoin wallet address is required');
    }
    if (!this.isValidBitcoinAddress(details.walletAddress)) {
      throw new Error('Invalid Bitcoin address');
    }
    return true;
  }

  async process(amount, details) {
    this.validate(details);

    console.log(`Processing Bitcoin payment of $${amount}`);

    const bitcoinNetwork = new BitcoinNetwork();
    const btcAmount = await this.convertToBTC(amount);

    const result = await bitcoinNetwork.sendTransaction({
      to: details.walletAddress,
      amount: btcAmount
    });

    return {
      success: result.confirmed,
      transactionId: result.txHash,
      method: this.getMethodName()
    };
  }

  getMethodName() {
    return 'Bitcoin';
  }

  isValidBitcoinAddress(address) {
    // Simplified validation
    return /^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$/.test(address);
  }

  async convertToBTC(usdAmount) {
    // Get current BTC/USD rate
    const rate = await this.getCurrentBTCRate();
    return usdAmount / rate;
  }

  async getCurrentBTCRate() {
    // Fetch from API
    return 50000; // Simplified
  }
}

// NEW payment method - no modification of existing code!
class ApplePayPayment extends PaymentMethod {
  validate(details) {
    if (!details.token) {
      throw new Error('Apple Pay token is required');
    }
    return true;
  }

  async process(amount, details) {
    this.validate(details);

    console.log(`Processing Apple Pay payment of $${amount}`);

    const applePayAPI = new ApplePayAPI();
    const result = await applePayAPI.processPayment({
      token: details.token,
      amount: amount
    });

    return {
      success: result.success,
      transactionId: result.transactionId,
      method: this.getMethodName()
    };
  }

  getMethodName() {
    return 'Apple Pay';
  }
}

// Payment processor - CLOSED for modification, OPEN for extension
class PaymentProcessor {
  constructor() {
    this.paymentMethods = new Map();
  }

  // Register payment methods (dependency injection)
  registerPaymentMethod(name, paymentMethod) {
    if (!(paymentMethod instanceof PaymentMethod)) {
      throw new Error('Payment method must extend PaymentMethod class');
    }
    this.paymentMethods.set(name, paymentMethod);
  }

  async processPayment(methodName, amount, details) {
    const paymentMethod = this.paymentMethods.get(methodName);

    if (!paymentMethod) {
      throw new Error(`Payment method '${methodName}' not supported`);
    }

    try {
      const result = await paymentMethod.process(amount, details);
      this.logTransaction(result);
      return result;
    } catch (error) {
      this.logError(error);
      throw error;
    }
  }

  logTransaction(result) {
    console.log(`Transaction ${result.transactionId} via ${result.method}: ${result.success ? 'Success' : 'Failed'}`);
  }

  logError(error) {
    console.error(`Payment processing error: ${error.message}`);
  }

  getSupportedMethods() {
    return Array.from(this.paymentMethods.keys());
  }
}

// Usage
const processor = new PaymentProcessor();

// Register payment methods
processor.registerPaymentMethod('credit_card', new CreditCardPayment());
processor.registerPaymentMethod('paypal', new PayPalPayment());
processor.registerPaymentMethod('bitcoin', new BitcoinPayment());
processor.registerPaymentMethod('apple_pay', new ApplePayPayment()); // NEW - no modification needed!

// Process payments
await processor.processPayment('credit_card', 100, {
  cardNumber: '4111111111111111',
  cvv: '123',
  expiryDate: '12/25'
});

await processor.processPayment('paypal', 50, {
  email: 'user@example.com',
  password: 'password123'
});

// Benefits:
// ✓ Adding new payment methods doesn't modify PaymentProcessor
// ✓ Each payment method is independent and testable
// ✓ Easy to add features to specific payment methods
// ✓ Follows Open/Closed Principle
// ✓ Supports runtime registration of new methods
```

### Strategy Pattern for OCP

```javascript
// Another OCP example: Shipping calculator

class ShippingStrategy {
  calculate(order) {
    throw new Error('calculate() must be implemented');
  }
}

class StandardShipping extends ShippingStrategy {
  calculate(order) {
    const baseRate = 5.99;
    const perItemRate = 0.50;
    return baseRate + (order.items.length * perItemRate);
  }
}

class ExpressShipping extends ShippingStrategy {
  calculate(order) {
    const baseRate = 15.99;
    const weightCharge = order.totalWeight * 0.75;
    return baseRate + weightCharge;
  }
}

class FreeShipping extends ShippingStrategy {
  calculate(order) {
    return order.total > 100 ? 0 : 5.99;
  }
}

// NEW strategy - no modification of existing code!
class PrimeShipping extends ShippingStrategy {
  calculate(order) {
    return order.user.hasPrimeMembership ? 0 : 12.99;
  }
}

class ShippingCalculator {
  constructor(strategy) {
    this.strategy = strategy;
  }

  setStrategy(strategy) {
    this.strategy = strategy;
  }

  calculate(order) {
    return this.strategy.calculate(order);
  }
}

// Usage
const order = { items: [1, 2, 3], total: 150, totalWeight: 5, user: { hasPrimeMembership: true } };

const calculator = new ShippingCalculator(new StandardShipping());
console.log(calculator.calculate(order)); // Standard shipping cost

calculator.setStrategy(new PrimeShipping());
console.log(calculator.calculate(order)); // Prime shipping cost
```

### OCP Checklist

```
When adding new functionality, ask:
□ Am I modifying existing, working code?
□ Can I add the new feature by creating new classes instead?
□ Have I defined abstractions (interfaces/base classes)?
□ Can new behaviors be added through inheritance or composition?
□ Is my code using polymorphism effectively?
```

---

## Liskov Substitution Principle (LSP)

### Definition
> "Objects of a superclass should be replaceable with objects of a subclass without breaking the application."
> — Barbara Liskov

If class B is a subtype of class A, we should be able to replace A with B without disrupting the behavior of our program.

### Why It Matters
```
┌─────────────────────────────────────────┐
│     Liskov Substitution Principle       │
├─────────────────────────────────────────┤
│ ✓ Ensures correct inheritance hierarchies│
│ ✓ Prevents unexpected behaviors         │
│ ✓ Enables true polymorphism             │
│ ✓ Improves code reliability             │
│ ✓ Supports design by contract           │
└─────────────────────────────────────────┘
```

### ❌ Bad Example - Violating LSP

```javascript
// BAD: Square violates LSP when extending Rectangle

class Rectangle {
  constructor(width, height) {
    this.width = width;
    this.height = height;
  }

  setWidth(width) {
    this.width = width;
  }

  setHeight(height) {
    this.height = height;
  }

  getArea() {
    return this.width * this.height;
  }
}

class Square extends Rectangle {
  constructor(size) {
    super(size, size);
  }

  // Problem: Square changes the behavior of Rectangle
  setWidth(width) {
    this.width = width;
    this.height = width; // Violates LSP!
  }

  setHeight(height) {
    this.width = height; // Violates LSP!
    this.height = height;
  }
}

// Test function that works with Rectangle
function testRectangle(rectangle) {
  rectangle.setWidth(5);
  rectangle.setHeight(4);

  // Expected: 5 * 4 = 20
  console.log(`Expected area: 20, Got: ${rectangle.getArea()}`);

  return rectangle.getArea() === 20;
}

// Test with Rectangle - works fine
const rect = new Rectangle(0, 0);
console.log(testRectangle(rect)); // true - area is 20

// Test with Square - FAILS!
const square = new Square(0);
console.log(testRectangle(square)); // false - area is 16, not 20!

// Problem: Square is NOT substitutable for Rectangle
// This violates LSP because Square changes the expected behavior

// Another LSP violation: Bird example
class Bird {
  fly() {
    console.log('Flying...');
  }

  eat() {
    console.log('Eating...');
  }
}

class Penguin extends Bird {
  fly() {
    // Penguins can't fly!
    throw new Error('Penguins cannot fly');
  }
}

// Function that works with Bird
function makeBirdFly(bird) {
  bird.fly(); // Expects all birds to fly
}

const sparrow = new Bird();
makeBirdFly(sparrow); // Works fine

const penguin = new Penguin();
makeBirdFly(penguin); // CRASHES! Violates LSP

// Problems:
// 1. Subclass throws exception not in parent contract
// 2. Cannot substitute Penguin for Bird
// 3. Breaks polymorphism
// 4. Inheritance is wrong - Penguin IS-A Bird but doesn't behave like one
```

### ✅ Good Example - Following LSP

```javascript
// GOOD: Proper abstraction that follows LSP

// Solution 1: Rectangle/Square problem

class Shape {
  getArea() {
    throw new Error('getArea() must be implemented');
  }
}

class Rectangle extends Shape {
  constructor(width, height) {
    super();
    this._width = width;
    this._height = height;
  }

  get width() {
    return this._width;
  }

  get height() {
    return this._height;
  }

  setWidth(width) {
    this._width = width;
  }

  setHeight(height) {
    this._height = height;
  }

  getArea() {
    return this._width * this._height;
  }
}

class Square extends Shape {
  constructor(size) {
    super();
    this._size = size;
  }

  get size() {
    return this._size;
  }

  setSize(size) {
    this._size = size;
  }

  getArea() {
    return this._size * this._size;
  }
}

// Now we can work with shapes polymorphically
function printArea(shape) {
  console.log(`Area: ${shape.getArea()}`);
}

const rect = new Rectangle(5, 4);
const square = new Square(4);

printArea(rect); // Area: 20
printArea(square); // Area: 16

// Both work correctly because they both follow Shape contract
// No unexpected behavior!

// Solution 2: Bird problem with proper abstraction

class Animal {
  eat() {
    console.log('Eating...');
  }

  move() {
    throw new Error('move() must be implemented');
  }
}

class Bird extends Animal {
  move() {
    console.log('Moving...');
  }
}

class FlyingBird extends Bird {
  move() {
    this.fly();
  }

  fly() {
    console.log('Flying through the air...');
  }
}

class FlightlessBird extends Bird {
  move() {
    this.walk();
  }

  walk() {
    console.log('Walking on the ground...');
  }
}

// Specific implementations
class Sparrow extends FlyingBird {
  fly() {
    console.log('Sparrow flying swiftly...');
  }
}

class Eagle extends FlyingBird {
  fly() {
    console.log('Eagle soaring high...');
  }
}

class Penguin extends FlightlessBird {
  walk() {
    console.log('Penguin waddling...');
  }

  swim() {
    console.log('Penguin swimming gracefully...');
  }
}

class Ostrich extends FlightlessBird {
  walk() {
    console.log('Ostrich running fast...');
  }
}

// Functions working with proper abstractions
function makeAnimalMove(animal) {
  animal.move(); // All animals can move
}

function makeBirdFly(flyingBird) {
  if (!(flyingBird instanceof FlyingBird)) {
    throw new Error('Only flying birds can fly');
  }
  flyingBird.fly(); // Only flying birds have fly()
}

// All work correctly with LSP
const sparrow = new Sparrow();
const eagle = new Eagle();
const penguin = new Penguin();
const ostrich = new Ostrich();

makeAnimalMove(sparrow);  // Sparrow flying swiftly...
makeAnimalMove(eagle);    // Eagle soaring high...
makeAnimalMove(penguin);  // Penguin waddling...
makeAnimalMove(ostrich);  // Ostrich running fast...

makeBirdFly(sparrow);     // Sparrow flying swiftly...
makeBirdFly(eagle);       // Eagle soaring high...
// makeBirdFly(penguin);  // Type error - penguin is not FlyingBird

// Benefits:
// ✓ Proper inheritance hierarchy
// ✓ No unexpected exceptions
// ✓ True polymorphism
// ✓ LSP compliant
```

### LSP Rules

```javascript
// LSP Contract Rules:

// 1. Preconditions cannot be strengthened in subclass
class User {
  setAge(age) {
    if (age < 0) throw new Error('Age must be positive');
    this.age = age;
  }
}

// BAD: Strengthens precondition
class AdultUser extends User {
  setAge(age) {
    if (age < 18) throw new Error('Must be 18 or older'); // Stricter!
    super.setAge(age);
  }
}

// GOOD: Doesn't strengthen precondition
class AdultUser extends User {
  setAge(age) {
    super.setAge(age);
    if (age < 18) {
      console.warn('User is a minor');
    }
  }
}

// 2. Postconditions cannot be weakened in subclass
class Account {
  withdraw(amount) {
    this.balance -= amount;
    // Postcondition: balance is always >= 0
    if (this.balance < 0) {
      throw new Error('Insufficient funds');
    }
  }
}

// BAD: Weakens postcondition (allows negative balance)
class OverdraftAccount extends Account {
  withdraw(amount) {
    this.balance -= amount;
    // Allows negative balance - weakens postcondition!
  }
}

// GOOD: Maintains postcondition
class OverdraftAccount extends Account {
  constructor(balance, overdraftLimit) {
    super(balance);
    this.overdraftLimit = overdraftLimit;
  }

  withdraw(amount) {
    this.balance -= amount;
    // Still ensures balance >= -overdraftLimit
    if (this.balance < -this.overdraftLimit) {
      throw new Error('Overdraft limit exceeded');
    }
  }
}

// 3. Invariants must be preserved
class Stack {
  constructor() {
    this.items = [];
  }

  push(item) {
    this.items.push(item);
    // Invariant: size increases by 1
  }

  pop() {
    if (this.items.length === 0) {
      throw new Error('Stack is empty');
    }
    return this.items.pop();
    // Invariant: size decreases by 1
  }

  size() {
    return this.items.length;
  }
}

// BAD: Violates invariant
class BoundedStack extends Stack {
  constructor(maxSize) {
    super();
    this.maxSize = maxSize;
  }

  push(item) {
    if (this.items.length >= this.maxSize) {
      // Silently ignores - violates size invariant!
      return;
    }
    super.push(item);
  }
}

// GOOD: Preserves invariant
class BoundedStack extends Stack {
  constructor(maxSize) {
    super();
    this.maxSize = maxSize;
  }

  push(item) {
    if (this.items.length >= this.maxSize) {
      throw new Error('Stack is full'); // Explicit error
    }
    super.push(item); // Maintains invariant
  }
}
```

### LSP Checklist

```
When creating subclasses, verify:
□ Can subclass be used anywhere parent is expected?
□ Does subclass strengthen preconditions? (DON'T)
□ Does subclass weaken postconditions? (DON'T)
□ Does subclass preserve invariants?
□ Does subclass throw new exceptions not in parent?
□ Is inheritance relationship truly "IS-A"?
□ Consider composition over inheritance if LSP is violated
```

---

## Interface Segregation Principle (ISP)

### Definition
> "Clients should not be forced to depend on interfaces they do not use."
> — Robert C. Martin

Many specific interfaces are better than one general-purpose interface. Don't force classes to implement methods they don't need.

### Why It Matters
```
┌─────────────────────────────────────────┐
│    Interface Segregation Principle      │
├─────────────────────────────────────────┤
│ ✓ Reduces coupling                      │
│ ✓ Increases cohesion                    │
│ ✓ Improves flexibility                  │
│ ✓ Easier to understand                  │
│ ✓ Better refactoring                    │
└─────────────────────────────────────────┘
```

### ❌ Bad Example - Violating ISP

```javascript
// BAD: Fat interface forces implementations to have methods they don't need

interface Worker {
  work(): void;
  eat(): void;
  sleep(): void;
  takeBreak(): void;
  getPaid(): void;
  attendMeeting(): void;
  writeCode(): void;
}

// Human worker - uses all methods
class HumanWorker implements Worker {
  work() {
    console.log('Working on tasks...');
  }

  eat() {
    console.log('Eating lunch...');
  }

  sleep() {
    console.log('Sleeping at night...');
  }

  takeBreak() {
    console.log('Taking a break...');
  }

  getPaid() {
    console.log('Receiving salary...');
  }

  attendMeeting() {
    console.log('Attending meeting...');
  }

  writeCode() {
    console.log('Writing code...');
  }
}

// Robot worker - doesn't need eat, sleep, getPaid!
class RobotWorker implements Worker {
  work() {
    console.log('Robot working 24/7...');
  }

  eat() {
    // Robots don't eat!
    throw new Error('Robots do not eat');
  }

  sleep() {
    // Robots don't sleep!
    throw new Error('Robots do not sleep');
  }

  takeBreak() {
    console.log('Entering maintenance mode...');
  }

  getPaid() {
    // Robots don't get paid!
    throw new Error('Robots do not get paid');
  }

  attendMeeting() {
    throw new Error('Robots do not attend meetings');
  }

  writeCode() {
    console.log('Robot generating code...');
  }
}

// Intern - doesn't write code or attend all meetings
class InternWorker implements Worker {
  work() {
    console.log('Learning and assisting...');
  }

  eat() {
    console.log('Eating in cafeteria...');
  }

  sleep() {
    console.log('Sleeping...');
  }

  takeBreak() {
    console.log('Coffee break...');
  }

  getPaid() {
    console.log('Receiving stipend...');
  }

  attendMeeting() {
    throw new Error('Interns attend only some meetings');
  }

  writeCode() {
    throw new Error('Interns are still learning to code');
  }
}

// Problems:
// 1. Forced to implement unnecessary methods
// 2. Many methods throw errors
// 3. Clients depend on methods they don't use
// 4. Violates ISP
// 5. Difficult to extend with new worker types
```

### ✅ Good Example - Following ISP

```javascript
// GOOD: Segregated interfaces - small, focused interfaces

// Core working interface
interface Workable {
  work(): void;
}

// Biological needs
interface Eatable {
  eat(): void;
}

interface Sleepable {
  sleep(): void;
}

// Employment interfaces
interface Payable {
  getPaid(): void;
}

interface Breakable {
  takeBreak(): void;
}

// Professional activities
interface MeetingAttendee {
  attendMeeting(meeting: string): void;
}

interface Programmer {
  writeCode(task: string): void;
}

// Maintenance
interface Maintainable {
  performMaintenance(): void;
}

// Human worker implements relevant interfaces
class HumanWorker implements Workable, Eatable, Sleepable, Payable, Breakable {
  work() {
    console.log('Working on tasks...');
  }

  eat() {
    console.log('Eating lunch...');
  }

  sleep() {
    console.log('Sleeping at night...');
  }

  getPaid() {
    console.log('Receiving salary...');
  }

  takeBreak() {
    console.log('Taking a break...');
  }
}

// Developer implements additional programming interface
class Developer extends HumanWorker implements Programmer, MeetingAttendee {
  writeCode(task: string) {
    console.log(`Writing code for: ${task}`);
  }

  attendMeeting(meeting: string) {
    console.log(`Attending ${meeting} meeting`);
  }
}

// Robot worker - only implements what it needs
class RobotWorker implements Workable, Maintainable, Programmer {
  work() {
    console.log('Robot working 24/7...');
  }

  performMaintenance() {
    console.log('Running diagnostics and maintenance...');
  }

  writeCode(task: string) {
    console.log(`Robot generating code for: ${task}`);
  }
}

// Intern - implements subset of interfaces
class Intern implements Workable, Eatable, Sleepable, Payable, Breakable {
  work() {
    console.log('Learning and assisting...');
  }

  eat() {
    console.log('Eating in cafeteria...');
  }

  sleep() {
    console.log('Sleeping...');
  }

  getPaid() {
    console.log('Receiving stipend...');
  }

  takeBreak() {
    console.log('Coffee break...');
  }
}

// Manager - attends meetings but doesn't code
class Manager extends HumanWorker implements MeetingAttendee {
  attendMeeting(meeting: string) {
    console.log(`Manager attending ${meeting} meeting`);
  }

  organizeMeeting(topic: string) {
    console.log(`Organizing meeting about: ${topic}`);
  }
}

// Functions work with specific interfaces
function makeWorkableWork(workable: Workable) {
  workable.work();
}

function feedEatable(eatable: Eatable) {
  eatable.eat();
}

function assignCodingTask(programmer: Programmer, task: string) {
  programmer.writeCode(task);
}

function scheduleMeeting(attendee: MeetingAttendee, meeting: string) {
  attendee.attendMeeting(meeting);
}

// Usage
const dev = new Developer();
const robot = new RobotWorker();
const intern = new Intern();
const manager = new Manager();

makeWorkableWork(dev);    // All can work
makeWorkableWork(robot);
makeWorkableWork(intern);
makeWorkableWork(manager);

feedEatable(dev);         // Only humans eat
feedEatable(intern);
feedEatable(manager);
// feedEatable(robot);    // Type error - robot doesn't implement Eatable

assignCodingTask(dev, 'API');     // Developers and robots code
assignCodingTask(robot, 'Tests');
// assignCodingTask(intern, 'Feature'); // Type error - intern isn't Programmer

scheduleMeeting(dev, 'Standup');      // Developers and managers attend
scheduleMeeting(manager, 'Planning');
// scheduleMeeting(robot, 'Review');  // Type error - robot doesn't attend

// Benefits:
// ✓ No empty or exception-throwing methods
// ✓ Each class implements only what it needs
// ✓ Easy to add new worker types
// ✓ Clients depend only on methods they use
// ✓ Follows ISP perfectly
```

### Real-World Example: Document Processor

```javascript
// BAD: Fat interface
interface DocumentProcessor {
  open(path: string): void;
  save(path: string): void;
  print(): void;
  scan(): void;
  fax(number: string): void;
  email(address: string): void;
  encrypt(): void;
  compress(): void;
}

// Modern printer - has all features
class MultiFunctionPrinter implements DocumentProcessor {
  open(path: string) { console.log(`Opening ${path}`); }
  save(path: string) { console.log(`Saving to ${path}`); }
  print() { console.log('Printing document...'); }
  scan() { console.log('Scanning document...'); }
  fax(number: string) { console.log(`Faxing to ${number}`); }
  email(address: string) { console.log(`Emailing to ${address}`); }
  encrypt() { console.log('Encrypting document...'); }
  compress() { console.log('Compressing document...'); }
}

// Old printer - forced to implement methods it doesn't support
class OldPrinter implements DocumentProcessor {
  open(path: string) { throw new Error('Not supported'); }
  save(path: string) { throw new Error('Not supported'); }
  print() { console.log('Printing...'); }
  scan() { throw new Error('Cannot scan'); }
  fax(number: string) { throw new Error('Cannot fax'); }
  email(address: string) { throw new Error('Cannot email'); }
  encrypt() { throw new Error('Cannot encrypt'); }
  compress() { throw new Error('Cannot compress'); }
}

// GOOD: Segregated interfaces
interface Printer {
  print(document: Document): void;
}

interface Scanner {
  scan(): Document;
}

interface FaxMachine {
  fax(document: Document, number: string): void;
}

interface EmailSender {
  email(document: Document, address: string): void;
}

interface DocumentEncryptor {
  encrypt(document: Document): Document;
}

interface DocumentCompressor {
  compress(document: Document): Document;
}

// Simple printer
class SimplePrinter implements Printer {
  print(document: Document) {
    console.log('Printing document...');
  }
}

// Multi-function device
class MultiFunctionDevice implements Printer, Scanner, FaxMachine {
  print(document: Document) {
    console.log('Printing document...');
  }

  scan(): Document {
    console.log('Scanning document...');
    return new Document();
  }

  fax(document: Document, number: string) {
    console.log(`Faxing to ${number}...`);
  }
}

// Modern office device
class ModernOfficeDevice implements Printer, Scanner, EmailSender, DocumentEncryptor, DocumentCompressor {
  print(document: Document) {
    console.log('Printing high-quality document...');
  }

  scan(): Document {
    console.log('Scanning in color...');
    return new Document();
  }

  email(document: Document, address: string) {
    console.log(`Emailing to ${address}...`);
  }

  encrypt(document: Document): Document {
    console.log('Encrypting document...');
    return document;
  }

  compress(document: Document): Document {
    console.log('Compressing document...');
    return document;
  }
}

// Functions work with specific capabilities
function printDocument(printer: Printer, doc: Document) {
  printer.print(doc);
}

function digitizeDocument(scanner: Scanner): Document {
  return scanner.scan();
}

// All devices can be used polymorphically based on their capabilities
const simple = new SimplePrinter();
const multiFunc = new MultiFunctionDevice();
const modern = new ModernOfficeDevice();

printDocument(simple, new Document());    // All can print
printDocument(multiFunc, new Document());
printDocument(modern, new Document());

const scanned = digitizeDocument(multiFunc);  // Only multiFunc and modern can scan
const colorScan = digitizeDocument(modern);
// digitizeDocument(simple); // Type error - simple can't scan
```

### ISP Checklist

```
When designing interfaces, ask:
□ Is my interface doing too much?
□ Do all implementations use all methods?
□ Are implementers throwing "not supported" exceptions?
□ Can I split this into smaller, focused interfaces?
□ Do clients depend on methods they don't use?
□ Would role-based interfaces make more sense?
```

---

## Dependency Inversion Principle (DIP)

### Definition
> "High-level modules should not depend on low-level modules. Both should depend on abstractions. Abstractions should not depend on details. Details should depend on abstractions."
> — Robert C. Martin

Depend on interfaces/abstractions, not concrete implementations.

### Why It Matters
```
┌─────────────────────────────────────────┐
│     Dependency Inversion Principle      │
├─────────────────────────────────────────┤
│ ✓ Reduces coupling                      │
│ ✓ Increases flexibility                 │
│ ✓ Easier testing (mocking)              │
│ ✓ Enables dependency injection          │
│ ✓ Supports plugin architectures         │
└─────────────────────────────────────────┘
```

### Traditional Dependency Flow (BAD)
```
┌──────────────────┐
│   High-Level     │
│    (Business)    │───depends on───┐
└──────────────────┘                │
                                    ▼
                          ┌──────────────────┐
                          │    Low-Level     │
                          │  (Infrastructure)│
                          └──────────────────┘
```

### Inverted Dependency Flow (GOOD)
```
┌──────────────────┐
│   High-Level     │
│    (Business)    │───depends on───┐
└──────────────────┘                │
                                    ▼
                          ┌──────────────────┐
                          │   Abstraction    │
                          │   (Interface)    │
                          └──────────────────┘
                                    ▲
                                    │───implements───
                          ┌──────────────────┐
                          │    Low-Level     │
                          │  (Infrastructure)│
                          └──────────────────┘
```

### ❌ Bad Example - Violating DIP

```javascript
// BAD: High-level module depends on low-level modules directly

// Low-level modules (infrastructure)
class MySQLDatabase {
  connect() {
    console.log('Connecting to MySQL...');
  }

  query(sql) {
    console.log(`Executing MySQL query: ${sql}`);
    return [{ id: 1, name: 'John' }];
  }

  close() {
    console.log('Closing MySQL connection');
  }
}

class EmailService {
  send(to, subject, body) {
    console.log(`Sending email to ${to}`);
    console.log(`Subject: ${subject}`);
    // SMTP logic
  }
}

class Logger {
  log(message) {
    console.log(`[LOG] ${message}`);
  }
}

// High-level module depends directly on low-level modules
class UserService {
  constructor() {
    // Direct dependencies on concrete classes!
    this.database = new MySQLDatabase();
    this.emailService = new EmailService();
    this.logger = new Logger();
  }

  async registerUser(userData) {
    this.logger.log('Registering new user...');

    // Tightly coupled to MySQL
    this.database.connect();
    const result = this.database.query(
      `INSERT INTO users (name, email) VALUES ('${userData.name}', '${userData.email}')`
    );
    this.database.close();

    // Tightly coupled to EmailService
    this.emailService.send(
      userData.email,
      'Welcome!',
      `Hello ${userData.name}, welcome to our platform!`
    );

    this.logger.log('User registered successfully');
    return result;
  }
}

// Problems:
// 1. Cannot switch to PostgreSQL without modifying UserService
// 2. Cannot use different email provider without modifying UserService
// 3. Difficult to test - cannot mock dependencies
// 4. Hard-coded dependencies
// 5. Violates DIP - high-level depends on low-level
```

### ✅ Good Example - Following DIP

```javascript
// GOOD: Depend on abstractions, use dependency injection

// Abstractions (interfaces)
interface Database {
  connect(): void;
  query(sql: string): Promise<any>;
  close(): void;
}

interface EmailProvider {
  sendEmail(to: string, subject: string, body: string): Promise<void>;
}

interface LoggerInterface {
  log(message: string): void;
  error(message: string): void;
}

// Low-level modules implement abstractions
class MySQLDatabase implements Database {
  async connect() {
    console.log('Connecting to MySQL...');
  }

  async query(sql: string) {
    console.log(`Executing MySQL query: ${sql}`);
    // MySQL-specific logic
    return [{ id: 1, name: 'John' }];
  }

  async close() {
    console.log('Closing MySQL connection');
  }
}

class PostgreSQLDatabase implements Database {
  async connect() {
    console.log('Connecting to PostgreSQL...');
  }

  async query(sql: string) {
    console.log(`Executing PostgreSQL query: ${sql}`);
    // PostgreSQL-specific logic
    return [{ id: 1, name: 'John' }];
  }

  async close() {
    console.log('Closing PostgreSQL connection');
  }
}

class MongoDatabase implements Database {
  async connect() {
    console.log('Connecting to MongoDB...');
  }

  async query(sql: string) {
    console.log(`Executing MongoDB query: ${sql}`);
    // MongoDB-specific logic
    return [{ id: 1, name: 'John' }];
  }

  async close() {
    console.log('Closing MongoDB connection');
  }
}

class SMTPEmailProvider implements EmailProvider {
  async sendEmail(to: string, subject: string, body: string) {
    console.log(`Sending email via SMTP to ${to}`);
    console.log(`Subject: ${subject}`);
    // SMTP logic
  }
}

class SendGridEmailProvider implements EmailProvider {
  async sendEmail(to: string, subject: string, body: string) {
    console.log(`Sending email via SendGrid to ${to}`);
    console.log(`Subject: ${subject}`);
    // SendGrid API logic
  }
}

class ConsoleLogger implements LoggerInterface {
  log(message: string) {
    console.log(`[LOG] ${new Date().toISOString()} - ${message}`);
  }

  error(message: string) {
    console.error(`[ERROR] ${new Date().toISOString()} - ${message}`);
  }
}

class FileLogger implements LoggerInterface {
  log(message: string) {
    // Write to file
    console.log(`Writing to file: [LOG] ${message}`);
  }

  error(message: string) {
    // Write to file
    console.log(`Writing to file: [ERROR] ${message}`);
  }
}

// High-level module depends on abstractions
class UserService {
  // Depend on interfaces, not implementations
  constructor(
    private database: Database,
    private emailProvider: EmailProvider,
    private logger: LoggerInterface
  ) {}

  async registerUser(userData: { name: string; email: string }) {
    try {
      this.logger.log('Starting user registration...');

      await this.database.connect();

      const result = await this.database.query(
        `INSERT INTO users (name, email) VALUES ('${userData.name}', '${userData.email}')`
      );

      await this.database.close();

      await this.emailProvider.sendEmail(
        userData.email,
        'Welcome!',
        `Hello ${userData.name}, welcome to our platform!`
      );

      this.logger.log('User registered successfully');
      return result;
    } catch (error) {
      this.logger.error(`Registration failed: ${error.message}`);
      throw error;
    }
  }

  async findUser(id: number) {
    this.logger.log(`Finding user with ID: ${id}`);
    await this.database.connect();
    const result = await this.database.query(`SELECT * FROM users WHERE id = ${id}`);
    await this.database.close();
    return result[0];
  }
}

// Dependency Injection Container (simple example)
class Container {
  private services = new Map();

  register(name: string, instance: any) {
    this.services.set(name, instance);
  }

  get(name: string) {
    return this.services.get(name);
  }
}

// Usage - Manual dependency injection
const mysqlDb = new MySQLDatabase();
const smtpEmail = new SMTPEmailProvider();
const consoleLogger = new ConsoleLogger();

const userService = new UserService(mysqlDb, smtpEmail, consoleLogger);
await userService.registerUser({ name: 'John', email: 'john@example.com' });

// Easy to switch implementations!
const postgresDb = new PostgreSQLDatabase();
const sendGridEmail = new SendGridEmailProvider();
const fileLogger = new FileLogger();

const userService2 = new UserService(postgresDb, sendGridEmail, fileLogger);
await userService2.registerUser({ name: 'Jane', email: 'jane@example.com' });

// Easy to test with mocks!
class MockDatabase implements Database {
  async connect() {}
  async query(sql: string) {
    return [{ id: 999, name: 'Test User' }];
  }
  async close() {}
}

class MockEmailProvider implements EmailProvider {
  emailsSent: any[] = [];

  async sendEmail(to: string, subject: string, body: string) {
    this.emailsSent.push({ to, subject, body });
  }
}

class MockLogger implements LoggerInterface {
  logs: string[] = [];
  errors: string[] = [];

  log(message: string) {
    this.logs.push(message);
  }

  error(message: string) {
    this.errors.push(message);
  }
}

// Test
const mockDb = new MockDatabase();
const mockEmail = new MockEmailProvider();
const mockLogger = new MockLogger();

const testUserService = new UserService(mockDb, mockEmail, mockLogger);
await testUserService.registerUser({ name: 'Test', email: 'test@example.com' });

console.log('Emails sent:', mockEmail.emailsSent.length); // 1
console.log('Logs:', mockLogger.logs.length); // 2

// Benefits:
// ✓ Easy to switch implementations (MySQL → PostgreSQL)
// ✓ Easy to test with mocks
// ✓ High-level module independent of low-level details
// ✓ Follows DIP perfectly
// ✓ Loose coupling
```

### DIP with Factory Pattern

```javascript
// Abstract factory for creating dependencies
interface DatabaseFactory {
  createDatabase(): Database;
}

class MySQLFactory implements DatabaseFactory {
  createDatabase(): Database {
    return new MySQLDatabase();
  }
}

class PostgreSQLFactory implements DatabaseFactory {
  createDatabase(): Database {
    return new PostgreSQLDatabase();
  }
}

// Configuration-based factory
class DatabaseFactoryProvider {
  static createFactory(type: string): DatabaseFactory {
    switch (type) {
      case 'mysql':
        return new MySQLFactory();
      case 'postgresql':
        return new PostgreSQLFactory();
      default:
        throw new Error(`Unsupported database type: ${type}`);
    }
  }
}

// Usage
const dbType = process.env.DB_TYPE || 'mysql';
const factory = DatabaseFactoryProvider.createFactory(dbType);
const database = factory.createDatabase();

const userService = new UserService(
  database,
  new SMTPEmailProvider(),
  new ConsoleLogger()
);
```

### DIP Checklist

```
When designing dependencies, verify:
□ Are high-level modules independent of low-level modules?
□ Do both depend on abstractions (interfaces)?
□ Can I easily swap implementations?
□ Can I test with mocks?
□ Am I using dependency injection?
□ Are dependencies passed in, not created internally?
□ Is there a clear separation between business logic and infrastructure?
```

---

## SOLID in Practice

### Combining All Principles

```javascript
// Real-world example: E-commerce Order Processing

// Interfaces (ISP + DIP)
interface ProductRepository {
  findById(id: string): Promise<Product>;
  save(product: Product): Promise<void>;
}

interface InventoryService {
  checkAvailability(productId: string, quantity: number): Promise<boolean>;
  reserve(productId: string, quantity: number): Promise<void>;
  release(productId: string, quantity: number): Promise<void>;
}

interface PaymentProcessor {
  processPayment(amount: number, paymentDetails: any): Promise<PaymentResult>;
  refund(transactionId: string): Promise<void>;
}

interface NotificationService {
  sendOrderConfirmation(order: Order): Promise<void>;
  sendPaymentFailure(order: Order): Promise<void>;
}

interface OrderRepository {
  save(order: Order): Promise<void>;
  findById(id: string): Promise<Order>;
}

// Value Objects (DDD + LSP)
class Money {
  constructor(
    private readonly amount: number,
    private readonly currency: string
  ) {
    if (amount < 0) {
      throw new Error('Amount cannot be negative');
    }
  }

  add(other: Money): Money {
    if (this.currency !== other.currency) {
      throw new Error('Cannot add different currencies');
    }
    return new Money(this.amount + other.amount, this.currency);
  }

  multiply(factor: number): Money {
    return new Money(this.amount * factor, this.currency);
  }

  getAmount(): number {
    return this.amount;
  }

  getCurrency(): string {
    return this.currency;
  }
}

// Entities (SRP)
class Product {
  constructor(
    public readonly id: string,
    public name: string,
    public price: Money,
    public stock: number
  ) {}
}

class OrderItem {
  constructor(
    public readonly product: Product,
    public readonly quantity: number
  ) {}

  getTotal(): Money {
    return this.product.price.multiply(this.quantity);
  }
}

class Order {
  private items: OrderItem[] = [];
  private status: OrderStatus = OrderStatus.PENDING;

  constructor(
    public readonly id: string,
    public readonly customerId: string
  ) {}

  addItem(item: OrderItem): void {
    this.items.push(item);
  }

  getTotal(): Money {
    return this.items.reduce(
      (total, item) => total.add(item.getTotal()),
      new Money(0, 'USD')
    );
  }

  confirm(): void {
    if (this.status !== OrderStatus.PENDING) {
      throw new Error('Can only confirm pending orders');
    }
    this.status = OrderStatus.CONFIRMED;
  }

  cancel(): void {
    if (this.status === OrderStatus.SHIPPED) {
      throw new Error('Cannot cancel shipped orders');
    }
    this.status = OrderStatus.CANCELLED;
  }

  getStatus(): OrderStatus {
    return this.status;
  }

  getItems(): OrderItem[] {
    return [...this.items]; // Return copy (encapsulation)
  }
}

enum OrderStatus {
  PENDING = 'PENDING',
  CONFIRMED = 'CONFIRMED',
  SHIPPED = 'SHIPPED',
  CANCELLED = 'CANCELLED'
}

// Domain Service (SRP + DIP)
class OrderService {
  constructor(
    private orderRepo: OrderRepository,
    private inventoryService: InventoryService,
    private paymentProcessor: PaymentProcessor,
    private notificationService: NotificationService
  ) {}

  async placeOrder(customerId: string, items: OrderItem[]): Promise<Order> {
    // Create order
    const order = new Order(this.generateOrderId(), customerId);
    items.forEach(item => order.addItem(item));

    // Check inventory
    for (const item of items) {
      const available = await this.inventoryService.checkAvailability(
        item.product.id,
        item.quantity
      );

      if (!available) {
        throw new Error(`Product ${item.product.name} is out of stock`);
      }
    }

    // Reserve inventory
    for (const item of items) {
      await this.inventoryService.reserve(item.product.id, item.quantity);
    }

    try {
      // Process payment
      const paymentResult = await this.paymentProcessor.processPayment(
        order.getTotal().getAmount(),
        { /* payment details */ }
      );

      if (!paymentResult.success) {
        // Release inventory
        for (const item of items) {
          await this.inventoryService.release(item.product.id, item.quantity);
        }

        await this.notificationService.sendPaymentFailure(order);
        throw new Error('Payment failed');
      }

      // Confirm order
      order.confirm();
      await this.orderRepo.save(order);

      // Send confirmation
      await this.notificationService.sendOrderConfirmation(order);

      return order;
    } catch (error) {
      // Rollback inventory reservation
      for (const item of items) {
        await this.inventoryService.release(item.product.id, item.quantity);
      }
      throw error;
    }
  }

  private generateOrderId(): string {
    return `ORD-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
}

// This design demonstrates all SOLID principles:
//
// S - Single Responsibility:
//   - Order handles order state
//   - OrderService handles order processing workflow
//   - Each repository handles data access for one entity
//
// O - Open/Closed:
//   - Can add new payment processors without modifying OrderService
//   - Can add new notification channels without changing core logic
//
// L - Liskov Substitution:
//   - Any PaymentProcessor implementation can be substituted
//   - Any NotificationService implementation works
//
// I - Interface Segregation:
//   - Separate interfaces for different concerns
//   - OrderService only depends on interfaces it uses
//
// D - Dependency Inversion:
//   - OrderService depends on abstractions (interfaces)
//   - Infrastructure implements interfaces
//   - Easy to test with mocks
```

---

## Common Violations

### God Object Anti-Pattern
```javascript
// Violates SRP, hard to maintain
class Application {
  handleHTTPRequest() {}
  connectToDatabase() {}
  generateReport() {}
  sendEmail() {}
  processPayment() {}
  validateUser() {}
  // ... 50 more methods
}
```

### Leaky Abstractions
```javascript
// Violates DIP - exposes implementation details
interface UserRepository {
  executeSQLQuery(sql: string): Promise<any>; // Leaks SQL!
}

// Better
interface UserRepository {
  findById(id: string): Promise<User>;
  save(user: User): Promise<void>;
}
```

### Refused Bequest
```javascript
// Violates LSP
class Bird {
  fly() { /* ... */ }
}

class Penguin extends Bird {
  fly() {
    throw new Error('Penguins cannot fly'); // Violates LSP!
  }
}
```

---

## Exercises

### Exercise 1: Refactor Violating SRP
```javascript
// Refactor this class to follow SRP
class BlogPost {
  title: string;
  content: string;
  author: string;

  save() {
    // Database logic
    const db = new Database();
    db.execute(`INSERT INTO posts...`);
  }

  sendNotification() {
    // Email logic
    const email = new EmailService();
    email.send('New post published');
  }

  formatAsHTML() {
    return `<h1>${this.title}</h1><p>${this.content}</p>`;
  }

  formatAsJSON() {
    return JSON.stringify(this);
  }
}
```

### Exercise 2: Apply OCP
```javascript
// Add new discount types without modifying this class
class DiscountCalculator {
  calculate(price: number, discountType: string) {
    if (discountType === 'percentage') {
      return price * 0.1;
    } else if (discountType === 'fixed') {
      return 10;
    }
    return 0;
  }
}
```

### Exercise 3: Fix LSP Violation
```javascript
// Fix this LSP violation
class Rectangle {
  setWidth(w) { this.width = w; }
  setHeight(h) { this.height = h; }
  area() { return this.width * this.height; }
}

class Square extends Rectangle {
  setWidth(w) {
    this.width = w;
    this.height = w;
  }
  setHeight(h) {
    this.width = h;
    this.height = h;
  }
}
```

### Exercise 4: Apply ISP
```javascript
// Split this fat interface
interface Machine {
  print(doc: Document): void;
  scan(): Document;
  fax(doc: Document, number: string): void;
  staple(doc: Document): void;
}
```

### Exercise 5: Implement DIP
```javascript
// Refactor to use dependency injection
class UserController {
  constructor() {
    this.userService = new UserService();
    this.logger = new ConsoleLogger();
  }

  async getUser(id: string) {
    this.logger.log(`Fetching user ${id}`);
    return await this.userService.findById(id);
  }
}
```

---

## Summary

```
┌────────────────────────────────────────────────────────┐
│                  SOLID PRINCIPLES                      │
├────────────────────────────────────────────────────────┤
│                                                        │
│  S - Single Responsibility                             │
│      One class, one job, one reason to change          │
│                                                        │
│  O - Open/Closed                                       │
│      Open for extension, closed for modification       │
│                                                        │
│  L - Liskov Substitution                               │
│      Subclasses must be substitutable for base class   │
│                                                        │
│  I - Interface Segregation                             │
│      Many specific interfaces > one general interface  │
│                                                        │
│  D - Dependency Inversion                              │
│      Depend on abstractions, not implementations       │
│                                                        │
└────────────────────────────────────────────────────────┘
```

**Next**: Proceed to `design-patterns.md` to learn the 23 Gang of Four design patterns!

---

**Duration**: 40 hours
**Difficulty**: Intermediate
**Prerequisites**: OOP fundamentals
**Next Step**: Design Patterns (GoF)
