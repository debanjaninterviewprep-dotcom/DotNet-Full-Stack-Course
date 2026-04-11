# Topic 5: Hash Tables & Hashing

## What is Hashing?

**Hashing** converts data (a key) into a fixed-size number (hash code) that determines where to store or find the value. It enables **O(1) average-case** lookup, insert, and delete.

```
Key "apple" → Hash Function → 3 → Store at index 3

   Index  Value
   [0]    null
   [1]    null
   [2]    null
   [3]    "apple" → found in O(1)!
   [4]    null
```

---

## Hash Function

A hash function maps a key to an index in the array (bucket).

### Properties of a Good Hash Function

1. **Deterministic** — Same key always produces same hash
2. **Uniform distribution** — Keys spread evenly across buckets
3. **Fast to compute** — O(1) or near O(1)
4. **Minimizes collisions** — Different keys rarely map to same index

### Simple Hash Function Examples

```csharp
// For integer keys
int HashInt(int key, int tableSize)
{
    return Math.Abs(key) % tableSize;
}

// For string keys — weighted sum of characters
int HashString(string key, int tableSize)
{
    int hash = 0;
    for (int i = 0; i < key.Length; i++)
    {
        hash = (hash * 31 + key[i]) % tableSize;
    }
    return Math.Abs(hash) % tableSize;
}
// "abc" → (0*31 + 97) = 97 → (97*31 + 98) = 3105 → (3105*31 + 99) = 96354
// 96354 % 10 = 4 → stored at index 4

// C# built-in: GetHashCode()
"hello".GetHashCode(); // Returns an int hash code
42.GetHashCode();       // Returns 42 for ints
```

### Why Prime Numbers?

```
Table size = 10 (not prime):
Keys: 10, 20, 30, 40, 50 → All hash to 0! 💥 Collision city!

Table size = 11 (prime):
Keys: 10→10, 20→9, 30→8, 40→7, 50→6 → Well distributed! ✅
```

---

## Collision Resolution

When two different keys hash to the same index, we have a **collision**.

### Method 1: Chaining (Separate Chaining)

Each bucket stores a linked list of all entries that hash to that index.

```
Index  Bucket (Linked List)
[0]    → null
[1]    → ("cat", 5) → ("dog", 8) → null   ← collision handled!
[2]    → ("bird", 3) → null
[3]    → null
[4]    → ("fish", 7) → null
```

```csharp
public class ChainingHashTable<TKey, TValue> where TKey : notnull
{
    private class Entry
    {
        public TKey Key;
        public TValue Value;
        public Entry? Next;
        public Entry(TKey key, TValue value) { Key = key; Value = value; }
    }
    
    private Entry?[] _buckets;
    private int _count;
    
    public ChainingHashTable(int capacity = 16)
    {
        _buckets = new Entry?[capacity];
    }
    
    private int GetIndex(TKey key) => Math.Abs(key.GetHashCode()) % _buckets.Length;
    
    // Insert or Update — O(1) average, O(n) worst
    public void Put(TKey key, TValue value)
    {
        int index = GetIndex(key);
        Entry? current = _buckets[index];
        
        // Check if key already exists
        while (current != null)
        {
            if (current.Key.Equals(key))
            {
                current.Value = value; // Update
                return;
            }
            current = current.Next;
        }
        
        // Insert at head of chain
        Entry newEntry = new Entry(key, value);
        newEntry.Next = _buckets[index];
        _buckets[index] = newEntry;
        _count++;
        
        // Resize if load factor > 0.75
        if ((double)_count / _buckets.Length > 0.75)
            Resize();
    }
    
    // Get — O(1) average
    public TValue? Get(TKey key)
    {
        int index = GetIndex(key);
        Entry? current = _buckets[index];
        
        while (current != null)
        {
            if (current.Key.Equals(key))
                return current.Value;
            current = current.Next;
        }
        return default;
    }
    
    // Delete — O(1) average
    public bool Remove(TKey key)
    {
        int index = GetIndex(key);
        Entry? current = _buckets[index];
        Entry? prev = null;
        
        while (current != null)
        {
            if (current.Key.Equals(key))
            {
                if (prev == null)
                    _buckets[index] = current.Next;
                else
                    prev.Next = current.Next;
                _count--;
                return true;
            }
            prev = current;
            current = current.Next;
        }
        return false;
    }
    
    private void Resize()
    {
        Entry?[] oldBuckets = _buckets;
        _buckets = new Entry?[oldBuckets.Length * 2];
        _count = 0;
        
        foreach (Entry? bucket in oldBuckets)
        {
            Entry? current = bucket;
            while (current != null)
            {
                Put(current.Key, current.Value);
                current = current.Next;
            }
        }
    }
    
    public int Count => _count;
}
```

### Method 2: Open Addressing (Linear Probing)

If a collision occurs, look at the **next** slot.

