# Topic 4: Stacks & Queues

## Stack — Last In, First Out (LIFO)

A **stack** is like a stack of plates: you add to the top and remove from the top.

```
Push 10, Push 20, Push 30:

   ┌────┐
   │ 30 │ ← Top (last in, first out)
   ├────┤
   │ 20 │
   ├────┤
   │ 10 │
   └────┘

Pop() → 30  (removes top)
Peek() → 20 (looks at top without removing)
```

### Stack Operations & Complexity

| Operation | Complexity |
|---|---|
| Push | O(1) |
| Pop | O(1) |
| Peek/Top | O(1) |
| IsEmpty | O(1) |
| Search | O(n) |

---

## Implementing a Stack

### Using Array

```csharp
public class ArrayStack<T>
{
    private T[] _items;
    private int _top;
    
    public ArrayStack(int capacity = 16)
    {
        _items = new T[capacity];
        _top = -1;
    }
    
    public void Push(T item)
    {
        if (_top == _items.Length - 1)
        {
            // Double the capacity (amortized O(1))
            T[] newItems = new T[_items.Length * 2];
            Array.Copy(_items, newItems, _items.Length);
            _items = newItems;
        }
        _items[++_top] = item;
    }
    
    public T Pop()
    {
        if (IsEmpty) throw new InvalidOperationException("Stack is empty");
        T item = _items[_top];
        _items[_top--] = default!; // Help GC
        return item;
    }
    
    public T Peek()
    {
        if (IsEmpty) throw new InvalidOperationException("Stack is empty");
        return _items[_top];
    }
    
    public bool IsEmpty => _top == -1;
    public int Count => _top + 1;
}
```

### Using Linked List

```csharp
public class LinkedStack<T>
{
    private class Node
    {
        public T Val;
        public Node? Next;
        public Node(T val, Node? next = null) { Val = val; Next = next; }
    }
    
    private Node? _top;
    private int _count;
    
    public void Push(T item)
    {
        _top = new Node(item, _top); // New node points to old top
        _count++;
    }
    
    public T Pop()
    {
        if (_top == null) throw new InvalidOperationException("Stack is empty");
        T val = _top.Val;
        _top = _top.Next;
        _count--;
        return val;
    }
    
    public T Peek() => _top == null ? throw new InvalidOperationException() : _top.Val;
    public bool IsEmpty => _top == null;
    public int Count => _count;
}
```

### Using Built-in Stack\<T\>

```csharp
Stack<int> stack = new Stack<int>();
stack.Push(10);
stack.Push(20);
stack.Push(30);

Console.WriteLine(stack.Peek());  // 30
Console.WriteLine(stack.Pop());   // 30
Console.WriteLine(stack.Count);   // 2
Console.WriteLine(stack.Contains(10)); // true
```

---

## Classic Stack Applications

### 1. Balanced Parentheses

```csharp
bool IsBalanced(string s)
{
    Stack<char> stack = new Stack<char>();
    Dictionary<char, char> pairs = new() { {')', '('}, {']', '['}, {'}', '{'} };
    
    foreach (char c in s)
    {
        if (c is '(' or '[' or '{')
        {
            stack.Push(c);
        }
        else if (pairs.ContainsKey(c))
        {
            if (stack.Count == 0 || stack.Pop() != pairs[c])
                return false;
        }
    }
    return stack.Count == 0;
}

// "([]{})" → true
// "([)]"   → false
// "{{}}"   → true
```

### 2. Evaluate Postfix Expression

```csharp
// Postfix: 2 3 + 4 * = (2+3)*4 = 20
int EvalPostfix(string[] tokens)
{
    Stack<int> stack = new Stack<int>();
    
    foreach (string token in tokens)
    {
        if (int.TryParse(token, out int num))
        {
            stack.Push(num);
        }
        else
        {
            int b = stack.Pop();
            int a = stack.Pop();
            int result = token switch
            {
                "+" => a + b,
                "-" => a - b,
                "*" => a * b,
                "/" => a / b,
                _ => throw new InvalidOperationException()
            };
            stack.Push(result);
        }
    }
    return stack.Pop();
}
// ["2", "3", "+", "4", "*"] → 20
```

### 3. Infix to Postfix Conversion

