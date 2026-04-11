# Topic 4: Stacks & Queues — Practice Problems

## Problem 1: Stack Fundamentals (Easy)
**Concept**: Stack implementation and basic operations

### 1a. Implement Stack Using Array
Build a generic `ArrayStack<T>` from scratch with:
- `Push(T item)`, `Pop()`, `Peek()`, `IsEmpty`, `Count`
- Auto-resize when full (double capacity)

### 1b. Balanced Parentheses Checker
Check if a string has balanced brackets: `()`, `[]`, `{}`
```
"([]{})" → true
"([)]"   → false
""       → true
"((("    → false
"{[()]}" → true
```

### 1c. Reverse a String Using Stack
```
Input: "Hello World"
Output: "dlroW olleH"
```

### 1d. Decimal to Binary Using Stack
```
Input: 13
Output: "1101"
```
Hint: Repeatedly divide by 2, push remainders, pop all.

**Expected Output:**
```
=== Stack Operations ===
Push(10), Push(20), Push(30)
Peek: 30, Count: 3
Pop: 30, Pop: 20
Peek: 10, Count: 1

=== Balanced Parentheses ===
"([]{})" → true
"([)]"   → false

=== Reverse String ===
"Hello World" → "dlroW olleH"

=== Decimal to Binary ===
13 → 1101
25 → 11001
```

---

## Problem 2: Queue Implementation & Operations (Easy-Medium)
**Concept**: Queue variants and usage

### 2a. Implement Queue Using Circular Array
Build `CircularQueue<T>` with:
- Fixed capacity, wraps around
- `Enqueue`, `Dequeue`, `Peek`, `IsEmpty`, `IsFull`, `Count`

### 2b. Queue Using Two Stacks
Implement a queue that uses only two stacks internally.
```
Enqueue(1), Enqueue(2), Enqueue(3)
Dequeue() → 1
Dequeue() → 2
Enqueue(4)
Dequeue() → 3
Dequeue() → 4
```

### 2c. Generate Binary Numbers from 1 to N Using Queue
```
Input: n = 5
Output: ["1", "10", "11", "100", "101"]
```
Hint: Start with "1" in queue, for each dequeued value, enqueue value+"0" and value+"1".

### 2d. First Non-Repeating Character in a Stream
Process characters one at a time, after each character output the first non-repeating character.
```
Input stream: "aabcbcd"
After 'a': 'a'
After 'a': null (a repeats)
After 'b': 'b'
After 'c': 'b'
After 'b': 'c' (b now repeats)
After 'c': 'd'? Wait — let's recalculate...
After 'd': 'd'
```
Hint: Use a queue + frequency dictionary.

---

## Problem 3: Monotonic Stack Problems (Medium)
**Concept**: Stack maintaining increasing or decreasing order

### 3a. Next Greater Element
For each element, find the next element to its right that is greater.
```
Input:  [4, 5, 2, 10, 8]
Output: [5, 10, 10, -1, -1]
```

### 3b. Previous Smaller Element
For each element, find the nearest smaller element to its left.
```
Input:  [4, 5, 2, 10, 8]
Output: [-1, 4, -1, 2, 2]
```

### 3c. Stock Span Problem
The span of a stock price on a given day is the number of consecutive days (including today) the price was ≤ today's price.
```
Input:  [100, 80, 60, 70, 60, 75, 85]
Output: [1, 1, 1, 2, 1, 4, 6]
```

### 3d. Largest Rectangle in Histogram
Find the area of the largest rectangle that fits in a histogram.
```
Input: heights = [2, 1, 5, 6, 2, 3]
Output: 10 (rectangle of height 5, width 2 at indices 2-3)
```
This is a classic monotonic stack problem. Time: O(n)

---

## Problem 4: Advanced Stack & Queue Problems (Medium-Hard)
**Concept**: Combining stacks/queues with other techniques

### 4a. Min Stack
Design a stack that supports `Push`, `Pop`, `Top`, and `GetMin` — all in O(1).
```
Push(3), Push(5), Push(2), Push(1)
GetMin() → 1
Pop(), GetMin() → 2
Pop(), GetMin() → 3
```

### 4b. Evaluate Infix Expression
Build a calculator that handles `+`, `-`, `*`, `/`, and parentheses.
```
Input: "3 + 4 * 2 / (1 - 5)"
Output: 1  (i.e., 3 + ((4*2)/(1-5)) = 3 + (8/-4) = 3 + (-2) = 1)
```
Use the Shunting Yard algorithm or two-stack approach.

### 4c. Sliding Window Maximum
Given an array and window size k, find the maximum in each window.
```
Input: [1, 3, -1, -3, 5, 3, 6, 7], k = 3
Output: [3, 3, 5, 5, 6, 7]

Windows: [1,3,-1]=3, [3,-1,-3]=3, [-1,-3,5]=5, [-3,5,3]=5, [5,3,6]=6, [3,6,7]=7
```
Time: O(n) using Deque (not O(n×k) brute force!)

### 4d. Implement Stack that Sorts Itself
After every push, the stack should remain sorted (smallest on top).
Only use one additional stack as extra space.
```
Push(5), Push(2), Push(8), Push(1), Push(3)
Stack (top to bottom): 1, 2, 3, 5, 8
Pop() → 1, Pop() → 2, Pop() → 3
```

---

## Problem 5: Real-World Application (Hard)
**Concept**: Apply stacks/queues to practical scenarios

### Build an Undo/Redo System

Implement a text editor that supports:
1. `Type(string text)` — append text to document
2. `Delete(int n)` — delete last n characters
3. `Undo()` — undo last operation
4. `Redo()` — redo last undone operation
5. `GetDocument()` — return current document state

Use **two stacks**: undo stack and redo stack.

**Expected Output:**
```
=== Text Editor with Undo/Redo ===
Type("Hello") → "Hello"
Type(" World") → "Hello World"
Delete(6) → "Hello"
Undo() → "Hello World"
Undo() → "Hello"
Redo() → "Hello World"
Type("!") → "Hello World!"
Redo() → "Hello World!" (nothing to redo — redo stack cleared after new operation)
Undo() → "Hello World"
Undo() → "Hello"
Undo() → ""
Undo() → "" (nothing to undo)
```

**Bonus:** Support `Replace(int start, int len, string text)` operation with undo/redo.

---

### Submission
- Create a new console project: `dotnet new console -n StacksQueuesPractice`
- Solve all problems in `Program.cs`
- Comment each solution with **Time: O(?), Space: O(?)**
- Test edge cases: empty stack/queue, single element, overflow/underflow
- Tell me "check" when you're ready for review!
