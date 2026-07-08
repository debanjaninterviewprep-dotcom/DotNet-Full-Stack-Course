# Topic 05: Hash Tables and Hashing — Interview Questions

---

## Q1. What is a hash table and how does it work?
**Answer:**
A hash table maps **keys to values** using a **hash function** that converts a key into an array index. It provides O(1) average-case operations for insert, lookup, and delete.

```
Key → Hash Function → Bucket Index → Value
"Alice" → hashCode("Alice") % N → bucket[42] → 90
```

In C#:
```csharp
var dict = new Dictionary<string, int>();
dict["Alice"] = 90;        // O(1) insert
int score = dict["Alice"]; // O(1) lookup
dict.Remove("Alice");      // O(1) delete
```

The underlying mechanism:
1. Compute `key.GetHashCode()`.
2. Map to bucket index: `Math.Abs(hashCode) % bucketCount`.
3. Store (or find) the key-value pair in that bucket.

---

## Q2. What is a hash function and what makes a good one?
**Answer:**
A hash function converts a key into an integer index. A good hash function:
- **Deterministic** — same key always produces the same hash.
- **Uniform distribution** — spreads keys evenly across buckets.
- **Fast to compute** — O(1) or at most O(key length).
- **Avalanche effect** — small input changes cause large output changes (for security).

```csharp
// Simple polynomial rolling hash for strings
int HashString(string s, int tableSize)
{
    const int prime = 31;
    long hash = 0, power = 1;
    foreach (char c in s)
    {
        hash = (hash + (c - 'a' + 1) * power) % tableSize;
        power = (power * prime) % tableSize;
    }
    return (int)hash;
}
```

.NET uses `Object.GetHashCode()`, which is overridden for built-in types (`string`, `int`, etc.).

---

## Q3. What is a hash collision and how is it handled?
**Answer:**
A **collision** occurs when two different keys hash to the same bucket index. Two main resolution strategies:

**1. Chaining (Separate Chaining):**
Each bucket holds a linked list of all key-value pairs that hash to it.
```
bucket[3] → [("Alice", 90) → ("Bob", 85) → null]
```
- Simple to implement
- O(n/k) average chain length (n = entries, k = buckets)
- Used by `Dictionary<K,V>` in .NET

**2. Open Addressing:**
On collision, probe for the next empty slot.
- **Linear probing:** try `(hash + i) % n` for i = 1, 2, 3...
- **Quadratic probing:** try `(hash + i²) % n`
- **Double hashing:** try `(hash + i * hash2) % n`
- Better cache performance but clustering can occur

---

## Q4. What is load factor and when does rehashing occur?
**Answer:**
**Load factor** = (number of entries) / (number of buckets).

```
Load factor = n / k
n = 1000 entries, k = 1000 buckets → load factor = 1.0
```

- Low load factor (< 0.3) → many empty buckets, wastes memory.
- High load factor (> 0.7-0.75) → long chains/clustering, degrades to O(n).
- .NET's `Dictionary<K,V>` **rehashes** (resizes bucket array and re-inserts all entries) when load factor exceeds ~0.72.

```csharp
// Pre-specify capacity to avoid rehashing
var dict = new Dictionary<string, int>(capacity: 1000);
```

Rehashing is O(n) but amortized O(1) per insertion.

---

## Q5. How do you implement a simple hash map from scratch?
**Answer:**
```csharp
class HashMap<K, V>
{
    private const int Capacity = 1024;
    private List<(K key, V val)>[] _buckets = new List<(K, V)>[Capacity];

    private int GetIndex(K key) => Math.Abs(key!.GetHashCode()) % Capacity;

    public void Put(K key, V val)
    {
        int idx = GetIndex(key);
        _buckets[idx] ??= new List<(K, V)>();
        var bucket = _buckets[idx];
        for (int i = 0; i < bucket.Count; i++)
            if (bucket[i].key!.Equals(key)) { bucket[i] = (key, val); return; }
        bucket.Add((key, val));
    }

    public V? Get(K key)
    {
        var bucket = _buckets[GetIndex(key)];
        if (bucket != null)
            foreach (var (k, v) in bucket)
                if (k!.Equals(key)) return v;
        return default;
    }

    public void Remove(K key)
    {
        var bucket = _buckets[GetIndex(key)];
        bucket?.RemoveAll(pair => pair.key!.Equals(key));
    }
}
```

