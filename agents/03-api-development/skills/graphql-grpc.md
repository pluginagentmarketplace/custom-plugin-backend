# GraphQL & gRPC: Comprehensive Guide

## Table of Contents
1. [GraphQL Overview](#graphql-overview)
2. [GraphQL Schema Design](#graphql-schema-design)
3. [Queries, Mutations & Subscriptions](#queries-mutations--subscriptions)
4. [The N+1 Problem & Solutions](#the-n1-problem--solutions)
5. [GraphQL Best Practices](#graphql-best-practices)
6. [gRPC Overview](#grpc-overview)
7. [Protocol Buffers](#protocol-buffers)
8. [gRPC Streaming Patterns](#grpc-streaming-patterns)
9. [gRPC Best Practices](#grpc-best-practices)
10. [Comparison: GraphQL vs gRPC vs REST](#comparison-graphql-vs-grpc-vs-rest)

---

## GraphQL Overview

GraphQL is a query language for APIs created by Facebook in 2012 and open-sourced in 2015. It allows clients to request exactly the data they need, giving them more flexibility and reducing over-fetching and under-fetching.

### Key Characteristics

**Client-Driven**: Clients specify exactly what data they need
**Single Endpoint**: All queries go to one endpoint (typically `/graphql`)
**Strongly Typed**: Schema defines all available types and operations
**Introspective**: Clients can query the schema itself
**Real-time**: Built-in support for subscriptions

### GraphQL vs REST

| Feature | GraphQL | REST |
|---------|---------|------|
| **Endpoints** | Single endpoint | Multiple endpoints |
| **Data Fetching** | Client specifies fields | Server determines response |
| **Over-fetching** | No - request only what you need | Yes - fixed response structure |
| **Under-fetching** | No - get related data in one request | Yes - multiple requests needed |
| **Versioning** | Usually not needed | Required for breaking changes |
| **Caching** | Complex (requires client caching) | Simple (HTTP caching) |
| **Learning Curve** | Steeper | Gentler |
| **Real-time** | Built-in (subscriptions) | Requires additional setup |

### When to Use GraphQL

✅ **Good Fits**:
- Complex, client-driven applications
- Mobile apps with bandwidth constraints
- Single Page Applications (SPAs)
- Aggregating data from multiple sources
- Applications requiring real-time updates
- Rapidly changing frontend requirements

❌ **Not Ideal For**:
- Simple CRUD APIs
- Public APIs (REST is more familiar)
- File uploads/downloads
- When HTTP caching is critical
- Small teams without GraphQL expertise

---

## GraphQL Schema Design

The schema is the heart of a GraphQL API. It defines types, queries, mutations, and subscriptions.

### Type System

#### Scalar Types

Built-in scalar types:

```graphql
# Built-in scalars
Int       # Signed 32-bit integer
Float     # Signed double-precision floating-point value
String    # UTF-8 character sequence
Boolean   # true or false
ID        # Unique identifier, serialized as String
```

Custom scalars:

```graphql
scalar DateTime
scalar Email
scalar URL
scalar JSON

# Usage
type User {
  id: ID!
  email: Email!
  createdAt: DateTime!
  metadata: JSON
}
```

#### Object Types

```graphql
type User {
  id: ID!
  name: String!
  email: String!
  age: Int
  isActive: Boolean!
  posts: [Post!]!
  profile: Profile
}

type Post {
  id: ID!
  title: String!
  content: String!
  published: Boolean!
  author: User!
  comments: [Comment!]!
  createdAt: DateTime!
}

type Comment {
  id: ID!
  text: String!
  author: User!
  post: Post!
  createdAt: DateTime!
}

type Profile {
  bio: String
  avatar: URL
  location: String
}
```

**Field Modifiers**:
- `String`: Nullable field
- `String!`: Non-null field (required)
- `[String]`: Array of nullable strings
- `[String]!`: Non-null array of nullable strings
- `[String!]!`: Non-null array of non-null strings

#### Enum Types

```graphql
enum Role {
  ADMIN
  EDITOR
  VIEWER
  GUEST
}

enum OrderStatus {
  PENDING
  PROCESSING
  SHIPPED
  DELIVERED
  CANCELLED
}

type User {
  id: ID!
  name: String!
  role: Role!
}
```

#### Interface Types

```graphql
interface Node {
  id: ID!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type User implements Node {
  id: ID!
  createdAt: DateTime!
  updatedAt: DateTime!
  name: String!
  email: String!
}

type Post implements Node {
  id: ID!
  createdAt: DateTime!
  updatedAt: DateTime!
  title: String!
  content: String!
}

# Query using interface
query {
  nodes {
    id
    createdAt
    ... on User {
      name
      email
    }
    ... on Post {
      title
      content
    }
  }
}
```

#### Union Types

```graphql
union SearchResult = User | Post | Comment

type Query {
  search(query: String!): [SearchResult!]!
}

# Query using union
query {
  search(query: "example") {
    ... on User {
      id
      name
      email
    }
    ... on Post {
      id
      title
      content
    }
    ... on Comment {
      id
      text
    }
  }
}
```

#### Input Types

```graphql
input CreateUserInput {
  name: String!
  email: String!
  age: Int
  role: Role = VIEWER  # Default value
}

input UpdateUserInput {
  name: String
  email: String
  age: Int
  role: Role
}

input PaginationInput {
  page: Int = 1
  limit: Int = 20
}

type Mutation {
  createUser(input: CreateUserInput!): User!
  updateUser(id: ID!, input: UpdateUserInput!): User!
}
```

### Complete Schema Example

```graphql
# Scalars
scalar DateTime
scalar Email

# Enums
enum Role {
  ADMIN
  EDITOR
  VIEWER
}

enum PostStatus {
  DRAFT
  PUBLISHED
  ARCHIVED
}

# Types
type User {
  id: ID!
  name: String!
  email: Email!
  role: Role!
  posts(status: PostStatus, limit: Int): [Post!]!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type Post {
  id: ID!
  title: String!
  content: String!
  status: PostStatus!
  author: User!
  comments: [Comment!]!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type Comment {
  id: ID!
  text: String!
  author: User!
  post: Post!
  createdAt: DateTime!
}

# Pagination types
type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}

type PostConnection {
  edges: [PostEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type PostEdge {
  node: Post!
  cursor: String!
}

# Input types
input CreateUserInput {
  name: String!
  email: Email!
  role: Role = VIEWER
}

input CreatePostInput {
  title: String!
  content: String!
  status: PostStatus = DRAFT
}

# Root types
type Query {
  user(id: ID!): User
  users(page: Int, limit: Int): [User!]!
  post(id: ID!): Post
  posts(
    first: Int
    after: String
    status: PostStatus
  ): PostConnection!
  me: User
}

type Mutation {
  createUser(input: CreateUserInput!): User!
  updateUser(id: ID!, input: UpdateUserInput!): User!
  deleteUser(id: ID!): Boolean!

  createPost(input: CreatePostInput!): Post!
  updatePost(id: ID!, input: UpdatePostInput!): Post!
  deletePost(id: ID!): Boolean!
  publishPost(id: ID!): Post!
}

type Subscription {
  postCreated: Post!
  postUpdated(id: ID!): Post!
  commentAdded(postId: ID!): Comment!
}
```

---

## Queries, Mutations & Subscriptions

### Queries (Read Operations)

Queries fetch data from the server.

#### Basic Query

```graphql
# Simple query
query {
  user(id: "123") {
    id
    name
    email
  }
}

# Response
{
  "data": {
    "user": {
      "id": "123",
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
}
```

#### Named Query with Variables

```graphql
# Query definition
query GetUser($userId: ID!) {
  user(id: $userId) {
    id
    name
    email
    role
  }
}

# Variables
{
  "userId": "123"
}
```

#### Nested Queries

```graphql
query {
  user(id: "123") {
    id
    name
    email
    posts {
      id
      title
      comments {
        id
        text
        author {
          id
          name
        }
      }
    }
  }
}
```

#### Multiple Queries

```graphql
query {
  user1: user(id: "123") {
    id
    name
  }
  user2: user(id: "456") {
    id
    name
  }
  allPosts: posts {
    id
    title
  }
}
```

#### Query with Arguments and Filters

```graphql
query {
  posts(
    status: PUBLISHED
    first: 10
    orderBy: { field: CREATED_AT, direction: DESC }
  ) {
    edges {
      node {
        id
        title
        author {
          name
        }
      }
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

### Mutations (Write Operations)

Mutations modify server-side data.

#### Create Mutation

```graphql
mutation {
  createUser(input: {
    name: "Jane Smith"
    email: "jane@example.com"
    role: EDITOR
  }) {
    id
    name
    email
    role
    createdAt
  }
}

# Response
{
  "data": {
    "createUser": {
      "id": "124",
      "name": "Jane Smith",
      "email": "jane@example.com",
      "role": "EDITOR",
      "createdAt": "2025-01-15T10:30:00Z"
    }
  }
}
```

#### Update Mutation

```graphql
mutation UpdateUser($id: ID!, $input: UpdateUserInput!) {
  updateUser(id: $id, input: $input) {
    id
    name
    email
    updatedAt
  }
}

# Variables
{
  "id": "123",
  "input": {
    "name": "John Updated",
    "role": "ADMIN"
  }
}
```

#### Delete Mutation

```graphql
mutation {
  deleteUser(id: "123")
}

# Response
{
  "data": {
    "deleteUser": true
  }
}
```

#### Multiple Mutations (Sequential)

```graphql
# Mutations execute sequentially in order
mutation {
  createPost(input: {
    title: "New Post"
    content: "Content here"
  }) {
    id
  }
  createComment(input: {
    postId: "456"
    text: "Great post!"
  }) {
    id
  }
}
```

### Subscriptions (Real-time Updates)

Subscriptions enable real-time push updates using WebSockets.

#### Basic Subscription

```graphql
subscription {
  postCreated {
    id
    title
    author {
      name
    }
    createdAt
  }
}

# Server pushes data when new post is created
{
  "data": {
    "postCreated": {
      "id": "789",
      "title": "Breaking News",
      "author": {
        "name": "John Doe"
      },
      "createdAt": "2025-01-15T10:35:00Z"
    }
  }
}
```

#### Subscription with Arguments

```graphql
subscription OnCommentAdded($postId: ID!) {
  commentAdded(postId: $postId) {
    id
    text
    author {
      name
    }
    createdAt
  }
}

# Variables
{
  "postId": "456"
}
```

#### Implementation Example (Node.js with Apollo Server)

```javascript
// Server-side resolver
const { PubSub } = require('graphql-subscriptions');
const pubsub = new PubSub();

const resolvers = {
  Mutation: {
    createPost: async (parent, { input }, context) => {
      const post = await createPost(input);

      // Publish event for subscription
      pubsub.publish('POST_CREATED', {
        postCreated: post
      });

      return post;
    }
  },

  Subscription: {
    postCreated: {
      subscribe: () => pubsub.asyncIterator(['POST_CREATED'])
    },

    commentAdded: {
      subscribe: (parent, { postId }) => {
        return pubsub.asyncIterator([`COMMENT_ADDED_${postId}`]);
      }
    }
  }
};

// Client-side subscription (Apollo Client)
const COMMENT_SUBSCRIPTION = gql`
  subscription OnCommentAdded($postId: ID!) {
    commentAdded(postId: $postId) {
      id
      text
      author {
        name
      }
    }
  }
`;

function Comments({ postId }) {
  const { data, loading } = useSubscription(
    COMMENT_SUBSCRIPTION,
    { variables: { postId } }
  );

  if (loading) return <p>Loading...</p>;

  return <div>{data.commentAdded.text}</div>;
}
```

### Fragments

Fragments are reusable units of query logic.

```graphql
# Define fragment
fragment UserFields on User {
  id
  name
  email
  role
}

# Use fragment
query {
  user(id: "123") {
    ...UserFields
    posts {
      id
      title
      author {
        ...UserFields
      }
    }
  }
}

# Inline fragments for unions/interfaces
query {
  search(query: "example") {
    ... on User {
      id
      name
      email
    }
    ... on Post {
      id
      title
      content
    }
  }
}
```

### Directives

Directives modify query execution.

```graphql
# @include directive
query GetUser($userId: ID!, $includeEmail: Boolean!) {
  user(id: $userId) {
    id
    name
    email @include(if: $includeEmail)
  }
}

# @skip directive
query GetUser($userId: ID!, $skipPosts: Boolean!) {
  user(id: $userId) {
    id
    name
    posts @skip(if: $skipPosts) {
      id
      title
    }
  }
}

# @deprecated directive (schema)
type User {
  id: ID!
  name: String!
  username: String @deprecated(reason: "Use `name` instead")
}

# Custom directives
directive @auth(requires: Role = VIEWER) on FIELD_DEFINITION

type Query {
  adminData: AdminData @auth(requires: ADMIN)
  userData: UserData @auth(requires: VIEWER)
}
```

---

## The N+1 Problem & Solutions

### Understanding the N+1 Problem

The N+1 problem occurs when GraphQL executes separate resolver functions for every field, making more database queries than necessary.

**Example Scenario**:
```graphql
query {
  posts {           # 1 query to get all posts
    id
    title
    author {        # N queries (one per post)
      id
      name
    }
  }
}
```

**Database Queries**:
```sql
-- 1 query for posts
SELECT * FROM posts LIMIT 10;

-- N queries for authors (10 separate queries)
SELECT * FROM users WHERE id = 1;
SELECT * FROM users WHERE id = 2;
SELECT * FROM users WHERE id = 1;  -- Duplicate!
SELECT * FROM users WHERE id = 3;
-- ... 10 total queries
```

**Total**: 1 + 10 = **11 database queries** for 10 posts

### Solution 1: DataLoader

DataLoader is a utility library that batches and caches data loading.

#### How DataLoader Works

1. **Batching**: Groups multiple `load(key)` calls into single `batchLoadFn(keys)` call
2. **Caching**: Stores results within request to avoid duplicate lookups
3. **Per-Request**: Create new DataLoader instance per request

#### Implementation

```javascript
const DataLoader = require('dataloader');

// Create batch load function
const batchUsers = async (userIds) => {
  // Single database query for all users
  const users = await db.query(
    'SELECT * FROM users WHERE id = ANY($1)',
    [userIds]
  );

  // Return users in same order as userIds
  const userMap = new Map(users.map(u => [u.id, u]));
  return userIds.map(id => userMap.get(id));
};

// Create DataLoader instance
const userLoader = new DataLoader(batchUsers);

// Resolvers
const resolvers = {
  Query: {
    posts: async () => {
      return await db.query('SELECT * FROM posts LIMIT 10');
    }
  },

  Post: {
    author: async (post, args, context) => {
      // DataLoader batches these calls
      return await context.userLoader.load(post.authorId);
    }
  }
};

// Context creation (per request)
const server = new ApolloServer({
  typeDefs,
  resolvers,
  context: () => ({
    userLoader: new DataLoader(batchUsers)
  })
});
```

**Result**: 1 query for posts + 1 batched query for authors = **2 total queries**

#### DataLoader with Caching

```javascript
// First call
await userLoader.load(1);  // Query database

// Second call (within same request)
await userLoader.load(1);  // Return from cache, no query

// Clear cache if needed
userLoader.clear(1);
```

#### Advanced DataLoader Example

```javascript
// User loader
const userLoader = new DataLoader(async (userIds) => {
  const users = await db.users.findMany({
    where: { id: { in: userIds } }
  });
  return userIds.map(id => users.find(u => u.id === id));
});

// Post loader
const postLoader = new DataLoader(async (postIds) => {
  const posts = await db.posts.findMany({
    where: { id: { in: postIds } }
  });
  return postIds.map(id => posts.find(p => p.id === id));
});

// Posts by user loader (one-to-many)
const postsByUserLoader = new DataLoader(async (userIds) => {
  const posts = await db.posts.findMany({
    where: { authorId: { in: userIds } }
  });

  // Group posts by authorId
  const postsByUser = userIds.map(userId =>
    posts.filter(p => p.authorId === userId)
  );

  return postsByUser;
});

// Context
const context = () => ({
  loaders: {
    user: userLoader,
    post: postLoader,
    postsByUser: postsByUserLoader
  }
});

// Resolvers
const resolvers = {
  User: {
    posts: (user, args, context) => {
      return context.loaders.postsByUser.load(user.id);
    }
  },

  Post: {
    author: (post, args, context) => {
      return context.loaders.user.load(post.authorId);
    }
  }
};
```

### Solution 2: Query Optimization

#### Join Query Approach

```javascript
// Instead of separate queries
const posts = await db.query('SELECT * FROM posts');
for (const post of posts) {
  post.author = await db.query('SELECT * FROM users WHERE id = $1', [post.authorId]);
}

// Use JOIN
const postsWithAuthors = await db.query(`
  SELECT
    posts.*,
    users.id as author_id,
    users.name as author_name,
    users.email as author_email
  FROM posts
  LEFT JOIN users ON posts.author_id = users.id
`);
```

### Solution 3: Field-Level Resolver Planning

```javascript
// Use GraphQL execution info to plan queries
const resolvers = {
  Query: {
    posts: async (parent, args, context, info) => {
      // Check if author field is requested
      const includeAuthor = hasField(info, 'author');

      if (includeAuthor) {
        // Use JOIN query
        return await db.getPostsWithAuthors();
      } else {
        // Simple query without JOIN
        return await db.getPosts();
      }
    }
  }
};

// Helper function
function hasField(info, fieldName) {
  return info.fieldNodes[0].selectionSet.selections
    .some(field => field.name.value === fieldName);
}
```

### DataLoader 3.0 Improvements

DataLoader 3.0 (released 2024) uses **breadth-first loading** to reduce concurrency:

**Before (Depth-First)**:
```
Load posts → Load authors → Load author's posts → Load author's comments
  ↓            ↓              ↓                      ↓
Sequential execution, O(N²) concurrency
```

**After (Breadth-First)**:
```
Load all posts → Load all authors → Load all posts → Load all comments
     ↓               ↓                  ↓               ↓
Batch execution, O(1) concurrency, 5x faster
```

---

## GraphQL Best Practices

### Schema Design

```graphql
# ✅ Good: Descriptive names
type User {
  id: ID!
  fullName: String!
  emailAddress: String!
}

# ❌ Bad: Ambiguous names
type User {
  id: ID!
  name: String!
  email: String!
}

# ✅ Good: Use enums for fixed sets
enum OrderStatus {
  PENDING
  PROCESSING
  SHIPPED
  DELIVERED
}

# ❌ Bad: Use strings
type Order {
  status: String!  # What are valid values?
}

# ✅ Good: Use connections for pagination
type PostConnection {
  edges: [PostEdge!]!
  pageInfo: PageInfo!
}

# ❌ Bad: Return plain arrays
type Query {
  posts: [Post!]!  # No pagination info
}
```

### Error Handling

```javascript
// Custom error classes
class NotFoundError extends Error {
  constructor(message) {
    super(message);
    this.extensions = {
      code: 'NOT_FOUND',
      http: { status: 404 }
    };
  }
}

class ValidationError extends Error {
  constructor(message, fields) {
    super(message);
    this.extensions = {
      code: 'VALIDATION_ERROR',
      fields,
      http: { status: 400 }
    };
  }
}

// Resolver with error handling
const resolvers = {
  Query: {
    user: async (parent, { id }) => {
      const user = await db.users.findUnique({ where: { id } });

      if (!user) {
        throw new NotFoundError(`User ${id} not found`);
      }

      return user;
    }
  },

  Mutation: {
    createUser: async (parent, { input }) => {
      // Validation
      if (!isValidEmail(input.email)) {
        throw new ValidationError('Invalid input', {
          email: 'Invalid email format'
        });
      }

      return await db.users.create({ data: input });
    }
  }
};

// Error response
{
  "errors": [
    {
      "message": "User 123 not found",
      "extensions": {
        "code": "NOT_FOUND",
        "http": {
          "status": 404
        }
      },
      "path": ["user"]
    }
  ],
  "data": {
    "user": null
  }
}
```

### Security

#### Query Complexity Analysis

```javascript
const { createComplexityLimitRule } = require('graphql-validation-complexity');

const server = new ApolloServer({
  typeDefs,
  resolvers,
  validationRules: [
    createComplexityLimitRule(1000, {
      onCost: (cost) => {
        console.log('Query cost:', cost);
      }
    })
  ]
});
```

#### Query Depth Limiting

```javascript
const depthLimit = require('graphql-depth-limit');

const server = new ApolloServer({
  typeDefs,
  resolvers,
  validationRules: [depthLimit(5)]
});
```

#### Disable Introspection in Production

```javascript
const server = new ApolloServer({
  typeDefs,
  resolvers,
  introspection: process.env.NODE_ENV !== 'production',
  playground: process.env.NODE_ENV !== 'production'
});
```

#### Rate Limiting

```javascript
const { RateLimitDirective } = require('graphql-rate-limit-directive');

const typeDefs = gql`
  directive @rateLimit(
    limit: Int!
    duration: Int!
  ) on FIELD_DEFINITION

  type Query {
    expensiveOperation: Data @rateLimit(limit: 5, duration: 60)
  }
`;
```

### Performance Optimization

#### Persisted Queries

```javascript
// Client sends query hash
{
  "extensions": {
    "persistedQuery": {
      "version": 1,
      "sha256Hash": "abc123..."
    }
  }
}

// Server configuration
const server = new ApolloServer({
  typeDefs,
  resolvers,
  persistedQueries: {
    cache: new InMemoryLRUCache()
  }
});
```

#### Field-Level Caching

```javascript
const responseCachePlugin = require('apollo-server-plugin-response-cache');

const server = new ApolloServer({
  typeDefs,
  resolvers,
  plugins: [responseCachePlugin()],
  cacheControl: {
    defaultMaxAge: 5
  }
});

// In schema
type Query {
  user(id: ID!): User @cacheControl(maxAge: 60)
  posts: [Post!]! @cacheControl(maxAge: 30)
}
```

---

## gRPC Overview

gRPC is a high-performance RPC (Remote Procedure Call) framework developed by Google that uses HTTP/2 for transport and Protocol Buffers for serialization.

### Key Features

- **High Performance**: Binary protocol reduces payload by 30-50% vs JSON
- **Streaming**: Built-in support for bidirectional streaming
- **Code Generation**: Auto-generate client/server code
- **Multi-Language**: Support for 11+ languages
- **HTTP/2**: Multiplexing, header compression, flow control

### When to Use gRPC

✅ **Good Fits**:
- Microservices communication
- Real-time data transfer
- High-performance systems
- Internal APIs
- IoT applications
- Mobile to backend communication
- Polyglot environments

❌ **Not Ideal For**:
- Browser-based clients (requires grpc-web)
- Public APIs (less familiar than REST)
- Simple CRUD operations
- When human-readable format needed

---

## Protocol Buffers

Protocol Buffers (protobuf) is a language-neutral, platform-neutral mechanism for serializing structured data.

### Basic Syntax

```protobuf
syntax = "proto3";

package example;

// Message definition
message User {
  int32 id = 1;
  string name = 2;
  string email = 3;
  repeated string roles = 4;
  optional string phone = 5;
}

// Nested message
message Address {
  string street = 1;
  string city = 2;
  string state = 3;
  string zip = 4;
}

message UserProfile {
  User user = 1;
  Address address = 2;
  int64 created_at = 3;
}
```

### Scalar Types

```protobuf
message DataTypes {
  // Numeric
  double price = 1;          // 64-bit float
  float rating = 2;          // 32-bit float
  int32 count = 3;           // 32-bit signed
  int64 bigCount = 4;        // 64-bit signed
  uint32 unsignedCount = 5;  // 32-bit unsigned
  uint64 bigUnsigned = 6;    // 64-bit unsigned

  // Boolean
  bool isActive = 7;

  // String and bytes
  string name = 8;
  bytes data = 9;
}
```

### Enums

```protobuf
enum Role {
  UNKNOWN = 0;  // First value must be 0
  ADMIN = 1;
  EDITOR = 2;
  VIEWER = 3;
}

message User {
  int32 id = 1;
  string name = 2;
  Role role = 3;
}
```

### Repeated Fields (Arrays)

```protobuf
message User {
  int32 id = 1;
  string name = 2;
  repeated string emails = 3;      // Array of strings
  repeated Role roles = 4;         // Array of enums
  repeated Address addresses = 5;  // Array of messages
}
```

### Maps

```protobuf
message User {
  int32 id = 1;
  string name = 2;
  map<string, string> metadata = 3;
  map<int32, Address> addresses = 4;
}
```

### Oneof (Union Types)

```protobuf
message Response {
  oneof result {
    User user = 1;
    Error error = 2;
  }
}

message Error {
  int32 code = 1;
  string message = 2;
}
```

### Service Definitions

```protobuf
syntax = "proto3";

package user;

// Service definition
service UserService {
  // Unary RPC
  rpc GetUser(GetUserRequest) returns (GetUserResponse);

  // Server streaming
  rpc ListUsers(ListUsersRequest) returns (stream User);

  // Client streaming
  rpc CreateUsers(stream CreateUserRequest) returns (CreateUsersResponse);

  // Bidirectional streaming
  rpc Chat(stream ChatMessage) returns (stream ChatMessage);
}

// Request/Response messages
message GetUserRequest {
  int32 id = 1;
}

message GetUserResponse {
  User user = 1;
  Error error = 2;
}

message ListUsersRequest {
  int32 page = 1;
  int32 limit = 2;
}

message CreateUserRequest {
  string name = 1;
  string email = 2;
}

message CreateUsersResponse {
  repeated User users = 1;
  int32 created_count = 2;
}

message ChatMessage {
  string user_id = 1;
  string message = 2;
  int64 timestamp = 3;
}
```

### Complete Example

```protobuf
syntax = "proto3";

package ecommerce;

option go_package = "github.com/example/ecommerce";

import "google/protobuf/timestamp.proto";

// Enums
enum OrderStatus {
  PENDING = 0;
  PROCESSING = 1;
  SHIPPED = 2;
  DELIVERED = 3;
  CANCELLED = 4;
}

// Messages
message Product {
  int32 id = 1;
  string name = 2;
  string description = 3;
  double price = 4;
  int32 stock = 5;
  repeated string images = 6;
  map<string, string> metadata = 7;
}

message OrderItem {
  int32 product_id = 1;
  int32 quantity = 2;
  double price = 3;
}

message Order {
  int32 id = 1;
  int32 customer_id = 2;
  repeated OrderItem items = 3;
  double total = 4;
  OrderStatus status = 5;
  google.protobuf.Timestamp created_at = 6;
  google.protobuf.Timestamp updated_at = 7;
}

// Requests/Responses
message CreateOrderRequest {
  int32 customer_id = 1;
  repeated OrderItem items = 2;
}

message CreateOrderResponse {
  Order order = 1;
  string error = 2;
}

message GetOrderRequest {
  int32 id = 1;
}

message GetOrderResponse {
  Order order = 1;
}

message ListOrdersRequest {
  int32 customer_id = 1;
  OrderStatus status = 2;
  int32 page = 3;
  int32 limit = 4;
}

message ListOrdersResponse {
  repeated Order orders = 1;
  int32 total = 2;
}

// Service
service OrderService {
  rpc CreateOrder(CreateOrderRequest) returns (CreateOrderResponse);
  rpc GetOrder(GetOrderRequest) returns (GetOrderResponse);
  rpc ListOrders(ListOrdersRequest) returns (stream Order);
  rpc UpdateOrderStatus(UpdateOrderStatusRequest) returns (UpdateOrderStatusResponse);
  rpc CancelOrder(CancelOrderRequest) returns (CancelOrderResponse);
}
```

### Code Generation

```bash
# Install protoc compiler
# Install language-specific plugin

# Generate code
protoc --go_out=. --go-grpc_out=. user.proto
protoc --python_out=. --python-grpc_out=. user.proto
protoc --js_out=. --grpc-web_out=. user.proto
```

---

## gRPC Streaming Patterns

gRPC supports four types of service methods.

### 1. Unary RPC (Request-Response)

Single request, single response (like traditional RPC).

```protobuf
service UserService {
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
}
```

**Server Implementation (Go)**:
```go
func (s *server) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.GetUserResponse, error) {
  user, err := db.GetUser(req.Id)
  if err != nil {
    return nil, status.Errorf(codes.NotFound, "User not found")
  }

  return &pb.GetUserResponse{
    User: user,
  }, nil
}
```

**Client Implementation**:
```go
resp, err := client.GetUser(ctx, &pb.GetUserRequest{Id: 123})
if err != nil {
  log.Fatal(err)
}
fmt.Println(resp.User)
```

### 2. Server Streaming RPC

Single request, stream of responses.

```protobuf
service UserService {
  rpc ListUsers(ListUsersRequest) returns (stream User);
}
```

**Server Implementation**:
```go
func (s *server) ListUsers(req *pb.ListUsersRequest, stream pb.UserService_ListUsersServer) error {
  users, err := db.GetAllUsers()
  if err != nil {
    return err
  }

  for _, user := range users {
    if err := stream.Send(user); err != nil {
      return err
    }
  }

  return nil
}
```

**Client Implementation**:
```go
stream, err := client.ListUsers(ctx, &pb.ListUsersRequest{})
if err != nil {
  log.Fatal(err)
}

for {
  user, err := stream.Recv()
  if err == io.EOF {
    break
  }
  if err != nil {
    log.Fatal(err)
  }
  fmt.Println(user)
}
```

**Use Cases**:
- Large result sets
- Real-time updates
- Log streaming
- File downloads

### 3. Client Streaming RPC

Stream of requests, single response.

```protobuf
service UserService {
  rpc CreateUsers(stream CreateUserRequest) returns (CreateUsersResponse);
}
```

**Server Implementation**:
```go
func (s *server) CreateUsers(stream pb.UserService_CreateUsersServer) error {
  var users []*pb.User

  for {
    req, err := stream.Recv()
    if err == io.EOF {
      // All data received, send response
      return stream.SendAndClose(&pb.CreateUsersResponse{
        Users: users,
        CreatedCount: int32(len(users)),
      })
    }
    if err != nil {
      return err
    }

    user, err := db.CreateUser(req)
    if err != nil {
      return err
    }
    users = append(users, user)
  }
}
```

**Client Implementation**:
```go
stream, err := client.CreateUsers(ctx)
if err != nil {
  log.Fatal(err)
}

users := []string{"Alice", "Bob", "Charlie"}
for _, name := range users {
  if err := stream.Send(&pb.CreateUserRequest{Name: name}); err != nil {
    log.Fatal(err)
  }
}

resp, err := stream.CloseAndRecv()
if err != nil {
  log.Fatal(err)
}
fmt.Printf("Created %d users\n", resp.CreatedCount)
```

**Use Cases**:
- Bulk uploads
- Aggregation
- File uploads
- Batch processing

### 4. Bidirectional Streaming RPC

Stream of requests, stream of responses.

```protobuf
service ChatService {
  rpc Chat(stream ChatMessage) returns (stream ChatMessage);
}
```

**Server Implementation**:
```go
func (s *server) Chat(stream pb.ChatService_ChatServer) error {
  for {
    msg, err := stream.Recv()
    if err == io.EOF {
      return nil
    }
    if err != nil {
      return err
    }

    // Process message
    fmt.Printf("Received: %s\n", msg.Message)

    // Send response
    response := &pb.ChatMessage{
      UserId: "server",
      Message: fmt.Sprintf("Echo: %s", msg.Message),
      Timestamp: time.Now().Unix(),
    }

    if err := stream.Send(response); err != nil {
      return err
    }
  }
}
```

**Client Implementation**:
```go
stream, err := client.Chat(ctx)
if err != nil {
  log.Fatal(err)
}

// Goroutine to receive messages
go func() {
  for {
    msg, err := stream.Recv()
    if err == io.EOF {
      return
    }
    if err != nil {
      log.Fatal(err)
    }
    fmt.Printf("Received: %s\n", msg.Message)
  }
}()

// Send messages
messages := []string{"Hello", "How are you?", "Goodbye"}
for _, text := range messages {
  if err := stream.Send(&pb.ChatMessage{
    UserId: "client",
    Message: text,
    Timestamp: time.Now().Unix(),
  }); err != nil {
    log.Fatal(err)
  }
  time.Sleep(time.Second)
}

stream.CloseSend()
```

**Use Cases**:
- Real-time chat
- Live collaboration
- Gaming
- IoT data exchange

---

## gRPC Best Practices

### 1. Error Handling

```go
import "google.golang.org/grpc/codes"
import "google.golang.org/grpc/status"

// Return structured errors
func (s *server) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.GetUserResponse, error) {
  if req.Id <= 0 {
    return nil, status.Error(codes.InvalidArgument, "ID must be positive")
  }

  user, err := db.GetUser(req.Id)
  if err == sql.ErrNoRows {
    return nil, status.Error(codes.NotFound, "User not found")
  }
  if err != nil {
    return nil, status.Error(codes.Internal, "Internal server error")
  }

  return &pb.GetUserResponse{User: user}, nil
}

// Client error handling
resp, err := client.GetUser(ctx, req)
if err != nil {
  st, ok := status.FromError(err)
  if ok {
    fmt.Printf("Error code: %s\n", st.Code())
    fmt.Printf("Error message: %s\n", st.Message())
  }
}
```

**gRPC Status Codes**:
- `OK`: Success
- `CANCELLED`: Operation cancelled
- `INVALID_ARGUMENT`: Invalid argument
- `NOT_FOUND`: Resource not found
- `ALREADY_EXISTS`: Resource already exists
- `PERMISSION_DENIED`: Permission denied
- `UNAUTHENTICATED`: Authentication required
- `RESOURCE_EXHAUSTED`: Rate limit exceeded
- `INTERNAL`: Internal server error
- `UNAVAILABLE`: Service unavailable

### 2. Timeouts and Deadlines

```go
// Server-side deadline check
func (s *server) SlowOperation(ctx context.Context, req *pb.Request) (*pb.Response, error) {
  // Check if deadline exceeded
  if ctx.Err() == context.DeadlineExceeded {
    return nil, status.Error(codes.DeadlineExceeded, "Operation timed out")
  }

  // Perform operation
  result, err := expensiveOperation(ctx)
  if err != nil {
    return nil, err
  }

  return &pb.Response{Result: result}, nil
}

// Client-side timeout
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()

resp, err := client.SlowOperation(ctx, req)
if err != nil {
  if status.Code(err) == codes.DeadlineExceeded {
    fmt.Println("Request timed out")
  }
}
```

### 3. Metadata (Headers)

```go
import "google.golang.org/grpc/metadata"

// Client sends metadata
md := metadata.Pairs(
  "authorization", "Bearer token123",
  "request-id", "abc-123",
)
ctx := metadata.NewOutgoingContext(context.Background(), md)

resp, err := client.GetUser(ctx, req)

// Server receives metadata
func (s *server) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.GetUserResponse, error) {
  md, ok := metadata.FromIncomingContext(ctx)
  if !ok {
    return nil, status.Error(codes.Internal, "No metadata")
  }

  auth := md.Get("authorization")
  if len(auth) == 0 {
    return nil, status.Error(codes.Unauthenticated, "No auth token")
  }

  // Validate token
  // ...
}

// Server sends metadata
md := metadata.Pairs("response-id", "xyz-789")
grpc.SendHeader(ctx, md)
```

### 4. Interceptors (Middleware)

```go
// Unary interceptor
func unaryInterceptor(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
  // Pre-processing
  start := time.Now()
  fmt.Printf("Request: %s\n", info.FullMethod)

  // Call handler
  resp, err := handler(ctx, req)

  // Post-processing
  fmt.Printf("Duration: %v\n", time.Since(start))

  return resp, err
}

// Server with interceptor
server := grpc.NewServer(
  grpc.UnaryInterceptor(unaryInterceptor),
)

// Stream interceptor
func streamInterceptor(srv interface{}, ss grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
  fmt.Printf("Stream: %s\n", info.FullMethod)
  return handler(srv, ss)
}

server := grpc.NewServer(
  grpc.StreamInterceptor(streamInterceptor),
)
```

### 5. Health Checking

```protobuf
syntax = "proto3";

package grpc.health.v1;

service Health {
  rpc Check(HealthCheckRequest) returns (HealthCheckResponse);
  rpc Watch(HealthCheckRequest) returns (stream HealthCheckResponse);
}

message HealthCheckRequest {
  string service = 1;
}

message HealthCheckResponse {
  enum ServingStatus {
    UNKNOWN = 0;
    SERVING = 1;
    NOT_SERVING = 2;
  }
  ServingStatus status = 1;
}
```

### 6. Versioning

```protobuf
// Option 1: Package versioning
syntax = "proto3";
package user.v1;

service UserService {
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
}

// Version 2
package user.v2;

service UserService {
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
  rpc GetUserProfile(GetUserProfileRequest) returns (GetUserProfileResponse);
}

// Option 2: Method versioning
service UserService {
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
  rpc GetUserV2(GetUserRequestV2) returns (GetUserResponseV2);
}
```

---

## Comparison: GraphQL vs gRPC vs REST

| Feature | REST | GraphQL | gRPC |
|---------|------|---------|------|
| **Protocol** | HTTP/1.1 | HTTP | HTTP/2 |
| **Format** | JSON/XML | JSON | Protocol Buffers (binary) |
| **Endpoints** | Multiple | Single | Multiple (services) |
| **Over-fetching** | Common | No | No |
| **Under-fetching** | Common | No | No |
| **Type Safety** | No (unless OpenAPI) | Yes | Yes |
| **Code Generation** | Optional | Optional | Built-in |
| **Real-time** | Requires WebSockets | Built-in (subscriptions) | Built-in (streaming) |
| **Caching** | Excellent (HTTP) | Complex | Not built-in |
| **Browser Support** | Native | Native | Requires grpc-web |
| **Learning Curve** | Low | Medium | High |
| **Performance** | Good | Good | Excellent |
| **Human Readable** | Yes | Yes | No (binary) |
| **Best For** | Public APIs, CRUD | Complex queries, SPAs | Microservices, high-performance |

### When to Choose What

**Choose REST when**:
- Building public-facing APIs
- Simple CRUD operations
- HTTP caching is important
- Wide client compatibility needed
- Team unfamiliar with alternatives

**Choose GraphQL when**:
- Complex, nested data requirements
- Mobile apps with bandwidth constraints
- Frontend-driven development
- Aggregating multiple data sources
- Real-time updates needed
- Rapid iteration on data requirements

**Choose gRPC when**:
- Internal microservices communication
- High-performance requirements
- Streaming data (real-time, IoT)
- Polyglot environments
- Strong typing required
- Not browser-facing

### Hybrid Approach

Many organizations use multiple:

```
Mobile App ←→ GraphQL API ←→ gRPC Services ←→ Databases
Public Web ←→ REST API ←→ gRPC Services ←→ Databases
```

## Summary

✅ **GraphQL** provides flexible, client-driven APIs with strong typing
✅ **gRPC** offers high-performance, streaming-capable RPC framework
✅ Use **DataLoader** to solve N+1 problem in GraphQL
✅ **Protocol Buffers** provide efficient, language-neutral serialization
✅ Choose paradigm based on use case, not trends
✅ Consider hybrid approach for complex systems

Both GraphQL and gRPC are powerful alternatives to REST, each with specific strengths. Understanding when to use each is crucial for building efficient, scalable APIs.
