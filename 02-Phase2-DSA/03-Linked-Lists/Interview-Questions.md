# Topic 03: Linked Lists — Interview Questions

---

## Q1. What is a linked list and what are its types?
**Answer:**
A linked list is a linear data structure where each element (**node**) contains a value and a pointer to the next node. Unlike arrays, nodes are stored at non-contiguous memory locations.

| Type | Structure | Notes |
|---|---|---|
| **Singly linked** | `Node → Node → null` | Forward traversal only |
| **Doubly linked** | `null ← Node ↔ Node → null` | Forward and backward traversal |
| **Circular (singly)** | `Node → Node → (back to head)` | No null terminator; used in round-robin |
| **Circular doubly** | Both directions, circular | Most flexible; used in complex data structures |

```csharp
class Node<T>
{
    public T Value;
    public Node<T>? Next;
    public Node(T val) => Value = val;
}
```

---

## Q2. What are the time complexities of linked list operations?
**Answer:**
| Operation | Singly Linked | Doubly Linked |
|---|---|---|
| Access by index | O(n) | O(n) |
| Search | O(n) | O(n) |
| Insert at head | O(1) | O(1) |
| Insert at tail | O(n)* / O(1)** | O(1)** |
| Insert in middle | O(n) to find + O(1) to insert | Same |
| Delete head | O(1) | O(1) |
| Delete tail | O(n) (singly) | O(1)** |
| Delete in middle | O(n) to find + O(1) | Same |

*O(n) without tail pointer, **O(1) with tail pointer.

---

## Q3. How do you reverse a singly linked list?
**Answer:**
**Iteratively — O(n) time, O(1) space:**
```csharp
Node<int>? Reverse(Node<int>? head)
{
    Node<int>? prev = null, curr = head;
    while (curr != null)
    {
        var next = curr.Next; // save next
        curr.Next = prev;     // reverse pointer
        prev = curr;          // advance prev
        curr = next;          // advance curr
    }
    return prev; // new head
}
```

**Recursively — O(n) time, O(n) space (stack):**
```csharp
Node<int>? ReverseRecursive(Node<int>? head)
{
    if (head?.Next == null) return head;
    var newHead = ReverseRecursive(head.Next);
    head.Next.Next = head;
    head.Next = null;
    return newHead;
}
```

---

## Q4. How do you detect a cycle in a linked list? (Floyd's Algorithm)
**Answer:**
Use two pointers — **slow** (moves 1 step) and **fast** (moves 2 steps). If they meet, a cycle exists:

```csharp
bool HasCycle(Node<int>? head)
{
    Node<int>? slow = head, fast = head;
    while (fast?.Next != null)
    {
        slow = slow!.Next;
        fast = fast.Next.Next;
        if (slow == fast) return true;
    }
    return false;
}
```

**To find the cycle start:**
```csharp
Node<int>? DetectCycleStart(Node<int>? head)
{
    Node<int>? slow = head, fast = head;
    while (fast?.Next != null)
    {
        slow = slow!.Next;
        fast = fast.Next.Next;
        if (slow == fast)
        {
            slow = head; // reset slow to head
            while (slow != fast) { slow = slow!.Next; fast = fast!.Next; }
            return slow; // cycle start
        }
    }
    return null;
}
```

---

## Q5. How do you find the middle of a linked list?
**Answer:**
Use slow and fast pointers. When fast reaches the end, slow is at the middle:

```csharp
Node<int>? FindMiddle(Node<int>? head)
{
    Node<int>? slow = head, fast = head;
    while (fast?.Next != null)
    {
        slow = slow!.Next;
        fast = fast.Next.Next;
    }
    return slow; // middle node
}
// [1→2→3→4→5] → returns node(3)
// [1→2→3→4]   → returns node(2) (first middle for even length)
```

**Variation:** To get the second middle for even-length lists, change the condition to `while (fast != null)`.

---

