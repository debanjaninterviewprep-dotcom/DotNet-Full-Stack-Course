# Topic 04: Stacks and Queues — Interview Questions

---

## Q1. What is a stack and what are its core operations?
**Answer:**
A stack is a **LIFO (Last In First Out)** linear data structure. The last element pushed is the first to be popped.

| Operation | Description | Time |
|---|---|---|
| `Push(x)` | Add element to top | O(1) |
| `Pop()` | Remove and return top element | O(1) |
| `Peek()` | View top element without removing | O(1) |
| `IsEmpty()` | Check if stack is empty | O(1) |

```csharp
var stack = new Stack<int>();
stack.Push(1); stack.Push(2); stack.Push(3);
stack.Peek();  // 3 — does not remove
stack.Pop();   // 3 — removes and returns
stack.Pop();   // 2
// Stack: [1]
```

Real-world uses: function call stack, undo/redo, expression evaluation, backtracking, DFS.

---

## Q2. What is a queue and what are its core operations?
**Answer:**
A queue is a **FIFO (First In First Out)** linear data structure. The first element enqueued is the first to be dequeued.

| Operation | Description | Time |
|---|---|---|
| `Enqueue(x)` | Add element to back | O(1) |
| `Dequeue()` | Remove and return front element | O(1) |
| `Peek()` | View front element | O(1) |
| `IsEmpty()` | Check if queue is empty | O(1) |

```csharp
var queue = new Queue<int>();
queue.Enqueue(1); queue.Enqueue(2); queue.Enqueue(3);
queue.Peek();    // 1 — does not remove
queue.Dequeue(); // 1 — removes and returns
queue.Dequeue(); // 2
// Queue: [3]
```

Real-world uses: task queues, BFS, print spoolers, OS process scheduling.

---

## Q3. How do you implement a stack using two queues?
**Answer:**
**Push O(1), Pop O(n) — "Expensive Pop":**
```csharp
class StackUsingQueues
{
    Queue<int> q1 = new(), q2 = new();

    public void Push(int x) => q1.Enqueue(x); // O(1)

    public int Pop() // O(n)
    {
        while (q1.Count > 1) q2.Enqueue(q1.Dequeue()); // move all but last
        int top = q1.Dequeue();
        (q1, q2) = (q2, q1); // swap
        return top;
    }
}
```

**Push O(n), Pop O(1) — "Expensive Push":**
```csharp
public void Push(int x)
{
    q2.Enqueue(x);
    while (q1.Count > 0) q2.Enqueue(q1.Dequeue()); // move all behind new element
    (q1, q2) = (q2, q1);
}
public int Pop() => q1.Dequeue(); // O(1)
```

---

## Q4. How do you implement a queue using two stacks?
**Answer:**
Use two stacks: `inbox` and `outbox`. Enqueue to `inbox`. Dequeue from `outbox` (lazy transfer):

```csharp
class QueueUsingStacks
{
    Stack<int> inbox = new(), outbox = new();

    public void Enqueue(int x) => inbox.Push(x); // O(1)

    public int Dequeue() // amortized O(1)
    {
        if (outbox.Count == 0)
            while (inbox.Count > 0)
                outbox.Push(inbox.Pop()); // transfer all
        return outbox.Pop();
    }

    public int Peek()
    {
        if (outbox.Count == 0)
            while (inbox.Count > 0) outbox.Push(inbox.Pop());
        return outbox.Peek();
    }
}
```

Each element is moved at most once: amortized O(1) per operation.

---

## Q5. What is a monotonic stack and when is it used?
**Answer:**
A **monotonic stack** maintains elements in strictly increasing or decreasing order. Used to efficiently find the **next/previous greater/smaller element**:

```csharp
// Next Greater Element — O(n) time
int[] NextGreaterElement(int[] nums)
{
    int n = nums.Length;
    int[] result = new int[n];
    Array.Fill(result, -1);
    var stack = new Stack<int>(); // stores indices

    for (int i = 0; i < n; i++)
    {
        // Pop elements that found their answer (current element is greater)
        while (stack.Count > 0 && nums[stack.Peek()] < nums[i])
            result[stack.Pop()] = nums[i];
        stack.Push(i);
    }
    return result;
}
// [2,1,2,4,3] → [4,2,4,-1,-1]
```

Applications: largest rectangle in histogram, trapping rain water, daily temperatures, stock span.

---

## Q6. How do you check for balanced parentheses?
**Answer:**
```csharp
bool IsValid(string s)
{
    var stack = new Stack<char>();
    foreach (char c in s)
    {
        if (c is '(' or '[' or '{')
            stack.Push(c);
        else
        {
            if (stack.Count == 0) return false;
            char top = stack.Pop();
            if (c == ')' && top != '(') return false;
            if (c == ']' && top != '[') return false;
            if (c == '}' && top != '{') return false;
        }
    }
    return stack.Count == 0;
}
// "()[]{}" → true, "([)]" → false, "{[]}" → true
```

---

## Q7. How do you design a stack that supports `GetMin()` in O(1)?
**Answer:**
Use an auxiliary min stack that tracks the current minimum at each state:

```csharp
class MinStack
{
    private Stack<int> _stack = new();
    private Stack<int> _minStack = new();

    public void Push(int val)
    {
        _stack.Push(val);
        int newMin = _minStack.Count == 0 ? val : Math.Min(val, _minStack.Peek());
        _minStack.Push(newMin);
    }

    public void Pop()
    {
        _stack.Pop();
        _minStack.Pop();
    }

    public int Top() => _stack.Peek();
    public int GetMin() => _minStack.Peek(); // O(1)
}
```

---

## Q8. What is a deque (double-ended queue)?
**Answer:**
A **deque** (double-ended queue) allows O(1) insert and delete at both front and back:

