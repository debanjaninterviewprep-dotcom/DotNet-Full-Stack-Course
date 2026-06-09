# Topic 2: Arrays & Strings (DSA)

## Arrays — The Foundation

An array is a **contiguous block of memory** that stores elements of the same type. Understanding arrays deeply is critical because most data structures are built on top of them.

### Memory Layout

```
Index:    0      1      2      3      4
        ┌──────┬──────┬──────┬──────┬──────┐
Array:  │  10  │  20  │  30  │  40  │  50  │
        └──────┴──────┴──────┴──────┴──────┘
Address: 0x100  0x104  0x108  0x10C  0x110
         ← Each int is 4 bytes →

Address of arr[i] = BaseAddress + (i × ElementSize)
arr[3] = 0x100 + (3 × 4) = 0x10C → O(1) access!
```

This is why array access by index is **O(1)** — it's just arithmetic.

---

## Array Operations & Complexity

| Operation | Complexity | Why |
|---|---|---|
| Access by index `arr[i]` | O(1) | Direct address calculation |
| Search (unsorted) | O(n) | Must scan linearly |
| Search (sorted) | O(log n) | Binary search |
| Insert at end | O(1) | If space available |
| Insert at position | O(n) | Must shift elements right |
| Delete at position | O(n) | Must shift elements left |
| Delete at end | O(1) | Just reduce length |

### Insertion Visualization

```
Insert 25 at index 2:

Before: [10, 20, 30, 40, 50, _]
                  ↓ shift right →
Step 1: [10, 20, 30, 30, 40, 50]  (shift from end)
Step 2: [10, 20, 25, 30, 40, 50]  (place 25)
```

---

## Common Array Techniques

### Technique 1: Two Pointer

Use two pointers moving from **both ends** or **same direction** to solve problems efficiently.

```csharp
// Reverse an array in-place — O(n) time, O(1) space
void Reverse(int[] arr)
{
    int left = 0, right = arr.Length - 1;
    while (left < right)
    {
        (arr[left], arr[right]) = (arr[right], arr[left]);
        left++;
        right--;
    }
}

// Two Sum on SORTED array — O(n) time, O(1) space
int[] TwoSumSorted(int[] sorted, int target)
{
    int left = 0, right = sorted.Length - 1;
    while (left < right)
    {
        int sum = sorted[left] + sorted[right];
        if (sum == target) return new[] { left, right };
        else if (sum < target) left++;
        else right--;
    }
    return new[] { -1, -1 };
}

// Remove duplicates from sorted array — O(n) time, O(1) space
int RemoveDuplicates(int[] sorted)
{
    if (sorted.Length == 0) return 0;
    int writeIndex = 1;
    for (int i = 1; i < sorted.Length; i++)
    {
        if (sorted[i] != sorted[i - 1])
        {
            sorted[writeIndex] = sorted[i];
            writeIndex++;
        }
    }
    return writeIndex; // New length
}
```

### Technique 2: Sliding Window

Maintain a **window** of elements and slide it across the array.

```csharp
// Maximum sum of k consecutive elements — O(n)
int MaxSumSubarray(int[] arr, int k)
{
    // Calculate sum of first window
    int windowSum = 0;
    for (int i = 0; i < k; i++)
        windowSum += arr[i];
    
    int maxSum = windowSum;
    
    // Slide: add next element, remove first element of previous window
    for (int i = k; i < arr.Length; i++)
    {
        windowSum += arr[i] - arr[i - k]; // Slide window
        maxSum = Math.Max(maxSum, windowSum);
    }
    
    return maxSum;
}
// Input: [2, 1, 5, 1, 3, 2], k=3
// Windows: [2,1,5]=8, [1,5,1]=7, [5,1,3]=9, [1,3,2]=6
// Answer: 9

// Longest substring without repeating characters — O(n)
int LengthOfLongestSubstring(string s)
{
    HashSet<char> window = new HashSet<char>();
    int left = 0, maxLen = 0;
    
    for (int right = 0; right < s.Length; right++)
    {
        while (window.Contains(s[right]))
        {
            window.Remove(s[left]);
            left++;
        }
        window.Add(s[right]);
        maxLen = Math.Max(maxLen, right - left + 1);
    }
    return maxLen;
}
// "abcabcbb" → 3 ("abc")
```

### Technique 3: Prefix Sum

Pre-compute cumulative sums for O(1) range queries.