## Q6. How do you merge two sorted linked lists?
**Answer:**
```csharp
Node<int>? MergeSorted(Node<int>? l1, Node<int>? l2)
{
    var dummy = new Node<int>(0);
    var curr = dummy;
    while (l1 != null && l2 != null)
    {
        if (l1.Value <= l2.Value) { curr.Next = l1; l1 = l1.Next; }
        else                      { curr.Next = l2; l2 = l2.Next; }
        curr = curr.Next;
    }
    curr.Next = l1 ?? l2; // attach remaining
    return dummy.Next;
}
// O(n + m) time, O(1) space
```

---

## Q7. How do you detect if two linked lists intersect?
**Answer:**
**Approach 1: Length difference — O(n+m) time, O(1) space:**
```csharp
Node<int>? GetIntersection(Node<int>? a, Node<int>? b)
{
    int lenA = Length(a), lenB = Length(b);
    while (lenA > lenB) { a = a!.Next; lenA--; }
    while (lenB > lenA) { b = b!.Next; lenB--; }
    while (a != b) { a = a!.Next; b = b!.Next; }
    return a;
}
```

**Approach 2: Two-pointer reset — O(n+m) time, O(1) space:**
```csharp
Node<int>? GetIntersection2(Node<int>? a, Node<int>? b)
{
    var p1 = a; var p2 = b;
    while (p1 != p2)
    {
        p1 = p1 == null ? b : p1.Next; // when one ends, redirect to other list
        p2 = p2 == null ? a : p2.Next;
    }
    return p1; // null if no intersection
}
```

---

## Q8. How do you remove the Nth node from the end?
**Answer:**
Use two pointers with a gap of N between them — O(n) time, O(1) space:

```csharp
Node<int>? RemoveNthFromEnd(Node<int>? head, int n)
{
    var dummy = new Node<int>(0) { Next = head };
    Node<int>? fast = dummy, slow = dummy;

    // Move fast n+1 steps ahead
    for (int i = 0; i <= n; i++) fast = fast!.Next;

    // Move both until fast reaches end
    while (fast != null) { slow = slow!.Next; fast = fast.Next; }

    // slow.Next is the node to remove
    slow!.Next = slow.Next!.Next;
    return dummy.Next;
}
```

---

## Q9. How do you check if a linked list is a palindrome?
**Answer:**
Find middle, reverse second half, compare with first half — O(n) time, O(1) space:

```csharp
bool IsPalindrome(Node<int>? head)
{
    // Find middle
    Node<int>? slow = head, fast = head;
    while (fast?.Next != null) { slow = slow!.Next; fast = fast.Next.Next; }

    // Reverse second half
    Node<int>? secondHalf = Reverse(slow);
    Node<int>? firstHalf = head;

    // Compare
    var p = secondHalf;
    bool isPalin = true;
    while (p != null)
    {
        if (firstHalf!.Value != p.Value) { isPalin = false; break; }
        firstHalf = firstHalf.Next;
        p = p.Next;
    }
    Reverse(secondHalf); // restore list (optional)
    return isPalin;
}
```

---

## Q10. What is the difference between a linked list and an array?
**Answer:**
| | Array | Linked List |
|---|---|---|
| **Memory** | Contiguous | Non-contiguous |
| **Size** | Fixed (or reallocated) | Dynamic |
| **Random access** | O(1) | O(n) |
| **Insert/delete at head** | O(n) | O(1) |
| **Insert/delete at middle** | O(n) | O(n) find + O(1) modify |
| **Cache performance** | Excellent (locality) | Poor (pointer chasing) |
| **Extra memory** | None | Pointer per node |

**Use linked list when:** frequent insert/delete at known positions, unknown size at compile time, implementing stacks/queues.
**Use array when:** frequent random access, mathematical operations, cache-sensitive code.

---

## Q11. How do you sort a linked list?
**Answer:**
**Merge Sort is ideal for linked lists** — O(n log n) time, O(log n) space (recursion):

