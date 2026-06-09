# Topic 12: Collections (List, Dictionary, HashSet, etc.)

## Why Collections Over Arrays?

Arrays have a **fixed size** — once created, you can't add or remove elements. Collections are **dynamic**, resizable, and come with powerful built-in methods.

```csharp
// Array — fixed size
int[] numbers = new int[3]; // Always 3 elements
// numbers[3] = 4; // 💥 IndexOutOfRangeException

// List — dynamic size
List<int> nums = new List<int>();
nums.Add(1);
nums.Add(2);
nums.Add(3);
nums.Add(4); // ✅ No problem — grows automatically
```

---

## The Collections Hierarchy

```
IEnumerable<T>          ← Can be iterated (foreach)
│
├── ICollection<T>      ← Has Count, Add, Remove, Contains
│   │
│   ├── IList<T>        ← Has index-based access [i]
│   │   └── List<T>     ★ Most commonly used
│   │
│   ├── ISet<T>         ← No duplicates
│   │   ├── HashSet<T>  ★ Fast lookups, no duplicates
│   │   └── SortedSet<T>
│   │
│   └── IDictionary<TKey, TValue>  ← Key-Value pairs
│       ├── Dictionary<TKey, TValue>  ★ Fast key lookup
│       └── SortedDictionary<TKey, TValue>
│
├── Queue<T>            ★ First-In-First-Out (FIFO)
├── Stack<T>            ★ Last-In-First-Out (LIFO)
└── LinkedList<T>       ← Doubly-linked list
```

---

## List\<T\> — The Workhorse Collection

### Creating Lists

```csharp
// Empty list
List<string> names = new List<string>();

// With initial values (collection initializer)
List<int> scores = new List<int> { 85, 92, 78, 95, 88 };

// From an array
int[] arr = { 1, 2, 3 };
List<int> fromArray = new List<int>(arr);

// With capacity hint (optimization — avoids resizing)
List<string> bigList = new List<string>(1000);
```

### Adding Elements

```csharp
List<string> fruits = new List<string>();

fruits.Add("Apple");                    // Add to end
fruits.Add("Banana");
fruits.Insert(1, "Cherry");            // Insert at index 1
fruits.AddRange(new[] { "Date", "Elderberry" }); // Add multiple

// fruits: [Apple, Cherry, Banana, Date, Elderberry]
```

### Removing Elements

```csharp
List<string> fruits = new List<string> { "Apple", "Banana", "Cherry", "Banana", "Date" };

fruits.Remove("Banana");       // Removes FIRST occurrence → [Apple, Cherry, Banana, Date]
fruits.RemoveAt(0);            // Removes at index 0 → [Cherry, Banana, Date]
fruits.RemoveAll(f => f.StartsWith("D")); // Removes all matching → [Cherry, Banana]
fruits.Clear();                // Removes everything → []
```

### Searching & Checking

```csharp
List<int> numbers = new List<int> { 10, 20, 30, 40, 50, 30 };

bool has30 = numbers.Contains(30);       // true
int index = numbers.IndexOf(30);         // 2 (first occurrence)
int lastIndex = numbers.LastIndexOf(30); // 5 (last occurrence)
int found = numbers.Find(n => n > 25);   // 30 (first match)
List<int> all = numbers.FindAll(n => n > 25); // [30, 40, 50, 30]
bool anyOver40 = numbers.Exists(n => n > 40); // true
bool allPositive = numbers.TrueForAll(n => n > 0); // true
```

### Sorting & Reversing

```csharp
List<int> nums = new List<int> { 5, 2, 8, 1, 9 };

nums.Sort();                    // [1, 2, 5, 8, 9] — ascending
nums.Reverse();                 // [9, 8, 5, 2, 1] — reverses current order
nums.Sort((a, b) => b - a);    // [9, 8, 5, 2, 1] — descending with custom comparer

// Sort strings by length
List<string> words = new List<string> { "cat", "elephant", "bee", "dog" };
words.Sort((a, b) => a.Length.CompareTo(b.Length));
// [bee, cat, dog, elephant]
```

### Converting

```csharp
List<int> numbers = new List<int> { 1, 2, 3, 4, 5 };

int[] array = numbers.ToArray();
List<string> strings = numbers.ConvertAll(n => n.ToString());
// ["1", "2", "3", "4", "5"]
```

### Iterating

```csharp
List<string> names = new List<string> { "Alice", "Bob", "Charlie" };

// foreach
foreach (string name in names)
    Console.WriteLine(name);

// for loop (when you need the index)
for (int i = 0; i < names.Count; i++)
    Console.WriteLine($"{i}: {names[i]}");

// ForEach method
names.ForEach(name => Console.WriteLine(name));
```

