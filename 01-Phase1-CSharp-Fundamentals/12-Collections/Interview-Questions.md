# Topic 12: Collections — Interview Questions

---

## Q1. What is the difference between `IEnumerable<T>`, `ICollection<T>`, and `IList<T>`?
**Answer:**
These are layered interfaces — each builds on the previous:

| Interface | Adds over previous | Key capability |
|---|---|---|
| `IEnumerable<T>` | — | Forward-only iteration (`foreach`) |
| `ICollection<T>` | `IEnumerable<T>` | Count, Add, Remove, Contains |
| `IList<T>` | `ICollection<T>` | Index-based access (`list[i]`), Insert, RemoveAt |

```csharp
IEnumerable<int> e = GetNumbers();    // iterate only
ICollection<int> c = new List<int>(); // add/remove/count
IList<int>       l = new List<int>(); // index access
```

**Best practice:** Accept the **most general** interface your code needs in method parameters (prefer `IEnumerable<T>` for read-only iteration) to allow callers to pass any compatible type.

---

## Q2. What is the difference between `List<T>` and `LinkedList<T>`?
**Answer:**
| | `List<T>` | `LinkedList<T>` |
|---|---|---|
| **Internal structure** | Dynamic array | Doubly linked list of `LinkedListNode<T>` |
| **Random access** | O(1) | O(n) |
| **Insert/remove at middle** | O(n) (shifts elements) | O(1) (adjust pointers) |
| **Memory** | Contiguous — cache friendly | Non-contiguous nodes — more allocation |
| **Use case** | Most scenarios | Frequent insert/delete at arbitrary positions |

In practice, `List<T>` is faster for most use cases due to CPU cache locality. Use `LinkedList<T>` only when you have a proved need for O(1) insertions/deletions.

---

## Q3. What is `Dictionary<TKey, TValue>` and how does it work internally?
**Answer:**
`Dictionary<TKey, TValue>` is a hash table. It stores key-value pairs and provides O(1) average-case lookups, inserts, and deletes.

Internally:
1. Calls `GetHashCode()` on the key to determine a bucket index.
2. Handles hash collisions with chaining.
3. Resizes (rehashes) when the load factor exceeds a threshold.

```csharp
var dict = new Dictionary<string, int>();
dict["Alice"] = 90;
dict.Add("Bob", 85);

int score = dict["Alice"];          // O(1)
dict.TryGetValue("Charlie", out int s); // safe — no exception if missing

foreach (var (key, value) in dict)
    Console.WriteLine($"{key}: {value}");
```

**Requirements:** Keys must correctly implement `GetHashCode()` and `Equals()`. Two keys that are equal must return the same hash code.

---

## Q4. What is the difference between `Dictionary` and `SortedDictionary`?
**Answer:**
| | `Dictionary<K,V>` | `SortedDictionary<K,V>` | `SortedList<K,V>` |
|---|---|---|---|
| **Internal structure** | Hash table | Red-black tree | Two sorted arrays |
| **Lookup** | O(1) average | O(log n) | O(log n) |
| **Ordered iteration** | No | Yes (sorted by key) | Yes (sorted by key) |
| **Memory** | Moderate | More (tree nodes) | Less |
| **Insert/delete** | O(1) average | O(log n) | O(n) |

Use `SortedDictionary` when you need ordered iteration and frequent insertions. Use `SortedList` when memory is tight and data is mostly read.

---

## Q5. What is `HashSet<T>` and when do you use it?
**Answer:**
`HashSet<T>` is an unordered set of **unique** values. It offers O(1) average-case `Add`, `Remove`, and `Contains`.

```csharp
var set = new HashSet<int> { 1, 2, 3 };
set.Add(2);           // ignored — already exists
set.Contains(3);      // true — O(1)

var set2 = new HashSet<int> { 2, 3, 4 };
set.UnionWith(set2);        // { 1, 2, 3, 4 }
set.IntersectWith(set2);    // { 2, 3 }
set.ExceptWith(set2);       // { 1 }
```

Use `HashSet<T>` when you need **deduplication** or fast membership testing. Elements must correctly implement `GetHashCode()` and `Equals()`.