```csharp
// Build prefix sum array
int[] BuildPrefixSum(int[] arr)
{
    int[] prefix = new int[arr.Length + 1];
    for (int i = 0; i < arr.Length; i++)
        prefix[i + 1] = prefix[i] + arr[i];
    return prefix;
}

// Query sum of range [left, right] in O(1)
int RangeSum(int[] prefix, int left, int right)
{
    return prefix[right + 1] - prefix[left];
}

// Example:
// arr:    [3, 1, 4, 1, 5, 9]
// prefix: [0, 3, 4, 8, 9, 14, 23]
// Sum(1,3) = prefix[4] - prefix[1] = 9 - 3 = 6 → (1+4+1)
```

### Technique 4: Kadane's Algorithm

Find the **maximum sum subarray** in O(n).

```csharp
int MaxSubarraySum(int[] arr)
{
    int currentMax = arr[0];
    int globalMax = arr[0];
    
    for (int i = 1; i < arr.Length; i++)
    {
        // Either extend the current subarray or start fresh
        currentMax = Math.Max(arr[i], currentMax + arr[i]);
        globalMax = Math.Max(globalMax, currentMax);
    }
    return globalMax;
}

// Input: [-2, 1, -3, 4, -1, 2, 1, -5, 4]
// Subarrays considered:
//   currentMax: -2, 1, -2, 4, 3, 5, 6, 1, 5
//   globalMax:  -2, 1,  1, 4, 4, 5, 6, 6, 6
// Answer: 6 (subarray [4, -1, 2, 1])
```

### Technique 5: Dutch National Flag (Three-Way Partition)

Sort an array with only 3 distinct values in O(n).

```csharp
// Sort array of 0s, 1s, and 2s — O(n) time, O(1) space
void SortColors(int[] arr)
{
    int low = 0, mid = 0, high = arr.Length - 1;
    
    while (mid <= high)
    {
        if (arr[mid] == 0)
        {
            (arr[low], arr[mid]) = (arr[mid], arr[low]);
            low++;
            mid++;
        }
        else if (arr[mid] == 1)
        {
            mid++;
        }
        else // arr[mid] == 2
        {
            (arr[mid], arr[high]) = (arr[high], arr[mid]);
            high--;
        }
    }
}
// [2, 0, 1, 2, 0, 1] → [0, 0, 1, 1, 2, 2]
```

---

## String Fundamentals for DSA

### Strings Are Immutable Arrays of Characters

```csharp
string s = "Hello";
// Internally: ['H', 'e', 'l', 'l', 'o']
// s[0] = 'H' — O(1) access
// s.Length = 5 — O(1)

// IMPORTANT: Strings are IMMUTABLE in C#
// s[0] = 'h'; // ❌ Compile error
// Every string operation creates a NEW string

// This is O(n²) because each += creates a new string:
string result = "";
for (int i = 0; i < 10000; i++)
    result += "a"; // Creates 10,000 string objects!

// Use StringBuilder for O(n):
StringBuilder sb = new StringBuilder();
for (int i = 0; i < 10000; i++)
    sb.Append("a");
string result2 = sb.ToString();
```

### Common String Techniques

```csharp
// Character frequency — O(n)
Dictionary<char, int> CharFrequency(string s)
{
    Dictionary<char, int> freq = new Dictionary<char, int>();
    foreach (char c in s)
    {
        freq.TryGetValue(c, out int count);
        freq[c] = count + 1;
    }
    return freq;
}

// For lowercase English letters, use array instead of dictionary:
int[] CharCount(string s)
{
    int[] count = new int[26]; // a-z
    foreach (char c in s)
        count[c - 'a']++;
    return count;
}

// Check if two strings are anagrams — O(n)
bool IsAnagram(string s, string t)
{
    if (s.Length != t.Length) return false;
    int[] count = new int[26];
    for (int i = 0; i < s.Length; i++)
    {
        count[s[i] - 'a']++;
        count[t[i] - 'a']--;
    }
    return count.All(c => c == 0);
}
```

### Palindrome Checking

```csharp
// Two pointer palindrome check — O(n) time, O(1) space
bool IsPalindrome(string s)
{
    int left = 0, right = s.Length - 1;
    while (left < right)
    {
        if (s[left] != s[right]) return false;
        left++;
        right--;
    }
    return true;
}

// Valid palindrome (ignore non-alphanumeric, case-insensitive)
bool IsValidPalindrome(string s)
{
    int left = 0, right = s.Length - 1;
    while (left < right)
    {
        while (left < right && !char.IsLetterOrDigit(s[left])) left++;
        while (left < right && !char.IsLetterOrDigit(s[right])) right--;
        if (char.ToLower(s[left]) != char.ToLower(s[right])) return false;
        left++;
        right--;
    }
    return true;
}
// "A man, a plan, a canal: Panama" → true
```

### String Reversal Techniques