---

## Dictionary\<TKey, TValue\> — Key-Value Pairs

### Creating Dictionaries

```csharp
// Empty
Dictionary<string, int> ages = new Dictionary<string, int>();

// With initializer
Dictionary<string, int> scores = new Dictionary<string, int>
{
    { "Debanjan", 95 },
    { "Alice", 88 },
    { "Bob", 72 }
};

// Modern syntax (index initializer)
Dictionary<string, string> config = new Dictionary<string, string>
{
    ["Host"] = "localhost",
    ["Port"] = "5432",
    ["Database"] = "TaskFlow"
};
```

### Adding & Updating

```csharp
Dictionary<string, int> inventory = new Dictionary<string, int>();

// Add
inventory.Add("Laptop", 50);       // Throws if key exists!
inventory["Mouse"] = 200;          // Adds OR updates (safer)
inventory.TryAdd("Laptop", 100);   // Returns false if key exists (no exception)

// Update
inventory["Laptop"] = 45;          // Update existing

// Conditional update
if (inventory.ContainsKey("Laptop"))
    inventory["Laptop"] -= 5;
```

### Accessing Values Safely

```csharp
Dictionary<string, int> ages = new Dictionary<string, int>
{
    ["Debanjan"] = 25,
    ["Alice"] = 30
};

// ❌ Throws KeyNotFoundException if key doesn't exist
// int age = ages["Unknown"];

// ✅ Safe access with TryGetValue
if (ages.TryGetValue("Bob", out int bobAge))
{
    Console.WriteLine($"Bob is {bobAge}");
}
else
{
    Console.WriteLine("Bob not found.");
}

// ✅ Check first
if (ages.ContainsKey("Debanjan"))
    Console.WriteLine($"Debanjan is {ages["Debanjan"]}");

// ✅ GetValueOrDefault (C# 7.1+)
int unknownAge = ages.GetValueOrDefault("Unknown", -1); // -1
```

### Removing

```csharp
Dictionary<string, int> data = new Dictionary<string, int>
{
    ["A"] = 1, ["B"] = 2, ["C"] = 3
};

data.Remove("B");                       // Remove by key
data.Remove("D", out int removedValue); // Returns false if key doesn't exist
data.Clear();                           // Remove all
```

### Iterating

```csharp
Dictionary<string, int> scores = new Dictionary<string, int>
{
    ["Debanjan"] = 95, ["Alice"] = 88, ["Bob"] = 72
};

// KeyValuePair
foreach (KeyValuePair<string, int> pair in scores)
    Console.WriteLine($"{pair.Key}: {pair.Value}");

// Deconstruction (cleaner)
foreach (var (name, score) in scores)
    Console.WriteLine($"{name}: {score}");

// Keys only
foreach (string name in scores.Keys)
    Console.WriteLine(name);

// Values only
foreach (int score in scores.Values)
    Console.WriteLine(score);
```

### Word Frequency Counter Example

```csharp
string text = "the cat sat on the mat the cat";
string[] words = text.Split(' ');

Dictionary<string, int> frequency = new Dictionary<string, int>();
foreach (string word in words)
{
    if (frequency.ContainsKey(word))
        frequency[word]++;
    else
        frequency[word] = 1;
}

// Cleaner with TryGetValue
foreach (string word in words)
{
    frequency.TryGetValue(word, out int count);
    frequency[word] = count + 1;
}

foreach (var (word, count) in frequency)
    Console.WriteLine($"'{word}' → {count}");
// 'the' → 3, 'cat' → 2, 'sat' → 1, 'on' → 1, 'mat' → 1
```

---

## HashSet\<T\> — Unique Elements Only

HashSet stores **unique values** with **O(1)** lookup time. No duplicates allowed.

### Creating HashSets

```csharp
HashSet<string> tags = new HashSet<string>();
HashSet<int> numbers = new HashSet<int> { 1, 2, 3, 4, 5 };

// Duplicates are silently ignored
HashSet<int> nums = new HashSet<int> { 1, 2, 2, 3, 3, 3 };
// nums: {1, 2, 3} — only 3 elements
```

### Adding & Removing

```csharp
HashSet<string> skills = new HashSet<string>();

bool added1 = skills.Add("C#");      // true — added
bool added2 = skills.Add("C#");      // false — already exists
skills.Add("Angular");
skills.Add("SQL");

skills.Remove("SQL");                 // true — removed
skills.RemoveWhere(s => s.StartsWith("A")); // Remove matching condition
```