---

## Q6. What is the difference between `Stack<T>` and `Queue<T>`?
**Answer:**
| | `Stack<T>` | `Queue<T>` |
|---|---|---|
| **Order** | LIFO — Last In First Out | FIFO — First In First Out |
| **Add** | `Push(item)` | `Enqueue(item)` |
| **Remove** | `Pop()` | `Dequeue()` |
| **Peek** | `Peek()` (top) | `Peek()` (front) |
| **Use case** | Undo/redo, call stacks, DFS | Task queues, BFS, message buffers |

```csharp
var stack = new Stack<int>();
stack.Push(1); stack.Push(2); stack.Push(3);
stack.Pop();   // returns 3 (LIFO)

var queue = new Queue<string>();
queue.Enqueue("A"); queue.Enqueue("B");
queue.Dequeue(); // returns "A" (FIFO)
```

---

## Q7. What are `ConcurrentDictionary` and other concurrent collections?
**Answer:**
Standard collections are **not thread-safe**. `System.Collections.Concurrent` provides thread-safe alternatives:

| Type | Thread-safe equivalent of |
|---|---|
| `ConcurrentDictionary<K,V>` | `Dictionary<K,V>` |
| `ConcurrentQueue<T>` | `Queue<T>` |
| `ConcurrentStack<T>` | `Stack<T>` |
| `ConcurrentBag<T>` | Unordered bag (no `List` equivalent) |
| `BlockingCollection<T>` | Producer-consumer buffer |

```csharp
var dict = new ConcurrentDictionary<string, int>();
dict.AddOrUpdate("count", 1, (key, old) => old + 1); // atomic
dict.GetOrAdd("new", 0);
```

`ConcurrentDictionary` uses fine-grained locking (lock striping) — multiple readers/writers can proceed simultaneously on different buckets.

---

## Q8. What is the difference between `List<T>.Remove()` and `List<T>.RemoveAll()`?
**Answer:**
- `Remove(T item)` — removes the **first occurrence** of the item. Returns `bool`.
- `RemoveAt(int index)` — removes the item at a specific index.
- `RemoveAll(Predicate<T>)` — removes **all elements** matching the predicate. Returns count removed.

```csharp
var list = new List<int> { 1, 2, 3, 2, 4 };

list.Remove(2);              // Removes first 2 → { 1, 3, 2, 4 }
list.RemoveAt(0);            // Removes index 0 → { 3, 2, 4 }
list.RemoveAll(x => x > 2); // Removes 3, 4 → { 2 }
```

Do **not** remove elements from a `List<T>` while iterating with `foreach` — use `RemoveAll` or iterate a copy.

---

## Q9. What is `IReadOnlyList<T>` and `IReadOnlyDictionary<K,V>`?
**Answer:**
These read-only interfaces expose collections without `Add`/`Remove` methods, preventing callers from modifying them while still allowing iteration and indexed access:

```csharp
class OrderService
{
    private List<Order> _orders = new();

    // Expose as read-only — callers cannot call Add/Remove
    public IReadOnlyList<Order> Orders => _orders.AsReadOnly();
}
```

Note: The underlying list is still mutable — this is a **view**, not a copy. For full immutability, use `ImmutableList<T>` from `System.Collections.Immutable`.

---

## Q10. What is `ArraySegment<T>` and when is it useful?
**Answer:**
`ArraySegment<T>` is a lightweight struct that represents a **slice** of an array without copying:

```csharp
int[] data = { 0, 1, 2, 3, 4, 5 };
var segment = new ArraySegment<int>(data, 2, 3); // elements [2, 3, 4]

foreach (int n in segment) Console.Write(n + " "); // 2 3 4
```

Used in networking code (e.g., `Socket.Send(ArraySegment<byte>)`), memory buffers, and any scenario where you want to work on a portion of an array without allocation. In modern .NET, `Span<T>` and `Memory<T>` are preferred for new code.

---

## Q11. What is `PriorityQueue<TElement, TPriority>` (.NET 6+)?
**Answer:**
`PriorityQueue<TElement, TPriority>` is a min-heap — the element with the **lowest priority value** is dequeued first:

