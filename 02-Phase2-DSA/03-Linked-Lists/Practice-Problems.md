# Topic 3: Linked Lists — Practice Problems

## Problem 1: Build Your Own Linked List (Easy)
**Concept**: Singly linked list CRUD operations

Build a `SinglyLinkedList` class from scratch with:

1. `InsertAtHead(int val)` — O(1)
2. `InsertAtTail(int val)` — O(n) or O(1) with tail
3. `InsertAt(int index, int val)` — O(n)
4. `DeleteByValue(int val)` — remove first occurrence
5. `DeleteAt(int index)` — remove at position
6. `Search(int val)` — return index or -1
7. `GetAt(int index)` — return value at index
8. `Print()` — display the list
9. `Count` — property for size
10. `Reverse()` — reverse in-place

Test with at least 10 operations and print after each.

**Expected Output:**
```
InsertAtTail(10): 10 → null
InsertAtTail(20): 10 → 20 → null
InsertAtTail(30): 10 → 20 → 30 → null
InsertAtHead(5):  5 → 10 → 20 → 30 → null
InsertAt(2, 15):  5 → 10 → 15 → 20 → 30 → null
Delete(15):       5 → 10 → 20 → 30 → null
Search(20): found at index 2
Reverse():        30 → 20 → 10 → 5 → null
Count: 4
```

---

## Problem 2: Linked List Classic Problems (Easy-Medium)
**Concept**: Fast/slow pointers, reversal

### 2a. Find Middle of Linked List
```
Input: 1 → 2 → 3 → 4 → 5
Output: 3

Input: 1 → 2 → 3 → 4 → 5 → 6
Output: 4 (second middle)
```

### 2b. Detect Cycle
Return `true` if the linked list has a cycle.

### 2c. Find Nth Node from End
```
Input: 1 → 2 → 3 → 4 → 5, n = 2
Output: 4 (2nd from end)
```
Hint: Use two pointers, n nodes apart.

### 2d. Remove Duplicates from Sorted List
```
Input: 1 → 1 → 2 → 3 → 3
Output: 1 → 2 → 3
```

### 2e. Check if Linked List is Palindrome
```
Input: 1 → 2 → 3 → 2 → 1
Output: true
```
Hint: Find middle, reverse second half, compare.

---

## Problem 3: Merge & Sort Linked Lists (Medium)
**Concept**: Merge sorted lists, sort a linked list

### 3a. Merge Two Sorted Lists
```
Input: 1 → 3 → 5, 2 → 4 → 6
Output: 1 → 2 → 3 → 4 → 5 → 6
```

### 3b. Remove All Nodes with Value
```
Input: 1 → 2 → 6 → 3 → 4 → 5 → 6, val = 6
Output: 1 → 2 → 3 → 4 → 5
```

### 3c. Intersection of Two Linked Lists
Find the node where two singly linked lists intersect.
```
A: 1 → 2 → ↘
             8 → 9 → null
B: 3 → 4 → ↗
Output: Node with value 8
```
Time: O(n+m), Space: O(1)

### 3d. Sort a Linked List
Sort a linked list in O(n log n) time.
Hint: Use merge sort — find middle, split, sort each half, merge.

---

## Problem 4: Advanced Linked List Operations (Medium-Hard)
**Concept**: Multiple pointers, complex manipulation

### 4a. Reverse Linked List in Groups of K
```
Input: 1 → 2 → 3 → 4 → 5, k = 3
Output: 3 → 2 → 1 → 4 → 5
(Only reverse if group has k nodes)
```

### 4b. Add Two Numbers
Numbers represented as linked lists (digits in reverse order).
```
Input: 2 → 4 → 3 (342) + 5 → 6 → 4 (465)
Output: 7 → 0 → 8 (807)
```
Handle carry!

### 4c. Flatten a Multilevel Doubly Linked List
Each node has a `Child` pointer. Flatten into a single-level list.
```
1 ⇄ 2 ⇄ 3 ⇄ 4
         |
         7 ⇄ 8
         |
         11
Output: 1 ⇄ 2 ⇄ 3 ⇄ 7 ⇄ 11 ⇄ 8 ⇄ 4
```

### 4d. Copy List with Random Pointer
Each node has a `Next` and a `Random` pointer. Create a deep copy.
Hint: Interleave cloned nodes, set random pointers, then separate lists.

---

## Problem 5: LRU Cache (Hard)
**Concept**: Doubly linked list + Dictionary — real interview classic

Implement an **LRU (Least Recently Used) Cache** with O(1) for both `Get` and `Put`:

```csharp
// LRUCache cache = new LRUCache(3); // capacity = 3
// cache.Put(1, "A");  // cache: {1=A}
// cache.Put(2, "B");  // cache: {1=A, 2=B}
// cache.Put(3, "C");  // cache: {1=A, 2=B, 3=C}
// cache.Get(1);       // returns "A", moves 1 to most recent
// cache.Put(4, "D");  // cache full! evict LRU (2=B): {1=A, 3=C, 4=D}
// cache.Get(2);       // returns null (evicted)
```

**Data Structures:**
- `Dictionary<int, DoublyNode>` — O(1) lookup
- `DoublyLinkedList` — O(1) insert/delete for ordering

**Required Methods:**
- `Get(int key)` → returns value or null, marks as recently used
- `Put(int key, string value)` → insert or update, evict LRU if full

**Expected Output:**
```
=== LRU Cache (capacity: 3) ===
Put(1, "A") → [1:A]
Put(2, "B") → [2:B, 1:A]
Put(3, "C") → [3:C, 2:B, 1:A]
Get(1)      → "A" → [1:A, 3:C, 2:B]
Put(4, "D") → Evicted key 2 → [4:D, 1:A, 3:C]
Get(2)      → null (not found)
Put(5, "E") → Evicted key 3 → [5:E, 4:D, 1:A]
Get(1)      → "A" → [1:A, 5:E, 4:D]
Get(4)      → "D" → [4:D, 1:A, 5:E]
```

---

### Submission
- Create a new console project: `dotnet new console -n LinkedListPractice`
- Solve all 5 problems
- Add **Time: O(?), Space: O(?)** comments for each solution
- Test edge cases: empty list, single node, cycle at different positions
- Tell me "check" when you're ready for review!