```csharp
string InfixToPostfix(string expression)
{
    Stack<char> stack = new Stack<char>();
    List<string> output = new List<string>();
    
    int Precedence(char op) => op is '+' or '-' ? 1 : op is '*' or '/' ? 2 : 0;
    
    for (int i = 0; i < expression.Length; i++)
    {
        char c = expression[i];
        
        if (char.IsDigit(c))
        {
            string num = "";
            while (i < expression.Length && char.IsDigit(expression[i]))
                num += expression[i++];
            i--;
            output.Add(num);
        }
        else if (c == '(')
        {
            stack.Push(c);
        }
        else if (c == ')')
        {
            while (stack.Peek() != '(')
                output.Add(stack.Pop().ToString());
            stack.Pop(); // Remove '('
        }
        else if (c is '+' or '-' or '*' or '/')
        {
            while (stack.Count > 0 && Precedence(stack.Peek()) >= Precedence(c))
                output.Add(stack.Pop().ToString());
            stack.Push(c);
        }
    }
    while (stack.Count > 0)
        output.Add(stack.Pop().ToString());
    
    return string.Join(" ", output);
}
// "2+3*4" → "2 3 4 * +"
// "(2+3)*4" → "2 3 + 4 *"
```

### 4. Next Greater Element (Monotonic Stack)

```csharp
// For each element, find the next element that is greater
int[] NextGreaterElement(int[] arr)
{
    int n = arr.Length;
    int[] result = new int[n];
    Array.Fill(result, -1);
    Stack<int> stack = new Stack<int>(); // Stores indices
    
    for (int i = 0; i < n; i++)
    {
        // Pop elements smaller than current
        while (stack.Count > 0 && arr[stack.Peek()] < arr[i])
        {
            result[stack.Pop()] = arr[i];
        }
        stack.Push(i);
    }
    return result;
}
// Input:  [4, 5, 2, 10, 8]
// Output: [5, 10, 10, -1, -1]
// 4→5, 5→10, 2→10, 10→none, 8→none
```

### 5. Min Stack (O(1) retrieval of minimum)

```csharp
public class MinStack
{
    private Stack<int> _stack = new();
    private Stack<int> _minStack = new();
    
    public void Push(int val)
    {
        _stack.Push(val);
        if (_minStack.Count == 0 || val <= _minStack.Peek())
            _minStack.Push(val);
    }
    
    public int Pop()
    {
        int val = _stack.Pop();
        if (val == _minStack.Peek())
            _minStack.Pop();
        return val;
    }
    
    public int Top() => _stack.Peek();
    public int GetMin() => _minStack.Peek();
}
// Push(3), Push(5), Push(2), Push(1)
// GetMin() → 1
// Pop() → 1 (removed 1)
// GetMin() → 2
```

---

## Queue — First In, First Out (FIFO)

A **queue** is like a line at a store: first person in line gets served first.

```
Enqueue: → [10] [20] [30] [40] →
             ↑                ↑
            Rear             Front
            (add here)       (remove here)

Dequeue() → 10 (removes front)
Peek()    → 20 (looks at front)
```

### Queue Operations & Complexity

| Operation | Complexity |
|---|---|
| Enqueue | O(1) |
| Dequeue | O(1) |
| Peek/Front | O(1) |
| IsEmpty | O(1) |
| Search | O(n) |

---

## Implementing a Queue

### Using Circular Array

```csharp
public class CircularQueue<T>
{
    private T[] _items;
    private int _front, _rear, _count;
    
    public CircularQueue(int capacity = 16)
    {
        _items = new T[capacity];
        _front = 0;
        _rear = -1;
        _count = 0;
    }
    
    public void Enqueue(T item)
    {
        if (_count == _items.Length)
            throw new InvalidOperationException("Queue is full");
        
        _rear = (_rear + 1) % _items.Length; // Wrap around
        _items[_rear] = item;
        _count++;
    }
    
    public T Dequeue()
    {
        if (IsEmpty) throw new InvalidOperationException("Queue is empty");
        
        T item = _items[_front];
        _items[_front] = default!;
        _front = (_front + 1) % _items.Length; // Wrap around
        _count--;
        return item;
    }
    
    public T Peek() => IsEmpty ? throw new InvalidOperationException() : _items[_front];
    public bool IsEmpty => _count == 0;
    public int Count => _count;
}
```

### Circular Array Visualization

```
Capacity: 5

After Enqueue(A, B, C, D):
Index:  [0]  [1]  [2]  [3]  [4]
Value:   A    B    C    D    _
         ↑front            ↑rear

After Dequeue() × 2 (removes A, B):
Index:  [0]  [1]  [2]  [3]  [4]
Value:   _    _    C    D    _
                   ↑front  ↑rear

After Enqueue(E, F) — wraps around!
Index:  [0]  [1]  [2]  [3]  [4]
Value:   F    _    C    D    E
         ↑rear     ↑front
```