### Set Operations

This is where HashSet truly shines:

```csharp
HashSet<string> frontEnd = new HashSet<string> { "HTML", "CSS", "JavaScript", "Angular", "React" };
HashSet<string> backEnd = new HashSet<string> { "C#", "SQL", "JavaScript", "Node.js" };

// Union — all unique elements from both sets
HashSet<string> allSkills = new HashSet<string>(frontEnd);
allSkills.UnionWith(backEnd);
// {HTML, CSS, JavaScript, Angular, React, C#, SQL, Node.js}

// Intersection — elements in BOTH sets
HashSet<string> shared = new HashSet<string>(frontEnd);
shared.IntersectWith(backEnd);
// {JavaScript}

// Difference — in frontEnd but NOT in backEnd
HashSet<string> frontOnly = new HashSet<string>(frontEnd);
frontOnly.ExceptWith(backEnd);
// {HTML, CSS, Angular, React}

// Symmetric Difference — in one OR the other, but NOT both
HashSet<string> exclusive = new HashSet<string>(frontEnd);
exclusive.SymmetricExceptWith(backEnd);
// {HTML, CSS, Angular, React, C#, SQL, Node.js}

// Subset / Superset checks
bool isSubset = frontEnd.IsSubsetOf(allSkills);     // true
bool isSuperset = allSkills.IsSupersetOf(frontEnd);  // true
bool overlaps = frontEnd.Overlaps(backEnd);           // true (JavaScript)
```

### When to Use HashSet

| Use Case | Why |
|---|---|
| Remove duplicates from a list | `new HashSet<T>(list)` |
| Fast membership checking | `Contains` is O(1) |
| Set math (union, intersection) | Built-in methods |
| Track "visited" items | No accidental duplicates |

---

## Queue\<T\> — First-In, First-Out (FIFO)

Like a real queue (line at a store) — first person in line gets served first.

```csharp
Queue<string> printQueue = new Queue<string>();

// Enqueue — add to the BACK
printQueue.Enqueue("Document1.pdf");
printQueue.Enqueue("Photo.jpg");
printQueue.Enqueue("Report.docx");

Console.WriteLine($"Items in queue: {printQueue.Count}"); // 3

// Peek — look at the FRONT without removing
string next = printQueue.Peek(); // "Document1.pdf"

// Dequeue — remove from the FRONT
string printed = printQueue.Dequeue(); // "Document1.pdf" — removed
Console.WriteLine($"Printing: {printed}");
Console.WriteLine($"Next up: {printQueue.Peek()}"); // "Photo.jpg"

// Safe dequeue
if (printQueue.TryDequeue(out string? item))
    Console.WriteLine($"Printing: {item}");

// TryPeek
if (printQueue.TryPeek(out string? nextItem))
    Console.WriteLine($"Next: {nextItem}");

// Contains
bool hasReport = printQueue.Contains("Report.docx"); // true

// Process all items
while (printQueue.Count > 0)
{
    Console.WriteLine($"Printing: {printQueue.Dequeue()}");
}
```

---

## Stack\<T\> — Last-In, First-Out (LIFO)

Like a stack of plates — the last plate placed on top is the first one taken off.

```csharp
Stack<string> undoHistory = new Stack<string>();

// Push — add to the TOP
undoHistory.Push("Type 'Hello'");
undoHistory.Push("Bold text");
undoHistory.Push("Change font size");

Console.WriteLine($"Last action: {undoHistory.Peek()}"); // "Change font size"

// Pop — remove from TOP
string undone = undoHistory.Pop(); // "Change font size" — removed
Console.WriteLine($"Undo: {undone}");

// Safe pop
if (undoHistory.TryPop(out string? action))
    Console.WriteLine($"Undo: {action}");

// Process all (undo everything)
while (undoHistory.Count > 0)
{
    Console.WriteLine($"Undo: {undoHistory.Pop()}");
}
```

### Bracket Matching Example

```csharp
bool IsBalanced(string expression)
{
    Stack<char> stack = new Stack<char>();
    Dictionary<char, char> pairs = new Dictionary<char, char>
    {
        { ')', '(' }, { ']', '[' }, { '}', '{' }
    };

    foreach (char ch in expression)
    {
        if (ch == '(' || ch == '[' || ch == '{')
        {
            stack.Push(ch);
        }
        else if (pairs.ContainsKey(ch))
        {
            if (stack.Count == 0 || stack.Pop() != pairs[ch])
                return false;
        }
    }
    return stack.Count == 0;
}

Console.WriteLine(IsBalanced("({[]})")); // true
Console.WriteLine(IsBalanced("({[}])"));  // false
Console.WriteLine(IsBalanced("((())"));   // false
```

