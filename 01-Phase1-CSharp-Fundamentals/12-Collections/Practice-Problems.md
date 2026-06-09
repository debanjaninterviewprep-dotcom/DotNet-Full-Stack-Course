# Topic 12: Collections — Practice Problems

## Problem 1: Contact Manager with List (Easy)
**Concept**: List\<T\> operations — Add, Remove, Search, Sort

Build a console contact manager using `List<string>`:

1. **Add Contact** — adds a name (no duplicates allowed — check with `Contains`)
2. **Remove Contact** — by name
3. **Search Contact** — partial name search (case-insensitive)
4. **Show All Contacts** — sorted alphabetically with numbering
5. **Contact Count** — display total count

Menu-driven with loop until user exits.

**Expected Output:**
```
=== Contact Manager ===
1. Add Contact  2. Remove  3. Search  4. Show All  5. Exit

Choice: 1
Enter name: Debanjan
✓ Contact 'Debanjan' added.

Choice: 1
Enter name: Alice
✓ Contact 'Alice' added.

Choice: 3
Search: deb
Found: Debanjan

Choice: 4
--- All Contacts (2) ---
1. Alice
2. Debanjan
```

---

## Problem 2: Word Frequency Analyzer with Dictionary (Easy-Medium)
**Concept**: Dictionary\<TKey, TValue\> — counting, sorting, iterating

Build a program that:
1. Accepts a paragraph of text from the user
2. Splits into words (ignore punctuation: `.`, `,`, `!`, `?`, `;`, `:`)
3. Counts frequency of each word (case-insensitive)
4. Displays:
   - Top 5 most frequent words
   - Words that appear only once
   - Total unique word count
   - Alphabetical word list with counts

**Expected Output:**
```
Enter text: The cat sat on the mat. The cat was a happy cat!

=== Word Frequency Analysis ===
Total words: 12
Unique words: 8

Top 5 Most Frequent:
  "the" → 3 times
  "cat" → 3 times
  "sat" → 1 time
  "on"  → 1 time
  "mat" → 1 time

Words appearing once: sat, on, mat, was, a, happy

Alphabetical List:
  a       → 1
  cat     → 3
  happy   → 1
  mat     → 1
  on      → 1
  sat     → 1
  the     → 3
  was     → 1
```

---

## Problem 3: Skill Tracker with HashSet (Medium)
**Concept**: HashSet\<T\> — set operations (Union, Intersection, Except)

Build a developer skill comparison tool:

1. Create skill profiles for 3 developers (use `HashSet<string>` for each)
2. Let the user input skills for each developer (comma-separated)
3. Display:
   - **Each developer's unique skills** (sorted)
   - **Common skills** shared by ALL developers (intersection of all 3)
   - **Skills known by at least one** (union of all 3)
   - **Unique to each developer** (skills no one else has)
   - **Skills known by exactly 2 developers** (not all 3, not just 1)