```csharp
// Reverse a string — O(n)
string ReverseString(string s)
{
    char[] chars = s.ToCharArray();
    Array.Reverse(chars);
    return new string(chars);
}

// Reverse words in a sentence — O(n)
string ReverseWords(string s)
{
    string[] words = s.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
    Array.Reverse(words);
    return string.Join(" ", words);
}
// "  the sky is blue  " → "blue is sky the"
```

---

## Classic Array/String Problems & Patterns

### Pattern: HashMap for O(1) Lookup

```csharp
// Two Sum (unsorted) — O(n) time, O(n) space
int[] TwoSum(int[] nums, int target)
{
    Dictionary<int, int> seen = new Dictionary<int, int>();
    for (int i = 0; i < nums.Length; i++)
    {
        int complement = target - nums[i];
        if (seen.ContainsKey(complement))
            return new[] { seen[complement], i };
        seen[nums[i]] = i;
    }
    return new[] { -1, -1 };
}
```

### Pattern: In-Place Manipulation

```csharp
// Rotate array by k positions — O(n) time, O(1) space
void Rotate(int[] nums, int k)
{
    k %= nums.Length;
    Reverse(nums, 0, nums.Length - 1);    // Reverse entire
    Reverse(nums, 0, k - 1);              // Reverse first k
    Reverse(nums, k, nums.Length - 1);    // Reverse remaining
}

void Reverse(int[] arr, int start, int end)
{
    while (start < end)
    {
        (arr[start], arr[end]) = (arr[end], arr[start]);
        start++;
        end--;
    }
}
// [1,2,3,4,5,6,7], k=3
// Reverse all:  [7,6,5,4,3,2,1]
// Reverse 0..2: [5,6,7,4,3,2,1]
// Reverse 3..6: [5,6,7,1,2,3,4] ✓
```

### Pattern: Matrix Traversal

```csharp
// Traverse a 2D matrix
void TraverseMatrix(int[,] matrix)
{
    int rows = matrix.GetLength(0);
    int cols = matrix.GetLength(1);
    
    // Row by row
    for (int r = 0; r < rows; r++)
        for (int c = 0; c < cols; c++)
            Console.Write($"{matrix[r, c]} ");
    
    // Spiral order
    // → → → ↓
    //       ↓
    // ← ← ← 
}

// Rotate matrix 90° clockwise — O(n²) time, O(1) space
void RotateMatrix(int[,] matrix)
{
    int n = matrix.GetLength(0);
    
    // Step 1: Transpose (swap rows and columns)
    for (int i = 0; i < n; i++)
        for (int j = i + 1; j < n; j++)
            (matrix[i, j], matrix[j, i]) = (matrix[j, i], matrix[i, j]);
    
    // Step 2: Reverse each row
    for (int i = 0; i < n; i++)
        for (int j = 0; j < n / 2; j++)
            (matrix[i, j], matrix[i, n - 1 - j]) = (matrix[i, n - 1 - j], matrix[i, j]);
}
```

---

## Subarray vs Substring vs Subsequence

```
Array: [1, 2, 3, 4, 5]

Subarray (contiguous):  [2, 3, 4]     — must be consecutive
Subset:                 {1, 3, 5}     — any elements, no order
Subsequence:            [1, 3, 5]     — maintain order, not necessarily consecutive

String: "abcde"

Substring (contiguous): "bcd"         — must be consecutive characters
Subsequence:            "ace"         — maintain order, skip some characters
```

---

## Complexity Cheat Sheet for This Topic

| Problem | Brute Force | Optimal | Technique |
|---|---|---|---|
| Two Sum | O(n²) | O(n) | HashMap |
| Max Subarray Sum | O(n³) | O(n) | Kadane's |
| Contains Duplicate | O(n²) | O(n) | HashSet |
| Reverse Array | O(n) | O(n) | Two Pointers |
| Rotate Array | O(n×k) | O(n) | Three Reversals |
| Sliding Window Max | O(n×k) | O(n) | Deque |
| Longest Unique Substring | O(n³) | O(n) | Sliding Window + Set |
| Anagram Check | O(n log n) | O(n) | Char Count Array |
| Palindrome Check | O(n) | O(n) | Two Pointers |

---

## Key Takeaways

| Concept | Summary |
|---|---|
| Arrays | Contiguous memory, O(1) access, O(n) insert/delete |
| Two Pointers | Solve problems with O(1) space by scanning from both ends |
| Sliding Window | Track a range of elements efficiently as you scan |
| Prefix Sum | Pre-compute totals for O(1) range sum queries |
| Kadane's Algorithm | Find max subarray sum in O(n) |
| HashMap/HashSet | Trade O(n) space for O(1) lookup |
| String Immutability | Use StringBuilder for concatenation in loops |
| Char counting | Use `int[26]` for lowercase letters, Dictionary otherwise |

---

*Next Topic: Linked Lists →*