```csharp
Node<int>? Sort(Node<int>? head)
{
    if (head?.Next == null) return head;

    // Split into halves
    Node<int>? mid = FindMiddle(head);
    Node<int>? second = mid!.Next;
    mid.Next = null;

    return MergeSorted(Sort(head), Sort(second));
}
```

Quick sort is harder to implement on linked lists (no O(1) random access for pivot). Insertion sort is O(n²) but good for nearly-sorted lists.

---

## Q12. How do you add two numbers represented as linked lists?
**Answer:**
```csharp
// Each digit stored in separate node, digits in reverse order
// 342 → [2→4→3], 465 → [5→6→4], sum = 807 → [7→0→8]
Node<int>? AddTwoNumbers(Node<int>? l1, Node<int>? l2)
{
    var dummy = new Node<int>(0);
    var curr = dummy;
    int carry = 0;
    while (l1 != null || l2 != null || carry != 0)
    {
        int sum = carry;
        if (l1 != null) { sum += l1.Value; l1 = l1.Next; }
        if (l2 != null) { sum += l2.Value; l2 = l2.Next; }
        carry = sum / 10;
        curr.Next = new Node<int>(sum % 10);
        curr = curr.Next;
    }
    return dummy.Next;
}
```

---

## Q13. What is a sentinel/dummy node and why is it useful?
**Answer:**
A **sentinel (dummy) node** is a placeholder node added before the real head to simplify edge cases (empty list, deleting head node):

```csharp
// Without dummy — must handle head deletion specially
Node<int>? head = ...;
if (head.Value == target) head = head.Next;

// With dummy — uniform logic for all nodes
var dummy = new Node<int>(0) { Next = head };
var curr = dummy;
while (curr.Next != null)
{
    if (curr.Next.Value == target) curr.Next = curr.Next.Next; // delete
    else curr = curr.Next;
}
return dummy.Next;
```

---

## Q14. How do you flatten a multilevel doubly linked list?
**Answer:**
Use a stack to handle child lists — O(n) time:

```csharp
class MLNode { public int Val; public MLNode? Next, Prev, Child; }

MLNode? Flatten(MLNode? head)
{
    if (head == null) return null;
    var stack = new Stack<MLNode>();
    var curr = head;
    while (curr != null)
    {
        if (curr.Child != null)
        {
            if (curr.Next != null) stack.Push(curr.Next);
            curr.Next = curr.Child;
            curr.Child.Prev = curr;
            curr.Child = null;
        }
        if (curr.Next == null && stack.Count > 0)
        {
            var next = stack.Pop();
            curr.Next = next;
            next.Prev = curr;
        }
        curr = curr.Next;
    }
    return head;
}
```

---

## Q15. What is an LRU Cache and how is it implemented using a linked list?
**Answer:**
**LRU (Least Recently Used) Cache** evicts the least recently accessed item when at capacity. Implemented with a **doubly linked list** (O(1) move/remove) + **hash map** (O(1) lookup):

```csharp
class LRUCache
{
    private int _capacity;
    private Dictionary<int, LinkedListNode<(int key, int val)>> _map = new();
    private LinkedList<(int key, int val)> _list = new();

    public LRUCache(int capacity) => _capacity = capacity;

    public int Get(int key)
    {
        if (!_map.TryGetValue(key, out var node)) return -1;
        _list.Remove(node);
        _list.AddFirst(node); // move to front (most recent)
        return node.Value.val;
    }

    public void Put(int key, int value)
    {
        if (_map.TryGetValue(key, out var node)) _list.Remove(node);
        else if (_map.Count == _capacity)
        {
            _map.Remove(_list.Last!.Value.key); // evict LRU
            _list.RemoveLast();
        }
        var newNode = _list.AddFirst((key, value));
        _map[key] = newNode;
    }
}
```

All operations are O(1).