4. Recommend skills that each developer should learn (skills others know that they don't)

**Expected Output:**
```
=== Developer Skill Tracker ===

Enter skills for Dev 1 (Debanjan): C#, Angular, SQL, Azure, Docker
Enter skills for Dev 2 (Alice): C#, React, SQL, AWS, Docker, Python
Enter skills for Dev 3 (Bob): C#, Angular, SQL, Node.js, Docker

--- Skill Analysis ---

Common to ALL: C#, Docker, SQL

All known skills (11): Angular, AWS, Azure, C#, Docker, Node.js, Python, React, SQL

Unique to Debanjan: Azure
Unique to Alice: AWS, Python, React
Unique to Bob: Node.js

Known by exactly 2: Angular (Debanjan, Bob)

Recommendations:
  Debanjan should learn: AWS, Node.js, Python, React
  Alice should learn: Angular, Azure, Node.js
  Bob should learn: AWS, Azure, Python, React
```

---

## Problem 4: Undo/Redo Text Editor with Stack & Queue (Medium-Hard)
**Concept**: Stack\<T\> for undo/redo, Queue\<T\> for command history

Build a simple text editor simulator:

**Features:**
- **Type text** — append text to the document
- **Delete last word** — remove last word from document
- **Undo** — revert last action (uses `Stack<string>` to store previous states)
- **Redo** — reapply undone action (uses another `Stack<string>`)
- **Command History** — log all commands in a `Queue<string>` with timestamps
- **Show Document** — display current text
- **Show History** — display all commands in order (FIFO)

**Rules:**
- Undo pushes current state to redo stack, pops from undo stack
- Any NEW action clears the redo stack
- Max 10 undo levels (if undo stack > 10, remove oldest)

**Expected Output:**
```
=== Simple Text Editor ===
1. Type  2. Delete Last Word  3. Undo  4. Redo  5. Show Doc  6. History  7. Exit

> 1
Text: Hello World
Document: "Hello World"

> 1
Text:  from Copilot
Document: "Hello World from Copilot"

> 2
Deleted last word: "Copilot"
Document: "Hello World from"

> 3
Undo successful.
Document: "Hello World from Copilot"

> 4
Redo successful.
Document: "Hello World from"

> 3
Undo successful.
Document: "Hello World from Copilot"

> 6
--- Command History ---
[10:30:01] Type: "Hello World"
[10:30:05] Type: " from Copilot"
[10:30:08] Delete Last Word: "Copilot"
[10:30:10] Undo
[10:30:12] Redo
[10:30:14] Undo
```

---

## Problem 5: TaskFlow Inventory Management System (Hard)
**Concept**: All collection types combined — List, Dictionary, HashSet, Queue, Stack

Build an inventory management system for a warehouse:

**Data Structures:**
- `Dictionary<string, Product>` — product catalog (key: product ID)
- `List<Transaction>` — transaction history
- `HashSet<string>` — set of unique categories
- `Queue<Order>` — pending orders (processed FIFO)
- `Stack<Transaction>` — undo last N transactions

**Product Class:** Id, Name, Category, Price, Quantity
**Transaction Class:** Id, ProductId, Type (Restock/Sale), Quantity, Timestamp
**Order Class:** OrderId, ProductId, Quantity, CustomerName

**Features:**
1. **Add Product** — add to catalog, category auto-added to HashSet
2. **Restock Product** — increase quantity, log transaction, push to undo stack
3. **Place Order** — add to order queue
4. **Process Orders** — dequeue and fulfill orders (reduce inventory)
   - If insufficient stock, skip and re-queue the order
5. **Undo Last Transaction** — pop from undo stack, reverse the operation
6. **Category Report** — for each category, show all products and total value
7. **Low Stock Alert** — products with quantity < 5
8. **Transaction History** — show all transactions sorted by timestamp

**Expected Output:**
```
=== Warehouse Inventory System ===

[Add Product] Laptop (Electronics) - $999.99 x 20 → ✓ Added
[Add Product] Mouse (Electronics) - $29.99 x 100 → ✓ Added
[Add Product] Desk (Furniture) - $249.99 x 10 → ✓ Added
[Add Product] Pen (Stationery) - $2.99 x 3 → ✓ Added

Categories: Electronics, Furniture, Stationery

[Restock] Pen +50 → Pen now has 53 units

[Order] Alice wants 5 Laptops → Queued (Position: 1)
[Order] Bob wants 200 Mice → Queued (Position: 2)

[Process Orders]
  Order #1 (Alice, 5 Laptops) → ✓ Fulfilled. Laptop stock: 15
  Order #2 (Bob, 200 Mice) → ✗ Insufficient stock (have 100). Re-queued.

[Undo] Reversed: Sale of 5 Laptops → Laptop stock: 20

--- Low Stock Alert ---
  ⚠ Pen: 53 units (OK after restock)
  (All items currently above threshold)

--- Category Report ---
  Electronics:
    Laptop - $999.99 x 20 = $19,999.80
    Mouse - $29.99 x 100 = $2,999.00
    Subtotal: $22,998.80
  Furniture:
    Desk - $249.99 x 10 = $2,499.90
  Stationery:
    Pen - $2.99 x 53 = $158.47
  Grand Total: $25,657.17
```

---

### Submission
- Create a new console project: `dotnet new console -n CollectionsPractice`
- Solve all 5 problems in `Program.cs`
- Test with various inputs including edge cases (empty collections, duplicates, removing from empty)
- Tell me "check" when you're ready for review!