```
Insert "cat" → hash = 1 → place at [1]
Insert "dog" → hash = 1 → collision! Try [2] → place at [2]
Insert "bird" → hash = 2 → collision! Try [3] → place at [3]

Index  Value
[0]    null
[1]    "cat"    ← original
[2]    "dog"    ← probed from [1]
[3]    "bird"   ← probed from [2]
```

```csharp
public class LinearProbingHashTable<TKey, TValue> where TKey : notnull
{
    private TKey?[] _keys;
    private TValue?[] _values;
    private bool[] _occupied;
    private int _count;
    
    public LinearProbingHashTable(int capacity = 16)
    {
        _keys = new TKey?[capacity];
        _values = new TValue?[capacity];
        _occupied = new bool[capacity];
    }
    
    private int GetIndex(TKey key) => Math.Abs(key.GetHashCode()) % _keys.Length;
    
    public void Put(TKey key, TValue value)
    {
        if ((double)_count / _keys.Length > 0.5) Resize();
        
        int index = GetIndex(key);
        while (_occupied[index])
        {
            if (_keys[index]!.Equals(key))
            {
                _values[index] = value; // Update
                return;
            }
            index = (index + 1) % _keys.Length; // Linear probe
        }
        
        _keys[index] = key;
        _values[index] = value;
        _occupied[index] = true;
        _count++;
    }
    
    public TValue? Get(TKey key)
    {
        int index = GetIndex(key);
        while (_occupied[index])
        {
            if (_keys[index]!.Equals(key))
                return _values[index];
            index = (index + 1) % _keys.Length;
        }
        return default;
    }
    
    private void Resize()
    {
        TKey?[] oldKeys = _keys;
        TValue?[] oldValues = _values;
        bool[] oldOccupied = _occupied;
        
        _keys = new TKey?[oldKeys.Length * 2];
        _values = new TValue?[oldValues.Length * 2];
        _occupied = new bool[oldKeys.Length * 2];
        _count = 0;
        
        for (int i = 0; i < oldKeys.Length; i++)
        {
            if (oldOccupied[i])
                Put(oldKeys[i]!, oldValues[i]!);
        }
    }
}
```

### Other Open Addressing Methods

```
Linear Probing:    h(k) + 1, h(k) + 2, h(k) + 3, ...
                   Problem: clustering (long chains)

Quadratic Probing:  h(k) + 1², h(k) + 2², h(k) + 3², ...
                   Better spread, but secondary clustering

Double Hashing:    h(k) + i × h2(k)
                   Best spread, uses second hash function
```

---

## Load Factor & Resizing

```
Load Factor (α) = Number of entries / Number of buckets

α = 0.75 (common threshold for chaining)
α = 0.5  (common threshold for open addressing)

When α exceeds threshold → Resize (double buckets & rehash everything)
```

| Load Factor | Effect |
|---|---|
| Low (< 0.5) | Fast but wastes memory |
| Medium (0.5–0.75) | Good balance |
| High (> 0.75) | More collisions, slower |
| 1.0+ | Guaranteed collisions (chaining still works, open addressing fails) |

---

## C# Built-in Hash-Based Collections

### Dictionary\<TKey, TValue\>

```csharp
// Hash table with key-value pairs
Dictionary<string, int> ages = new Dictionary<string, int>();

// Add
ages["Alice"] = 25;
ages["Bob"] = 30;
ages.Add("Charlie", 35); // Throws if key exists

// Get
int age = ages["Alice"]; // 25 — throws if key missing
bool found = ages.TryGetValue("Dave", out int daveAge); // Safe lookup

// Check
bool hasAlice = ages.ContainsKey("Alice"); // true
bool has25 = ages.ContainsValue(25);       // true (O(n)!)

// Remove
ages.Remove("Bob");

// Iterate
foreach (KeyValuePair<string, int> kvp in ages)
    Console.WriteLine($"{kvp.Key}: {kvp.Value}");
```

### HashSet\<T\>

```csharp
// Unordered collection of unique elements
HashSet<int> set = new HashSet<int>();

set.Add(1);
set.Add(2);
set.Add(2); // Ignored (already exists)
set.Contains(1); // true — O(1)
set.Remove(1);

// Set operations
HashSet<int> a = new HashSet<int> { 1, 2, 3, 4 };
HashSet<int> b = new HashSet<int> { 3, 4, 5, 6 };

a.IntersectWith(b);  // a = {3, 4}
a.UnionWith(b);       // a = {1, 2, 3, 4, 5, 6}
a.ExceptWith(b);      // a = {1, 2}
a.IsSubsetOf(b);      // false
```

### SortedDictionary\<TKey, TValue\> (Red-Black Tree, not Hash)

```csharp
// Ordered by key — O(log n) operations
SortedDictionary<string, int> sorted = new SortedDictionary<string, int>();
sorted["Banana"] = 2;
sorted["Apple"] = 1;
sorted["Cherry"] = 3;

foreach (var kvp in sorted)
    Console.WriteLine(kvp.Key);
// Apple, Banana, Cherry (sorted!)
```