---

## LinkedList\<T\> — Doubly-Linked List

Efficient insertion/removal at **any position** (O(1) once you have the node), but no index access.

```csharp
LinkedList<string> playlist = new LinkedList<string>();

// Add items
playlist.AddLast("Song A");
playlist.AddLast("Song B");
playlist.AddFirst("Intro");
playlist.AddLast("Song C");

// Find a node and insert around it
LinkedListNode<string>? nodeB = playlist.Find("Song B");
if (nodeB != null)
{
    playlist.AddBefore(nodeB, "Interlude");
    playlist.AddAfter(nodeB, "Song B Remix");
}

// Iterate forward
foreach (string song in playlist)
    Console.Write($"{song} → ");
// Intro → Song A → Interlude → Song B → Song B Remix → Song C →

// Remove
playlist.Remove("Interlude");
playlist.RemoveFirst();
playlist.RemoveLast();
```

---

## SortedDictionary & SortedSet — Auto-Sorted Collections

```csharp
// SortedDictionary — keys are always sorted
SortedDictionary<string, int> leaderboard = new SortedDictionary<string, int>
{
    ["Charlie"] = 75,
    ["Alice"] = 95,
    ["Bob"] = 88
};

foreach (var (name, score) in leaderboard)
    Console.WriteLine($"{name}: {score}");
// Alice: 95 (sorted alphabetically by key)
// Bob: 88
// Charlie: 75

// SortedSet — unique elements, always sorted
SortedSet<int> sortedNums = new SortedSet<int> { 5, 2, 8, 1, 9, 3 };
foreach (int n in sortedNums)
    Console.Write($"{n} "); // 1 2 3 5 8 9
```

---

## Choosing the Right Collection

| Need | Use | Why |
|---|---|---|
| Ordered list with index access | `List<T>` | Flexible, index access, most common |
| Key-value lookup | `Dictionary<TKey,TValue>` | O(1) lookup by key |
| Unique elements | `HashSet<T>` | No duplicates, O(1) contains |
| FIFO processing | `Queue<T>` | First in, first out |
| LIFO / undo operations | `Stack<T>` | Last in, first out |
| Frequent insert/delete in middle | `LinkedList<T>` | O(1) insert/delete at node |
| Sorted key-value pairs | `SortedDictionary<TKey,TValue>` | Auto-sorted by key |
| Sorted unique elements | `SortedSet<T>` | Auto-sorted, no duplicates |

---

## Read-Only Collections

When you want to expose a collection but prevent external modification:

```csharp
public class Team
{
    private List<string> _members = new List<string> { "Alice", "Bob", "Charlie" };

    // Expose as read-only — callers can't Add/Remove
    public IReadOnlyList<string> Members => _members.AsReadOnly();
}

var team = new Team();
foreach (string member in team.Members)
    Console.WriteLine(member);

// team.Members.Add("Dave"); // ❌ Compile error — no Add method
```

```csharp
// Other read-only wrappers
IReadOnlyCollection<int> readOnlyCollection = new List<int> { 1, 2, 3 }.AsReadOnly();
IReadOnlyDictionary<string, int> readOnlyDict = new Dictionary<string, int>
{
    ["A"] = 1
};
```

---

## Performance Comparison

| Operation | List | Dictionary | HashSet | Queue | Stack |
|---|---|---|---|---|---|
| Add (end) | O(1)* | O(1)* | O(1)* | O(1) | O(1) |
| Insert (middle) | O(n) | N/A | N/A | N/A | N/A |
| Remove | O(n) | O(1) | O(1) | O(1) | O(1) |
| Search (Contains) | O(n) | O(1) by key | O(1) | O(n) | O(n) |
| Access by index | O(1) | N/A | N/A | N/A | N/A |

*Amortized — occasional O(n) when internal array resizes

---

## Key Takeaways

| Concept | Summary |
|---|---|
| `List<T>` | Dynamic array — the default go-to collection |
| `Dictionary<TKey,TValue>` | Fast key-based lookup and storage |
| `HashSet<T>` | Unique elements with set operations |
| `Queue<T>` | FIFO — processing in order |
| `Stack<T>` | LIFO — undo/backtracking operations |
| `TryGetValue` / `TryAdd` | Always use safe access methods |
| Read-only collections | Expose data without allowing modification |
| Choose by use case | Each collection excels at different operations |

---

*Next Topic: LINQ (Language Integrated Query) →*