---

## Q6. What is the Two Sum problem and how do you solve it with a hash map?
**Answer:**
Find two indices `i, j` such that `nums[i] + nums[j] == target`:

```csharp
// O(n) time, O(n) space
int[] TwoSum(int[] nums, int target)
{
    var seen = new Dictionary<int, int>(); // value → index
    for (int i = 0; i < nums.Length; i++)
    {
        int complement = target - nums[i];
        if (seen.TryGetValue(complement, out int j))
            return new[] { j, i };
        seen[nums[i]] = i;
    }
    return Array.Empty<int>();
}
// [2,7,11,15], target=9 → [0,1]
```

---

## Q7. How do you find the first non-repeating character in a string?
**Answer:**
```csharp
char FirstUniqueChar(string s)
{
    var count = new Dictionary<char, int>();
    foreach (char c in s) count[c] = count.GetValueOrDefault(c, 0) + 1;
    foreach (char c in s) if (count[c] == 1) return c;
    return '\0';
}
// "leetcode" → 'l', "aabb" → '\0'

// With array (faster for ASCII only)
char FirstUniqueChar_Array(string s)
{
    int[] freq = new int[26];
    foreach (char c in s) freq[c - 'a']++;
    foreach (char c in s) if (freq[c - 'a'] == 1) return c;
    return '\0';
}
```

---

## Q8. What is the difference between `Dictionary<K,V>` and `HashSet<T>`?
**Answer:**
| | `Dictionary<K,V>` | `HashSet<T>` |
|---|---|---|
| **Stores** | Key-value pairs | Keys only |
| **Purpose** | Fast lookup by key | Fast membership testing, deduplication |
| **Contains check** | `dict.ContainsKey(k)` — O(1) | `set.Contains(v)` — O(1) |
| **Duplicate keys** | Not allowed (throws) | Not allowed (Add returns false) |
| **Iteration** | Key-value pairs | Values only |

```csharp
// HashSet for deduplication
var unique = new HashSet<int>(new[] { 1, 2, 2, 3, 3, 3 });
// unique = { 1, 2, 3 }

// Set operations
var a = new HashSet<int> { 1, 2, 3 };
var b = new HashSet<int> { 2, 3, 4 };
a.UnionWith(b);        // { 1, 2, 3, 4 }
a.IntersectWith(b);    // { 2, 3 }
a.ExceptWith(b);       // { 1 }
```

---

## Q9. How do you group anagrams together?
**Answer:**
Use sorted string or character count as the hash key:

```csharp
// O(n * k log k) — sort each word as key
IList<IList<string>> GroupAnagrams(string[] strs)
{
    var groups = new Dictionary<string, List<string>>();
    foreach (var s in strs)
    {
        var key = string.Concat(s.OrderBy(c => c)); // sorted chars = key
        if (!groups.ContainsKey(key)) groups[key] = new List<string>();
        groups[key].Add(s);
    }
    return groups.Values.Cast<IList<string>>().ToList();
}

// O(n * k) — character count as key (faster)
string CharCountKey(string s)
{
    int[] count = new int[26];
    foreach (char c in s) count[c - 'a']++;
    return string.Join(",", count);
}
```

---

## Q10. What is a rolling hash and what is it used for?
**Answer:**
A **rolling hash** efficiently updates a hash when a sliding window moves by one character — O(1) update vs O(k) recompute:

```csharp
// Rabin-Karp algorithm: find pattern in text — O(n + m) average
bool Contains(string text, string pattern)
{
    int n = text.Length, m = pattern.Length;
    int patHash = pattern.GetHashCode();

    for (int i = 0; i <= n - m; i++)
    {
        if (text.Substring(i, m).GetHashCode() == patHash)
            if (text.Substring(i, m) == pattern) return true; // verify (avoid false positives)
    }
    return false;
}
// Applications: plagiarism detection, DNA sequence matching, repeated substrings
```

---

## Q11. What is a perfect hash function?
**Answer:**
A **perfect hash function** maps each key to a **unique bucket** with zero collisions. A **minimal perfect hash function** uses exactly n buckets for n keys.

Requirements:
- All keys must be known in advance (static set).
- Lookup is O(1) with no collision handling overhead.

Applications: compilers (keyword lookup), static dictionaries, read-only lookup tables.

In practice, perfect hashing is rarely used outside specialized systems — the construction time and memory to build the perfect hash function usually isn't worth it for general-purpose use.

---

## Q12. How do you detect if an array contains a duplicate within k distance?
**Answer:**
```csharp
// Sliding window hash set — O(n) time, O(k) space
bool ContainsNearbyDuplicate(int[] nums, int k)
{
    var window = new HashSet<int>();
    for (int i = 0; i < nums.Length; i++)
    {
        if (window.Contains(nums[i])) return true;
        window.Add(nums[i]);
        if (window.Count > k) window.Remove(nums[i - k]); // shrink window
    }
    return false;
}
// [1,2,3,1], k=3 → true (nums[0]==nums[3], distance=3≤k)
```

---

## Q13. What is consistent hashing and why is it used?
**Answer:**
**Consistent hashing** minimizes key remapping when nodes are added or removed from a distributed system (e.g., distributed caches, sharded databases).

In a standard hash ring:
- Keys and nodes are mapped to positions on a circle (0 to 2³²).
- A key is assigned to the nearest node clockwise.
- Adding/removing a node only remaps keys between the affected nodes.

```
Standard hashing: adding 1 node remaps ~n/k keys (catastrophic)
Consistent hashing: adding 1 node remaps ~n/(k+1) keys (minimal disruption)
```

Used by: Redis Cluster, Amazon DynamoDB, Apache Cassandra, CDN load balancers.

---

## Q14. How do you implement a word frequency counter?
**Answer:**
```csharp
Dictionary<string, int> WordFrequency(string text)
{
    var freq = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
    foreach (var word in text.Split(' ', StringSplitOptions.RemoveEmptyEntries))
        freq[word] = freq.GetValueOrDefault(word, 0) + 1;
    return freq;
}

// Top K most frequent words — O(n log k)
IList<string> TopKFrequent(string[] words, int k)
{
    var freq = words.GroupBy(w => w).ToDictionary(g => g.Key, g => g.Count());
    return freq.OrderByDescending(kv => kv.Value)
               .ThenBy(kv => kv.Key)
               .Take(k)
               .Select(kv => kv.Key)
               .ToList();
}
```

---

## Q15. What are the `GetHashCode()` and `Equals()` contract rules in .NET?
**Answer:**
When implementing custom `GetHashCode()` and `Equals()`:

1. **If `a.Equals(b)` is `true`, then `a.GetHashCode() == b.GetHashCode()`** — violation breaks dictionary/set lookups.
2. `GetHashCode()` must be **consistent** — same object same hash within an application run.
3. `GetHashCode()` **should** differ for unequal objects (not required, but reduces collisions).
4. `Equals()` must be **reflexive** (`a.Equals(a)`), **symmetric** (`a.Equals(b) == b.Equals(a)`), and **transitive**.

```csharp
record Point(int X, int Y); // record auto-generates correct GetHashCode + Equals

// Manual implementation
class Point
{
    public int X, Y;
    public override bool Equals(object? obj)
        => obj is Point p && X == p.X && Y == p.Y;
    public override int GetHashCode()
        => HashCode.Combine(X, Y); // Use HashCode.Combine — avoids overflow issues
}
```