### Using Built-in Queue\<T\>

```csharp
Queue<int> queue = new Queue<int>();
queue.Enqueue(10);
queue.Enqueue(20);
queue.Enqueue(30);

Console.WriteLine(queue.Peek());    // 10
Console.WriteLine(queue.Dequeue()); // 10
Console.WriteLine(queue.Count);     // 2
```

---

## Deque (Double-Ended Queue)

Add/remove from **both ends** in O(1).

```csharp
// C# doesn't have a built-in Deque, but LinkedList<T> works as one:
LinkedList<int> deque = new LinkedList<int>();
deque.AddFirst(10);   // Push front
deque.AddLast(20);    // Push back
deque.RemoveFirst();  // Pop front → 10
deque.RemoveLast();   // Pop back → 20

// Useful for sliding window maximum problem
```

---

## Priority Queue

Elements are dequeued based on **priority**, not insertion order.

```csharp
// .NET 6+ has PriorityQueue<TElement, TPriority>
PriorityQueue<string, int> pq = new PriorityQueue<string, int>();

pq.Enqueue("Low priority task", 3);
pq.Enqueue("High priority task", 1);
pq.Enqueue("Medium priority task", 2);

while (pq.Count > 0)
    Console.WriteLine(pq.Dequeue());
// Output (min-heap — lowest priority number first):
// High priority task
// Medium priority task
// Low priority task
```

| Operation | Complexity |
|---|---|
| Enqueue | O(log n) |
| Dequeue | O(log n) |
| Peek | O(1) |

---

## Queue Implemented Using Two Stacks

A classic interview question — use two stacks to create a queue.

```csharp
public class QueueUsingStacks<T>
{
    private Stack<T> _inbox = new();  // For enqueue
    private Stack<T> _outbox = new(); // For dequeue
    
    // O(1)
    public void Enqueue(T item) => _inbox.Push(item);
    
    // Amortized O(1)
    public T Dequeue()
    {
        if (_outbox.Count == 0)
        {
            // Transfer all from inbox to outbox (reverses order)
            while (_inbox.Count > 0)
                _outbox.Push(_inbox.Pop());
        }
        return _outbox.Pop();
    }
    
    public T Peek()
    {
        if (_outbox.Count == 0)
            while (_inbox.Count > 0)
                _outbox.Push(_inbox.Pop());
        return _outbox.Peek();
    }
    
    public bool IsEmpty => _inbox.Count == 0 && _outbox.Count == 0;
}

// Enqueue(1), Enqueue(2), Enqueue(3)
// inbox: [1, 2, 3], outbox: []
// Dequeue(): transfer → outbox: [3, 2, 1], pop → 1
// Dequeue(): outbox still has [3, 2], pop → 2
```

---

## Stack Implemented Using Two Queues

```csharp
public class StackUsingQueues<T>
{
    private Queue<T> _q1 = new();
    private Queue<T> _q2 = new();
    
    // O(n) — move all but last to q2, then swap
    public void Push(T item)
    {
        _q2.Enqueue(item);
        while (_q1.Count > 0)
            _q2.Enqueue(_q1.Dequeue());
        (_q1, _q2) = (_q2, _q1);
    }
    
    // O(1)
    public T Pop() => _q1.Dequeue();
    public T Peek() => _q1.Peek();
    public bool IsEmpty => _q1.Count == 0;
}
```

---

## Real-World Use Cases

| Data Structure | Use Case |
|---|---|
| Stack | Undo/Redo, browser back/forward, call stack, expression evaluation |
| Queue | BFS traversal, task scheduling, print queue, message queues |
| Deque | Sliding window problems, palindrome checking |
| Priority Queue | Dijkstra's algorithm, task scheduling by priority, event simulation |

---

## Key Takeaways

| Concept | Summary |
|---|---|
| Stack | LIFO — Push/Pop at top only. O(1) for all operations |
| Queue | FIFO — Enqueue at rear, Dequeue from front. O(1) |
| Monotonic Stack | Stack maintaining increasing/decreasing order — next greater element |
| Circular Queue | Array-based queue that wraps around to reuse space |
| Min Stack | Track minimum alongside regular stack operations |
| Two Stacks → Queue | Inbox/outbox pattern, amortized O(1) |
| Priority Queue | Dequeue by priority (uses heap internally) |

---

*Next Topic: Hash Tables & Hashing →*
