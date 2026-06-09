# Practice Problems: Services Layer & Business Logic

---

## Problem 1: Service Layer with Business Validation ⭐ Easy

**Objective**: Build a console app that demonstrates the service layer pattern with input validation vs business validation.

### Requirements:
1. Create a `ProductService` with full CRUD that calls `ProductRepository`
2. Implement input validation (required, range, string length) in DTOs
3. Implement business validation in the service: duplicate names, category exists, minimum price rules
4. Show thin controller that delegates all logic to the service
5. Process 6+ operations showing both passing and failing validations

### Expected Output:
```
=== Service Layer ===

▶ Create Product: { Name: "Laptop", Price: 999.99, CategoryId: 1 }
  [Input Validation] ✓ Passed
  [Business Validation] ✓ Name is unique, Category exists
  [Service] Product #1 created
  ← 201 Created

▶ Create Product: { Name: "Laptop", Price: 500 }  (duplicate)
  [Input Validation] ✓ Passed
  [Business Validation] ✗ Product 'Laptop' already exists
  ← 409 Conflict

▶ Create Product: { Name: "", Price: -5 }
  [Input Validation] ✗ Name is required, Price must be > 0
  ← 400 Bad Request (service never called!)
```

---

## Problem 2: Order Processing Service ⭐⭐ Easy-Medium

**Objective**: Build a console app that implements complex order processing business logic with stock management and pricing rules.

### Requirements:
1. Implement order creation with: customer validation, product lookup, stock checking
2. Business rules: stock deduction, discount calculation (5% over $500, 10% over $1000), tax (8%)
3. Use Unit of Work for atomic operations (order + stock updates)
4. Process 4 orders: successful, insufficient stock, invalid customer, minimum amount violation
5. Show running stock levels before and after orders

---

## Problem 3: Result Pattern Implementation ⭐⭐ Medium

**Objective**: Build a console app that implements the Result<T> pattern for elegant error handling without exceptions.

### Requirements:
1. Create `Result<T>` with: IsSuccess, Value, Error, StatusCode
2. Static factory methods: Success, NotFound, BadRequest, Conflict, Forbidden
3. Implement `Map()`, `Bind()` for chaining results (Railway-oriented programming)
4. Rewrite a ProductService using Results instead of exceptions
5. Show controller converting Results to HTTP responses
6. Chain multiple operations that can fail at any step

---

## Problem 4: E-Commerce Business Rules Engine ⭐⭐ Medium-Hard

**Objective**: Build a console app that implements a complete e-commerce service layer with complex interconnected business rules.

### Requirements:
1. **Product Service**: CRUD + business rules (pricing tiers, category restrictions)
2. **Customer Service**: Registration, loyalty points, tier upgrades (Bronze→Silver→Gold)
3. **Order Service**: Complex order with discounts, loyalty points, shipping calculation
4. **Business Rules**:
   - Loyalty points: 1 point per $10 spent
   - Gold customers get 15% discount, Silver 10%, Bronze 5%
   - Free shipping over $100
   - Max 10 items per order
   - Products can't be ordered if discontinued
5. Process a full customer lifecycle: register → browse → order → accumulate points → upgrade tier

---

## Problem 5: Multi-Service Orchestration ⭐⭐⭐ Hard

**Objective**: Build a console app that demonstrates service orchestration where multiple services coordinate to complete a complex business workflow.

### Requirements:
1. **Services**: OrderService, InventoryService, PaymentService, NotificationService, ShippingService
2. **Workflow**: CreateOrder → ValidateInventory → ProcessPayment → UpdateInventory → CreateShipment → SendNotifications
3. Implement compensation/rollback when a step fails:
   - Payment fails → release inventory hold
   - Shipping fails → refund payment + release inventory
4. Use Result pattern for each step to chain operations
5. Process 3 scenarios: full success, payment failure (rollback), shipping failure (full compensation)

### Expected Output:
```
=== Multi-Service Orchestration ===

━━━ Scenario 1: Success ━━━
[OrderService] Order #1 created → ✓
[InventoryService] Stock reserved: Laptop×2, Mouse×1 → ✓
[PaymentService] Charged $2,029.97 to card ***1234 → ✓
[InventoryService] Stock deducted → ✓
[ShippingService] Shipment #SH001 created, ETA: 3-5 days → ✓
[NotificationService] Confirmation email sent to john@co.com → ✓
Result: ORDER COMPLETED ✓

━━━ Scenario 2: Payment Failure ━━━
[OrderService] Order #2 created → ✓
[InventoryService] Stock reserved → ✓
[PaymentService] ✗ Card declined!
  [COMPENSATE] InventoryService: Stock released → ✓
  [COMPENSATE] OrderService: Order #2 cancelled → ✓
Result: ORDER FAILED — Payment declined ✗

━━━ Scenario 3: Shipping Failure ━━━
[OrderService] Order #3 created → ✓
[InventoryService] Stock reserved → ✓
[PaymentService] Charged $150.00 → ✓
[InventoryService] Stock deducted → ✓
[ShippingService] ✗ Address invalid!
  [COMPENSATE] PaymentService: Refunded $150.00 → ✓
  [COMPENSATE] InventoryService: Stock restored → ✓
  [COMPENSATE] OrderService: Order #3 cancelled → ✓
  [NotificationService] Failure notification sent → ✓
Result: ORDER FAILED — Shipping error, refund processed ✗
```