---

## Hash Table vs Other Data Structures

| Feature | Hash Table | Array | BST | Sorted Array |
|---|---|---|---|---|
| Search | O(1) avg | O(n) | O(log n) | O(log n) |
| Insert | O(1) avg | O(1) end | O(log n) | O(n) |
| Delete | O(1) avg | O(n) | O(log n) | O(n) |
| Ordered | No | No | Yes | Yes |
| Min/Max | O(n) | O(n) | O(log n) | O(1) |
| Space | O(n) | O(n) | O(n) | O(n) |

---

## Common Hashing Patterns in DSA

### Pattern 1: Frequency Counting

```csharp
// Count character frequency
Dictionary<char, int> FrequencyCount(string s)
{
    Dictionary<char, int> freq = new();
    foreach (char c in s)
    {
        freq.TryGetValue(c, out int count);
        freq[c] = count + 1;
    }
    return freq;
}
// "aabbbcc" → {'a':2, 'b':3, 'c':2}
```

### Pattern 2: Two Sum (Classic)

```csharp
int[] TwoSum(int[] nums, int target)
{
    Dictionary<int, int> seen = new();
    for (int i = 0; i < nums.Length; i++)
    {
        int complement = target - nums[i];
        if (seen.TryGetValue(complement, out int j))
            return new[] { j, i };
        seen[nums[i]] = i;
    }
    return Array.Empty<int>();
}
```

### Pattern 3: Group By Key

```csharp
// Group anagrams by sorted key
Dictionary<string, List<string>> GroupAnagrams(string[] words)
{
    Dictionary<string, List<string>> groups = new();
    foreach (string word in words)
    {
        char[] chars = word.ToCharArray();
        Array.Sort(chars);
        string key = new string(chars);
        
        if (!groups.ContainsKey(key))
            groups[key] = new List<string>();
        groups[key].Add(word);
    }
    return groups;
}
// ["eat","tea","tan","ate","nat","bat"] → {"aet":["eat","tea","ate"], "ant":["tan","nat"], "abt":["bat"]}
```

### Pattern 4: Existence Check with HashSet

```csharp
// Find first duplicate in O(n) time, O(n) space
int FirstDuplicate(int[] arr)
{
    HashSet<int> seen = new();
    foreach (int num in arr)
    {
        if (!seen.Add(num)) // Add returns false if already exists
            return num;
    }
    return -1;
}

// Check if array has pair with given sum
bool HasPairWithSum(int[] arr, int target)
{
    HashSet<int> complements = new();
    foreach (int num in arr)
    {
        if (complements.Contains(num)) return true;
        complements.Add(target - num);
    }
    return false;
}
```

### Pattern 5: Index Mapping

```csharp
// Longest consecutive sequence — O(n)
int LongestConsecutive(int[] nums)
{
    HashSet<int> set = new(nums);
    int maxLen = 0;
    
    foreach (int num in set)
    {
        // Only start counting from sequence beginning
        if (!set.Contains(num - 1))
        {
            int current = num;
            int length = 1;
            while (set.Contains(current + 1))
            {
                current++;
                length++;
            }
            maxLen = Math.Max(maxLen, length);
        }
    }
    return maxLen;
}
// [100, 4, 200, 1, 3, 2] → 4 (sequence: 1,2,3,4)
```

---

## Implementing GetHashCode() and Equals()

When using custom objects as dictionary keys:

```csharp
public class Point
{
    public int X { get; }
    public int Y { get; }
    
    public Point(int x, int y) { X = x; Y = y; }
    
    // MUST override both Equals and GetHashCode
    public override bool Equals(object? obj)
    {
        if (obj is Point other)
            return X == other.X && Y == other.Y;
        return false;
    }
    
    public override int GetHashCode()
    {
        return HashCode.Combine(X, Y); // .NET built-in combiner
    }
}

// Now works correctly as dictionary key:
Dictionary<Point, string> map = new();
map[new Point(1, 2)] = "A";
Console.WriteLine(map[new Point(1, 2)]); // "A" — works because of Equals/GetHashCode
```

---

## Key Takeaways

| Concept | Summary |
|---|---|
| Hash Function | Converts key → index. Must be deterministic and uniform |
| Collision | Two keys mapping to same index |
| Chaining | Each bucket is a linked list |
| Open Addressing | Probe next slots on collision |
| Load Factor | entries/buckets — resize when too high |
| Dictionary\<K,V\> | C# hash table — O(1) avg for CRUD |
| HashSet\<T\> | Unique elements — O(1) contains check |
| Frequency counting | Most common hash table pattern |
| GetHashCode/Equals | Must override both for custom keys |

---

*Next Topic: Trees & Binary Search Trees →*
