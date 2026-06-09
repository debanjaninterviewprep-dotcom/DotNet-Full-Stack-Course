# Topic 9: Searching Algorithms

## Why Study Searching?

Searching is one of the most frequent operations in programming. Choosing the right search algorithm can make the difference between O(n) and O(log n) — that's the difference between 1 million operations and 20 operations for a million elements.

---

## Linear Search

Scan every element from start to end. Works on **any** collection (sorted or unsorted).

```csharp
// Linear Search — O(n) time, O(1) space
int LinearSearch(int[] arr, int target)
{
    for (int i = 0; i < arr.Length; i++)
    {
        if (arr[i] == target) return i;
    }
    return -1; // Not found
}

// With sentinel optimization (avoid bounds check)
int LinearSearchSentinel(int[] arr, int target)
{
    int n = arr.Length;
    if (n == 0) return -1;
    
    int last = arr[n - 1];
    arr[n - 1] = target; // Place sentinel
    
    int i = 0;
    while (arr[i] != target) i++;
    
    arr[n - 1] = last; // Restore
    
    if (i < n - 1 || last == target) return i;
    return -1;
}
```

| Case | Complexity |
|---|---|
| Best | O(1) — found at first position |
| Average | O(n/2) = O(n) |
| Worst | O(n) — not found or at last position |

---

## Binary Search

Only works on **sorted** arrays. Repeatedly divide the search space in half.

```
Target: 7
Array: [1, 3, 5, 7, 9, 11, 13, 15]

Step 1: mid = 9 → 7 < 9 → search left half
        [1, 3, 5, 7]

Step 2: mid = 5 → 7 > 5 → search right half
        [7]

Step 3: mid = 7 → Found! ✓

Only 3 comparisons instead of 8 (linear)!
```

```csharp
// Iterative Binary Search — O(log n) time, O(1) space
int BinarySearch(int[] arr, int target)
{
    int left = 0, right = arr.Length - 1;
    
    while (left <= right)
    {
        int mid = left + (right - left) / 2; // Avoids overflow
        
        if (arr[mid] == target)
            return mid;
        else if (arr[mid] < target)
            left = mid + 1;
        else
            right = mid - 1;
    }
    return -1;
}

// Recursive Binary Search — O(log n) time, O(log n) space (call stack)
int BinarySearchRecursive(int[] arr, int target, int left, int right)
{
    if (left > right) return -1;
    
    int mid = left + (right - left) / 2;
    
    if (arr[mid] == target) return mid;
    if (arr[mid] < target)
        return BinarySearchRecursive(arr, target, mid + 1, right);
    return BinarySearchRecursive(arr, target, left, mid - 1);
}
```

### Why `left + (right - left) / 2` instead of `(left + right) / 2`?

```csharp
// Integer overflow danger!
int left = 1_500_000_000;
int right = 2_000_000_000;

int bad = (left + right) / 2;              // OVERFLOW! 3.5 billion > int.MaxValue
int good = left + (right - left) / 2;     // Safe: 1.5B + 250M = 1.75B ✓
```

---

## Binary Search Variations

### Find First Occurrence (Lower Bound)

```csharp
// First index where arr[i] >= target
int LowerBound(int[] arr, int target)
{
    int left = 0, right = arr.Length;
    while (left < right)
    {
        int mid = left + (right - left) / 2;
        if (arr[mid] < target)
            left = mid + 1;
        else
            right = mid;
    }
    return left;
}
// [1, 2, 2, 2, 3, 4], target=2 → returns 1 (first 2)
```

### Find Last Occurrence (Upper Bound)

```csharp
// First index where arr[i] > target (i.e., last occurrence is result - 1)
int UpperBound(int[] arr, int target)
{
    int left = 0, right = arr.Length;
    while (left < right)
    {
        int mid = left + (right - left) / 2;
        if (arr[mid] <= target)
            left = mid + 1;
        else
            right = mid;
    }
    return left;
}
// [1, 2, 2, 2, 3, 4], target=2 → returns 4 (last 2 is at index 3)
```