```csharp
var pq = new PriorityQueue<string, int>();
pq.Enqueue("Low priority task",  3);
pq.Enqueue("High priority task", 1);
pq.Enqueue("Medium task",        2);

pq.Dequeue(); // "High priority task" (priority 1 is smallest — min-heap)
pq.Dequeue(); // "Medium task"
pq.Dequeue(); // "Low priority task"

// Peek without removing
var (element, priority) = pq.Peek();
```

Use cases: Dijkstra's algorithm, task scheduling, event-driven simulations. For a max-heap, negate the priority value.

---

## Q12. What is `ObservableCollection<T>` and when is it used?
**Answer:**
`ObservableCollection<T>` extends `List<T>` with a `CollectionChanged` event that fires when items are added, removed, or the list is cleared. It is the standard collection for **UI data binding** in WPF and MAUI:

```csharp
var users = new ObservableCollection<string>();
users.CollectionChanged += (sender, e) =>
{
    Console.WriteLine($"Action: {e.Action}"); // Add, Remove, Reset, etc.
};

users.Add("Alice");    // fires CollectionChanged with Action=Add
users.Remove("Alice"); // fires CollectionChanged with Action=Remove
```

**Limitation:** UI frameworks require collection changes to happen on the **UI thread**. For background updates, marshal back to the UI thread or use a synchronized wrapper.

---

## Q13. What are `ImmutableList<T>` and immutable collections?
**Answer:**
Immutable collections (`System.Collections.Immutable`) cannot be modified after creation. All operations return **new collections** with the modification applied:

```csharp
using System.Collections.Immutable;

var list = ImmutableList.Create(1, 2, 3);
var list2 = list.Add(4);        // new list: 1,2,3,4 — original unchanged
var list3 = list.Remove(1);     // new list: 2,3
var dict  = ImmutableDictionary.Create<string, int>().Add("a", 1);
```

Benefits:
- **Thread-safe by nature** — no locks needed for reads.
- **Structural sharing** — unchanged parts are shared between old and new collections (tree-based internally).

Use when collections are shared across threads or need to act as snapshots.

---

## Q14. How does `List<T>` manage capacity internally?
**Answer:**
`List<T>` uses a dynamic array that **doubles in capacity** when full:

```csharp
var list = new List<int>();      // Capacity = 0
list.Add(1);                      // Capacity = 4  (first growth)
// ... add to 4
list.Add(5);                      // Capacity = 8  (doubles)
// ... add to 8
list.Add(9);                      // Capacity = 16 (doubles)

Console.WriteLine(list.Count);    // 9  (actual items)
Console.WriteLine(list.Capacity); // 16 (allocated slots)

// Pre-allocate when count is known — avoids repeated reallocation
var efficient = new List<int>(capacity: 1000);

// Release excess memory
list.TrimExcess();
```

Each resize copies all elements to a new array — amortized O(1) per add, O(n) worst case per resize. Pre-specify capacity to avoid resizes when the approximate count is known.

---

## Q15. What is the difference between `List<T>` and `Collection<T>`?
**Answer:**
| | `List<T>` | `Collection<T>` |
|---|---|---|
| **Namespace** | `System.Collections.Generic` | `System.Collections.ObjectModel` |
| **Extensibility** | Sealed — cannot override insert/remove | Virtual `InsertItem`, `RemoveItem`, `SetItem` methods |
| **Use case** | Internal storage, implementation detail | Base class for custom collections with hooks |
| **Protected hooks** | None | `InsertItem`, `RemoveItem`, `ClearItems`, `SetItem` |

```csharp
class ValidatedCollection : Collection<string>
{
    protected override void InsertItem(int index, string item)
    {
        if (string.IsNullOrWhiteSpace(item))
            throw new ArgumentException("Empty strings not allowed");
        base.InsertItem(index, item);
    }
}
```

Expose `Collection<T>` (or `IList<T>`) in public APIs, not `List<T>` — this follows the guideline of returning the most general appropriate type.
