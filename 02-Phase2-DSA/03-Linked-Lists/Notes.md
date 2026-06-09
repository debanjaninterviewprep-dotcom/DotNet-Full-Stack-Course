# Topic 3: Linked Lists

## What is a Linked List?

A linked list is a **linear data structure** where elements (nodes) are stored in **non-contiguous memory**. Each node contains data and a **pointer/reference** to the next node.

```
Array (contiguous):
[10][20][30][40][50]  — all in a row in memory

Linked List (scattered):
[10|→] → [20|→] → [30|→] → [40|→] → [50|null]
 Node1     Node2     Node3     Node4     Node5
 @0x100    @0x500    @0x200    @0x800    @0x350
```

---

## Array vs Linked List

| Feature | Array | Linked List |
|---|---|---|
| Memory layout | Contiguous | Scattered |
| Access by index | O(1) | O(n) |
| Insert at beginning | O(n) | O(1) |
| Insert at end | O(1) amortized | O(n) or O(1) with tail |
| Insert at middle | O(n) | O(1) once position found |
| Delete | O(n) | O(1) once position found |
| Memory overhead | None | Extra pointer per node |
| Cache performance | Excellent | Poor (non-contiguous) |

---

## Singly Linked List

### Node Structure

```csharp
public class ListNode
{
    public int Val;
    public ListNode? Next;
    
    public ListNode(int val, ListNode? next = null)
    {
        Val = val;
        Next = next;
    }
}
```

### Building a Linked List

```csharp
public class SinglyLinkedList
{
    public ListNode? Head;
    private int _count;
    
    // Insert at beginning — O(1)
    public void InsertAtHead(int val)
    {
        ListNode newNode = new ListNode(val);
        newNode.Next = Head;
        Head = newNode;
        _count++;
    }
    
    // Insert at end — O(n) (O(1) if we maintain a tail pointer)
    public void InsertAtTail(int val)
    {
        ListNode newNode = new ListNode(val);
        if (Head == null)
        {
            Head = newNode;
        }
        else
        {
            ListNode current = Head;
            while (current.Next != null)
                current = current.Next;
            current.Next = newNode;
        }
        _count++;
    }
    
    // Insert at position — O(n)
    public void InsertAt(int index, int val)
    {
        if (index == 0) { InsertAtHead(val); return; }
        
        ListNode current = Head!;
        for (int i = 0; i < index - 1; i++)
            current = current.Next!;
        
        ListNode newNode = new ListNode(val, current.Next);
        current.Next = newNode;
        _count++;
    }
    
    // Delete by value — O(n)
    public bool Delete(int val)
    {
        if (Head == null) return false;
        
        if (Head.Val == val)
        {
            Head = Head.Next;
            _count--;
            return true;
        }
        
        ListNode current = Head;
        while (current.Next != null)
        {
            if (current.Next.Val == val)
            {
                current.Next = current.Next.Next;
                _count--;
                return true;
            }
            current = current.Next;
        }
        return false;
    }
    
    // Search — O(n)
    public bool Contains(int val)
    {
        ListNode? current = Head;
        while (current != null)
        {
            if (current.Val == val) return true;
            current = current.Next;
        }
        return false;
    }
    
    // Print list
    public void Print()
    {
        ListNode? current = Head;
        while (current != null)
        {
            Console.Write($"{current.Val} → ");
            current = current.Next;
        }
        Console.WriteLine("null");
    }
    
    public int Count => _count;
}
```

### Usage

```csharp
var list = new SinglyLinkedList();
list.InsertAtTail(10);
list.InsertAtTail(20);
list.InsertAtTail(30);
list.InsertAtHead(5);
list.Print(); // 5 → 10 → 20 → 30 → null

list.Delete(20);
list.Print(); // 5 → 10 → 30 → null
```

---

## Doubly Linked List

Each node has pointers to **both next and previous** nodes.

```
null ← [10] ⇄ [20] ⇄ [30] ⇄ [40] → null
        Head                    Tail
```