### Count Occurrences

```csharp
int CountOccurrences(int[] arr, int target)
{
    return UpperBound(arr, target) - LowerBound(arr, target);
}
// [1, 2, 2, 2, 3, 4], target=2 → 4 - 1 = 3
```

### Find Insert Position

```csharp
// Where should target be inserted to keep array sorted?
int SearchInsert(int[] arr, int target)
{
    int left = 0, right = arr.Length;
    while (left < right)
    {
        int mid = left + (right - left) / 2;
        if (arr[mid] < target)
            left = mid + 1;
        else
            right = mid;
    }
    return left;
}
// [1, 3, 5, 6], target=4 → 2 (insert at index 2)
```

---

## Binary Search on Rotated Sorted Array

```
Original: [0, 1, 2, 4, 5, 6, 7]
Rotated:  [4, 5, 6, 7, 0, 1, 2]
```

```csharp
int SearchRotated(int[] arr, int target)
{
    int left = 0, right = arr.Length - 1;
    
    while (left <= right)
    {
        int mid = left + (right - left) / 2;
        
        if (arr[mid] == target) return mid;
        
        // Left half is sorted
        if (arr[left] <= arr[mid])
        {
            if (target >= arr[left] && target < arr[mid])
                right = mid - 1; // Target is in sorted left half
            else
                left = mid + 1;
        }
        // Right half is sorted
        else
        {
            if (target > arr[mid] && target <= arr[right])
                left = mid + 1; // Target is in sorted right half
            else
                right = mid - 1;
        }
    }
    return -1;
}
// [4, 5, 6, 7, 0, 1, 2], target=0 → 4
```

### Find Minimum in Rotated Sorted Array

```csharp
int FindMin(int[] arr)
{
    int left = 0, right = arr.Length - 1;
    
    while (left < right)
    {
        int mid = left + (right - left) / 2;
        if (arr[mid] > arr[right])
            left = mid + 1; // Min is in right half
        else
            right = mid; // Min is in left half (could be mid)
    }
    return arr[left];
}
// [4, 5, 6, 7, 0, 1, 2] → 0
```

---

## Binary Search on Answer

Sometimes you binary search on the **answer space** rather than an array.

### Find Square Root (Integer)

```csharp
int Sqrt(int x)
{
    if (x < 2) return x;
    int left = 1, right = x / 2;
    
    while (left <= right)
    {
        int mid = left + (right - left) / 2;
        long square = (long)mid * mid;
        
        if (square == x) return mid;
        if (square < x) left = mid + 1;
        else right = mid - 1;
    }
    return right; // Floor of sqrt
}
// Sqrt(8) → 2 (floor of 2.83)
```

### Find Peak Element

```csharp
// An element greater than its neighbors
int FindPeakElement(int[] arr)
{
    int left = 0, right = arr.Length - 1;
    
    while (left < right)
    {
        int mid = left + (right - left) / 2;
        if (arr[mid] < arr[mid + 1])
            left = mid + 1; // Peak is to the right
        else
            right = mid; // Peak is to the left (or at mid)
    }
    return left;
}
// [1, 2, 3, 1] → 2 (index of 3)
```

---

## Interpolation Search

Like binary search but estimates position based on value distribution. Good for **uniformly distributed** data.

```csharp
int InterpolationSearch(int[] arr, int target)
{
    int left = 0, right = arr.Length - 1;
    
    while (left <= right && target >= arr[left] && target <= arr[right])
    {
        if (left == right)
        {
            if (arr[left] == target) return left;
            return -1;
        }
        
        // Estimate position (linear interpolation)
        int pos = left + (int)((double)(right - left) / (arr[right] - arr[left]) * (target - arr[left]));
        
        if (arr[pos] == target) return pos;
        if (arr[pos] < target) left = pos + 1;
        else right = pos - 1;
    }
    return -1;
}
// Best: O(log log n) for uniform data
// Worst: O(n) for non-uniform data
```

