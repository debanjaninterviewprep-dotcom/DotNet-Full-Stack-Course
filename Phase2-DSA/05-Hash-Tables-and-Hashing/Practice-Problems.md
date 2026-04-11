# Topic 5: Hash Tables & Hashing — Practice Problems

## Problem 1: Build Your Own Hash Table (Easy)
**Concept**: Hash function, collision resolution

### 1a. Implement a Hash Table with Chaining
Build `ChainingHashTable<TKey, TValue>` from scratch:
- `Put(key, value)` — insert or update
- `Get(key)` — return value or default
- `Remove(key)` — delete entry
- `ContainsKey(key)` — check existence
- Auto-resize when load factor > 0.75
- `Count` property

### 1b. Test Your Hash Table
```csharp
var table = new ChainingHashTable<string, int>();
table.Put("apple", 5);
table.Put("banana", 3);
table.Put("cherry", 8);
Console.WriteLine(table.Get("banana")); // 3
table.Put("banana", 10); // Update
Console.WriteLine(table.Get("banana")); // 10
table.Remove("cherry");
Console.WriteLine(table.ContainsKey("cherry")); // false
```

### 1c. Hash Table Statistics
Add a method `PrintStats()` that shows:
- Number of entries
- Number of buckets
- Load factor
- Longest chain length
- Number of empty buckets

---

## Problem 2: Frequency & Counting Problems (Easy-Medium)
**Concept**: Using hash maps for counting

### 2a. First Non-Repeating Character
```
Input: "aabbcdeff"
Output: 'c' (first char with count 1)
```

### 2b. Top K Frequent Elements
```
Input: [1, 1, 1, 2, 2, 3], k = 2
Output: [1, 2] (most frequent k elements)
```

### 2c. Valid Anagram
```
Input: s = "anagram", t = "nagaram"
Output: true
```

### 2d. Find All Duplicates in Array
Each element appears once or twice. Find all elements that appear twice.
```
Input: [4, 3, 2, 7, 8, 2, 3, 1]
Output: [2, 3]
```

### 2e. Majority Element
Find the element that appears more than ⌊n/2⌋ times.
```
Input: [3, 2, 3]
Output: 3
```
Bonus: Can you solve in O(1) space? (Hint: Boyer-Moore Voting Algorithm)

---

## Problem 3: HashSet Problems (Medium)
**Concept**: Using sets for existence checks and set operations

### 3a. Intersection of Two Arrays
```
Input: [1, 2, 2, 1], [2, 2]
Output: [2] (unique intersection)
```

### 3b. Longest Consecutive Sequence
```
Input: [100, 4, 200, 1, 3, 2]
Output: 4 (sequence: 1, 2, 3, 4)
```
Time: O(n) using HashSet

### 3c. Happy Number
A number is happy if repeatedly summing the squares of its digits eventually reaches 1.
```
Input: 19
19 → 1² + 9² = 82 → 8² + 2² = 68 → 6² + 8² = 100 → 1² + 0² + 0² = 1 ✓
Output: true
```
Use a HashSet to detect infinite loops.

### 3d. Contains Duplicate Within Distance K
Return true if `nums[i] == nums[j]` and `|i - j| <= k`.
```
Input: [1, 2, 3, 1], k = 3
Output: true (index 0 and 3)
```

---

## Problem 4: Advanced HashMap Problems (Medium-Hard)
**Concept**: Complex patterns using hash maps

### 4a. Group Anagrams
```
Input: ["eat", "tea", "tan", "ate", "nat", "bat"]
Output: [["eat","tea","ate"], ["tan","nat"], ["bat"]]
```

### 4b. Subarray Sum Equals K
Count the number of subarrays that sum to k.
```
Input: [1, 1, 1], k = 2
Output: 2 (subarrays [1,1] starting at index 0 and 1)
```
Hint: Prefix sum + HashMap. Store prefix sum frequencies.

### 4c. Isomorphic Strings
Two strings are isomorphic if characters can be replaced to get the other.
```
"egg" and "add" → true (e→a, g→d)
"foo" and "bar" → false
"paper" and "title" → true
```

### 4d. Word Pattern
```
pattern = "abba", s = "dog cat cat dog" → true
pattern = "abba", s = "dog cat cat fish" → false
```

### 4e. Longest Substring Without Repeating Characters
```
Input: "abcabcbb"
Output: 3 ("abc")
```
Use HashMap to track last seen position of each character.

---

## Problem 5: Design Problems Using Hash Tables (Hard)
**Concept**: System design with hash tables

### 5a. Design a Phone Book
Implement a phone book supporting:
- `Add(name, number)` — add or update contact
- `Delete(name)` — remove contact
- `Search(name)` — find number
- `SearchByPrefix(prefix)` — find all contacts starting with prefix
- `PrintAll()` — display all sorted by name

```
Add("Alice", "123-456")
Add("Bob", "789-012")
Add("Alex", "345-678")
Search("Alice") → "123-456"
SearchByPrefix("Al") → [("Alex", "345-678"), ("Alice", "123-456")]
```

### 5b. Design a Cache with Expiration
Implement a key-value cache where entries expire after a given TTL:
- `Set(key, value, ttlSeconds)` — store with expiration
- `Get(key)` — return value if not expired, else null
- `CleanUp()` — remove all expired entries

```
cache.Set("token", "abc123", 5); // expires in 5 seconds
cache.Get("token"); // "abc123"
// After 5 seconds...
cache.Get("token"); // null (expired)
```

### 5c. Implement a Consistent Hashing Ring (Bonus)
Used in distributed systems to distribute keys across servers.
- Add/remove servers from the ring
- Find which server a key maps to
- Minimize key redistribution when servers change

This is a bonus challenge — research consistent hashing before attempting.

---

### Submission
- Create a new console project: `dotnet new console -n HashTablePractice`
- Solve all problems in `Program.cs`
- Comment each solution with **Time: O(?), Space: O(?)**
- Test with collision scenarios and edge cases
- Tell me "check" when you're ready for review!