```csharp
public class DoublyNode
{
    public int Val;
    public DoublyNode? Next;
    public DoublyNode? Prev;
    
    public DoublyNode(int val) { Val = val; }
}

public class DoublyLinkedList
{
    public DoublyNode? Head;
    public DoublyNode? Tail;
    private int _count;
    
    // Insert at head — O(1)
    public void InsertAtHead(int val)
    {
        DoublyNode newNode = new DoublyNode(val);
        if (Head == null)
        {
            Head = Tail = newNode;
        }
        else
        {
            newNode.Next = Head;
            Head.Prev = newNode;
            Head = newNode;
        }
        _count++;
    }
    
    // Insert at tail — O(1) because we maintain Tail pointer
    public void InsertAtTail(int val)
    {
        DoublyNode newNode = new DoublyNode(val);
        if (Tail == null)
        {
            Head = Tail = newNode;
        }
        else
        {
            Tail.Next = newNode;
            newNode.Prev = Tail;
            Tail = newNode;
        }
        _count++;
    }
    
    // Delete a node — O(1) if you have the node reference
    public void DeleteNode(DoublyNode node)
    {
        if (node.Prev != null) node.Prev.Next = node.Next;
        else Head = node.Next; // Deleting head
        
        if (node.Next != null) node.Next.Prev = node.Prev;
        else Tail = node.Prev; // Deleting tail
        
        _count--;
    }
    
    // Print forward and backward
    public void PrintForward()
    {
        DoublyNode? current = Head;
        while (current != null)
        {
            Console.Write($"{current.Val} ⇄ ");
            current = current.Next;
        }
        Console.WriteLine("null");
    }
    
    public void PrintBackward()
    {
        DoublyNode? current = Tail;
        while (current != null)
        {
            Console.Write($"{current.Val} ⇄ ");
            current = current.Prev;
        }
        Console.WriteLine("null");
    }
}
```

---

## Common Linked List Techniques

### Technique 1: Runner (Fast & Slow Pointer)

Two pointers move at different speeds. Detects cycles and finds midpoints.

```csharp
// Find middle of linked list — O(n) time, O(1) space
ListNode FindMiddle(ListNode head)
{
    ListNode slow = head, fast = head;
    while (fast?.Next != null)
    {
        slow = slow.Next!;
        fast = fast.Next.Next;
    }
    return slow;
}
// [1] → [2] → [3] → [4] → [5]
//                ↑ slow stops here (middle)
```

### Technique 2: Cycle Detection (Floyd's Algorithm)

```csharp
// Detect if linked list has a cycle — O(n) time, O(1) space
bool HasCycle(ListNode? head)
{
    ListNode? slow = head, fast = head;
    while (fast?.Next != null)
    {
        slow = slow!.Next;
        fast = fast.Next.Next;
        if (slow == fast) return true; // They meet — cycle exists!
    }
    return false;
}

// Find the START of the cycle
ListNode? FindCycleStart(ListNode? head)
{
    ListNode? slow = head, fast = head;
    
    // Phase 1: Detect cycle
    while (fast?.Next != null)
    {
        slow = slow!.Next;
        fast = fast.Next.Next;
        if (slow == fast) break;
    }
    
    if (fast?.Next == null) return null; // No cycle
    
    // Phase 2: Find start — move one pointer to head, advance both by 1
    slow = head;
    while (slow != fast)
    {
        slow = slow!.Next;
        fast = fast!.Next;
    }
    return slow; // This is the cycle start
}
```

### Technique 3: Reverse a Linked List