---

## Exponential Search

Useful when searching in **unbounded/infinite** sorted arrays.

```csharp
int ExponentialSearch(int[] arr, int target)
{
    if (arr[0] == target) return 0;
    
    // Find range: double the bound until we overshoot
    int bound = 1;
    while (bound < arr.Length && arr[bound] <= target)
        bound *= 2;
    
    // Binary search in the found range
    int left = bound / 2;
    int right = Math.Min(bound, arr.Length - 1);
    
    while (left <= right)
    {
        int mid = left + (right - left) / 2;
        if (arr[mid] == target) return mid;
        if (arr[mid] < target) left = mid + 1;
        else right = mid - 1;
    }
    return -1;
}
// Time: O(log n) — finds range in O(log i) where i is target position
```

---

## Ternary Search

Divides search space into **three** parts instead of two.

```csharp
int TernarySearch(int[] arr, int target, int left, int right)
{
    while (left <= right)
    {
        int mid1 = left + (right - left) / 3;
        int mid2 = right - (right - left) / 3;
        
        if (arr[mid1] == target) return mid1;
        if (arr[mid2] == target) return mid2;
        
        if (target < arr[mid1])
            right = mid1 - 1;
        else if (target > arr[mid2])
            left = mid2 + 1;
        else
        {
            left = mid1 + 1;
            right = mid2 - 1;
        }
    }
    return -1;
}
// Time: O(log₃ n) — slightly more comparisons per step than binary search
// Binary search is usually faster due to fewer comparisons
```

---

## Search Algorithm Comparison

| Algorithm | Time (Avg) | Time (Worst) | Sorted Required | Space |
|---|---|---|---|---|
| Linear Search | O(n) | O(n) | No | O(1) |
| Binary Search | O(log n) | O(log n) | Yes | O(1) |
| Interpolation Search | O(log log n) | O(n) | Yes (uniform) | O(1) |
| Exponential Search | O(log n) | O(log n) | Yes | O(1) |
| Ternary Search | O(log₃ n) | O(log₃ n) | Yes | O(1) |
| Hash Table Lookup | O(1) | O(n) | No | O(n) |

---

## C# Built-in Search Methods

```csharp
// Array.BinarySearch — requires sorted array
int[] sorted = { 1, 3, 5, 7, 9, 11 };
int index = Array.BinarySearch(sorted, 7); // Returns 3
int missing = Array.BinarySearch(sorted, 4); // Returns -3 (bitwise complement of insert position)

// List<T>.BinarySearch
List<int> list = new List<int> { 1, 3, 5, 7, 9 };
int idx = list.BinarySearch(5); // Returns 2

// LINQ methods
int[] arr = { 5, 2, 8, 1, 9 };
bool exists = arr.Contains(8);        // O(n)
int first = arr.First(x => x > 5);   // O(n) — returns 8
int? found = arr.FirstOrDefault(x => x > 10); // null if not found

// Dictionary/HashSet — O(1) lookup
Dictionary<string, int> dict = new() { ["apple"] = 5 };
bool has = dict.ContainsKey("apple"); // O(1)
```

---

## Key Takeaways

| Concept | Summary |
|---|---|
| Linear Search | O(n) — works on unsorted, simple |
| Binary Search | O(log n) — requires sorted, eliminates half each step |
| Lower/Upper Bound | Find first/last occurrence of target |
| Rotated Array | One half is always sorted — decide which side |
| Binary Search on Answer | Search solution space, not array indices |
| Interpolation | O(log log n) for uniform data — estimates position |
| Exponential | Find range first, then binary search — for unbounded arrays |
| Overflow prevention | Use `left + (right - left) / 2` |

---

*Next Topic: Recursion & Dynamic Programming →*