```csharp
var deque = new LinkedList<int>(); // C# uses LinkedList as a deque

// Front operations
deque.AddFirst(1);       // push front
deque.First?.Value;      // peek front
deque.RemoveFirst();     // pop front

// Back operations
deque.AddLast(2);        // push back
deque.Last?.Value;       // peek back
deque.RemoveLast();      // pop back
```

In C#, `LinkedList<T>` and `ArrayDeque` (as `Queue<T>` internally) serve this purpose. Used in: sliding window maximum, palindrome checking, BFS with priority.

---

## Q9. How do you find the maximum in a sliding window of size k?
**Answer:**
Use a monotonic deque — O(n) overall:

```csharp
int[] MaxSlidingWindow(int[] nums, int k)
{
    var result = new List<int>();
    var dq = new LinkedList<int>(); // stores indices

    for (int i = 0; i < nums.Length; i++)
    {
        // Remove indices outside window
        while (dq.Count > 0 && dq.First!.Value < i - k + 1)
            dq.RemoveFirst();

        // Remove indices whose values are less than current (maintain decreasing order)
        while (dq.Count > 0 && nums[dq.Last!.Value] < nums[i])
            dq.RemoveLast();

        dq.AddLast(i);

        if (i >= k - 1) result.Add(nums[dq.First!.Value]); // front is max
    }
    return result.ToArray();
}
// [1,3,-1,-3,5,3,6,7], k=3 → [3,3,5,5,6,7]
```

---

## Q10. What is a circular queue and how is it implemented?
**Answer:**
A circular queue reuses empty space at the front by wrapping the rear pointer around:

```csharp
class CircularQueue
{
    private int[] _data;
    private int _head, _tail, _count;

    public CircularQueue(int k) { _data = new int[k]; }

    public bool Enqueue(int val)
    {
        if (_count == _data.Length) return false;
        _data[_tail] = val;
        _tail = (_tail + 1) % _data.Length;
        _count++;
        return true;
    }

    public int Dequeue()
    {
        if (_count == 0) throw new InvalidOperationException();
        int val = _data[_head];
        _head = (_head + 1) % _data.Length;
        _count--;
        return val;
    }

    public bool IsEmpty() => _count == 0;
    public bool IsFull()  => _count == _data.Length;
}
```

---

## Q11. How do you evaluate a Reverse Polish Notation (RPN) expression?
**Answer:**
```csharp
int EvalRPN(string[] tokens)
{
    var stack = new Stack<int>();
    foreach (var token in tokens)
    {
        if (int.TryParse(token, out int num))
            stack.Push(num);
        else
        {
            int b = stack.Pop(), a = stack.Pop();
            stack.Push(token switch
            {
                "+" => a + b,
                "-" => a - b,
                "*" => a * b,
                "/" => a / b,
                _ => throw new ArgumentException()
            });
        }
    }
    return stack.Pop();
}
// ["2","1","+","3","*"] → (2+1)*3 = 9
```

---

## Q12. What is a priority queue (heap) and how does it differ from a regular queue?
**Answer:**
A **priority queue** dequeues the element with the **highest (or lowest) priority**, not necessarily the oldest:

```csharp
// Min-heap — smallest priority dequeued first (.NET 6+)
var pq = new PriorityQueue<string, int>();
pq.Enqueue("Low",    3);
pq.Enqueue("High",   1);
pq.Enqueue("Medium", 2);

pq.Dequeue(); // "High" (priority 1 — smallest)
pq.Dequeue(); // "Medium" (priority 2)
pq.Dequeue(); // "Low" (priority 3)
```

Applications: Dijkstra's algorithm, A* search, Huffman coding, task schedulers, top-K problems.

---

## Q13. How do you implement a browser back/forward navigation using stacks?
**Answer:**
```csharp
class BrowserHistory
{
    private Stack<string> _back = new();
    private Stack<string> _forward = new();
    private string _current;

    public BrowserHistory(string homepage) => _current = homepage;

    public void Visit(string url)
    {
        _back.Push(_current);
        _current = url;
        _forward.Clear(); // visiting new page clears forward history
    }

    public string Back()
    {
        if (_back.Count == 0) return _current;
        _forward.Push(_current);
        return _current = _back.Pop();
    }

    public string Forward()
    {
        if (_forward.Count == 0) return _current;
        _back.Push(_current);
        return _current = _forward.Pop();
    }
}
```

---

## Q14. What is the difference between a stack overflow and a queue?
**Answer:**
- **Stack overflow** (runtime error) — occurs when the call stack exceeds its memory limit due to excessive recursion or very deep nested calls. Not related to the data structure Stack.

```csharp
// Causes stack overflow — infinite recursion
void Infinite() => Infinite(); // each call adds a frame to the call stack
```

- The **Queue** data structure does not inherently overflow unless you explicitly limit its capacity (bounded queue). An unbounded queue can grow until heap memory is exhausted (`OutOfMemoryException`).

---

## Q15. When would you choose a stack vs a queue in algorithm design?
**Answer:**
| Scenario | Stack (LIFO) | Queue (FIFO) |
|---|---|---|
| Graph traversal | DFS (Depth-First Search) | BFS (Breadth-First Search) |
| Tree traversal | Iterative inorder/preorder | Level-order (BFS) |
| Backtracking | ✓ — undo last decision | ✗ |
| Expression evaluation | ✓ — RPN, balanced parens | ✗ |
| Shortest path | ✗ | ✓ (BFS on unweighted graphs) |
| Processing order | Last-first | First-first |
| Memory footprint | DFS: O(depth) | BFS: O(width) |

**Interview tip:** BFS uses a queue; DFS uses a stack (or recursion which implicitly uses the call stack).