```csharp
// Iterative reverse — O(n) time, O(1) space
ListNode? ReverseIterative(ListNode? head)
{
    ListNode? prev = null;
    ListNode? current = head;
    
    while (current != null)
    {
        ListNode? next = current.Next; // Save next
        current.Next = prev;           // Reverse pointer
        prev = current;                // Move prev forward
        current = next;                // Move current forward
    }
    return prev; // New head
}

// Visualization:
// null ← [1] ← [2] ← [3]   [4] → [5] → null
//         ↑              ↑     ↑
//       (done)         prev  current

// Recursive reverse — O(n) time, O(n) space (stack)
ListNode? ReverseRecursive(ListNode? head)
{
    if (head?.Next == null) return head;
    
    ListNode? newHead = ReverseRecursive(head.Next);
    head.Next.Next = head; // Point next node back to current
    head.Next = null;       // Remove forward pointer
    return newHead;
}
```

### Technique 4: Dummy Node

A dummy node simplifies edge cases (empty list, inserting at head).

```csharp
// Merge two sorted lists — O(n + m) time, O(1) space
ListNode MergeTwoSorted(ListNode? l1, ListNode? l2)
{
    ListNode dummy = new ListNode(0); // Dummy node
    ListNode current = dummy;
    
    while (l1 != null && l2 != null)
    {
        if (l1.Val <= l2.Val)
        {
            current.Next = l1;
            l1 = l1.Next;
        }
        else
        {
            current.Next = l2;
            l2 = l2.Next;
        }
        current = current.Next;
    }
    
    current.Next = l1 ?? l2; // Attach remaining
    return dummy.Next!;       // Skip dummy
}
```

### Technique 5: Recursive Linked List Manipulation

```csharp
// Remove all nodes with a given value — recursive
ListNode? RemoveElements(ListNode? head, int val)
{
    if (head == null) return null;
    head.Next = RemoveElements(head.Next, val);
    return head.Val == val ? head.Next : head;
}

// Print list in reverse order (without modifying it)
void PrintReverse(ListNode? node)
{
    if (node == null) return;
    PrintReverse(node.Next); // Go to end first
    Console.Write($"{node.Val} "); // Print on the way back
}
```

---

## LinkedList\<T\> in C# (.NET)

C# has a built-in `LinkedList<T>` (doubly linked):

```csharp
LinkedList<int> list = new LinkedList<int>();

// Add elements
list.AddLast(10);
list.AddLast(20);
list.AddFirst(5);

LinkedListNode<int> node20 = list.Find(20)!;
list.AddBefore(node20, 15);
list.AddAfter(node20, 25);

// Iterate
foreach (int val in list)
    Console.Write($"{val} → ");
// 5 → 10 → 15 → 20 → 25 →

// Remove
list.Remove(15);
list.RemoveFirst();
list.RemoveLast();
```

---

## Complexity Summary

| Operation | Singly | Doubly | Array/List\<T\> |
|---|---|---|---|
| Access by index | O(n) | O(n) | O(1) |
| Insert at head | O(1) | O(1) | O(n) |
| Insert at tail | O(n)* | O(1) | O(1) amortized |
| Insert in middle | O(n) | O(1)** | O(n) |
| Delete head | O(1) | O(1) | O(n) |
| Delete tail | O(n) | O(1) | O(1) |
| Search | O(n) | O(n) | O(n) |

*O(1) with tail pointer | **O(1) if you have the node reference

---

## When to Use Linked Lists

| Use Case | Why |
|---|---|
| Frequent insertions/deletions at beginning | O(1) vs O(n) for arrays |
| Implementing stacks and queues | Natural fit |
| LRU Cache | Doubly linked list + HashMap |
| Polynomial math | Each node = term |
| Undo functionality | Each state = a node |

---

## Key Takeaways

| Concept | Summary |
|---|---|
| Singly linked | Each node points to next only |
| Doubly linked | Each node points to next and previous |
| Fast/slow pointer | Detect cycles, find middle |
| Dummy node | Simplifies edge cases |
| Reverse a list | Three pointers: prev, current, next |
| Merge two sorted | Dummy node + comparison |
| Cycle detection | Floyd's algorithm (tortoise and hare) |
| O(1) insert at head | Main advantage over arrays |

---

*Next Topic: Stacks & Queues →*
