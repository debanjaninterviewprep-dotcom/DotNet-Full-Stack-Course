# Topic 09: Searching Algorithms — Interview Questions

---

## Q1. What is linear search and when is it used?
**Answer:**
Linear search scans every element one by one until the target is found:

```csharp
int LinearSearch(int[] arr, int target)
{
    for (int i = 0; i < arr.Length; i++)
        if (arr[i] == target) return i;
    return -1;
}
// Time: O(n), Space: O(1)
```

**Use when:**
- Array is unsorted.
- Array is very small (n < 50).
- One-time search (not worth sorting first).
- Searching linked lists or streams.

---

## Q2. What is binary search and what are its requirements?
**Answer:**
Binary search halves the search space each step — requires a **sorted** array:

```csharp
int BinarySearch(int[] arr, int target)
{
    int lo = 0, hi = arr.Length - 1;
    while (lo <= hi)
    {
        int mid = lo + (hi - lo) / 2; // avoids integer overflow vs (lo+hi)/2
        if (arr[mid] == target) return mid;
        if (arr[mid] < target) lo = mid + 1;
        else hi = mid - 1;
    }
    return -1; // not found
}
// Time: O(log n), Space: O(1)
```

**Key pitfall:** `mid = (lo + hi) / 2` can overflow for large indices. Always use `lo + (hi - lo) / 2`.

---

## Q3. How do you find the first and last occurrence of a target using binary search?
**Answer:**
```csharp
// First occurrence (leftmost)
int FirstOccurrence(int[] arr, int target)
{
    int lo = 0, hi = arr.Length - 1, result = -1;
    while (lo <= hi)
    {
        int mid = lo + (hi - lo) / 2;
        if (arr[mid] == target) { result = mid; hi = mid - 1; } // go left
        else if (arr[mid] < target) lo = mid + 1;
        else hi = mid - 1;
    }
    return result;
}

// Last occurrence (rightmost)
int LastOccurrence(int[] arr, int target)
{
    int lo = 0, hi = arr.Length - 1, result = -1;
    while (lo <= hi)
    {
        int mid = lo + (hi - lo) / 2;
        if (arr[mid] == target) { result = mid; lo = mid + 1; } // go right
        else if (arr[mid] < target) lo = mid + 1;
        else hi = mid - 1;
    }
    return result;
}
```

---

## Q4. How do you search in a rotated sorted array?
**Answer:**
One half of the array is always sorted — use that to decide which half to search:

```csharp
int SearchRotated(int[] nums, int target)
{
    int lo = 0, hi = nums.Length - 1;
    while (lo <= hi)
    {
        int mid = lo + (hi - lo) / 2;
        if (nums[mid] == target) return mid;

        // Left half is sorted
        if (nums[lo] <= nums[mid])
        {
            if (nums[lo] <= target && target < nums[mid]) hi = mid - 1;
            else lo = mid + 1;
        }
        // Right half is sorted
        else
        {
            if (nums[mid] < target && target <= nums[hi]) lo = mid + 1;
            else hi = mid - 1;
        }
    }
    return -1;
}
// [4,5,6,7,0,1,2], target=0 → 4
```

---

## Q5. How do you find the minimum in a rotated sorted array?
**Answer:**
```csharp
int FindMin(int[] nums)
{
    int lo = 0, hi = nums.Length - 1;
    while (lo < hi)
    {
        int mid = lo + (hi - lo) / 2;
        if (nums[mid] > nums[hi]) lo = mid + 1; // min is in right half
        else hi = mid;                           // min is in left half (including mid)
    }
    return nums[lo];
}
// [3,4,5,1,2] → 1, [4,5,6,7,0,1,2] → 0
```

---

## Q6. What is the square root problem using binary search?
**Answer:**
```csharp
// Integer square root: find largest x such that x*x <= n
int MySqrt(int n)
{
    if (n < 2) return n;
    int lo = 1, hi = n / 2, result = 1;
    while (lo <= hi)
    {
        int mid = lo + (hi - lo) / 2;
        long sq = (long)mid * mid; // prevent int overflow
        if (sq == n) return mid;
        if (sq < n) { result = mid; lo = mid + 1; }
        else hi = mid - 1;
    }
    return result;
}
// mySqrt(8) → 2 (2² = 4 ≤ 8 < 9 = 3²)
```

---

## Q7. What is "binary search on the answer" and how does it work?
**Answer:**
When the answer has a monotonic property (if x works, x-1 also works — or vice versa), binary search on the answer space instead of the array:

```csharp
// Koko Eating Bananas: find minimum speed k to eat all bananas in h hours
int MinEatingSpeed(int[] piles, int h)
{
    int lo = 1, hi = piles.Max();
    while (lo < hi)
    {
        int mid = lo + (hi - lo) / 2;
        // Can Koko eat all piles at speed mid within h hours?
        if (CanFinish(piles, mid, h)) hi = mid; // try slower
        else lo = mid + 1;
    }
    return lo;

    bool CanFinish(int[] p, int speed, int hours)
        => p.Sum(pile => (pile + speed - 1) / speed) <= hours;
}
```

**Other examples:** Capacity to Ship Packages, Split Array Largest Sum, Magnetic Force Between Balls.

---

## Q8. What is jump search and when is it better than binary search?
**Answer:**
Jump search skips ahead by √n steps, then does linear search in the found block:

```csharp
int JumpSearch(int[] arr, int target)
{
    int n = arr.Length;
    int step = (int)Math.Sqrt(n);
    int prev = 0;

    // Jump until we find a block that may contain the target
    while (arr[Math.Min(step, n) - 1] < target)
    {
        prev = step;
        step += (int)Math.Sqrt(n);
        if (prev >= n) return -1;
    }

    // Linear search in the block
    for (int i = prev; i < Math.Min(step, n); i++)
        if (arr[i] == target) return i;

    return -1;
}
// Time: O(√n), Space: O(1)
```

Jump search is useful when the array is **on disk** and random access (binary search's backward jump) is expensive — √n jumps are always forward.

---

## Q9. What is interpolation search?
**Answer:**
Estimates the position of the target based on its value, assuming uniform distribution — faster than binary search for uniformly distributed sorted data:

```csharp
int InterpolationSearch(int[] arr, int target)
{
    int lo = 0, hi = arr.Length - 1;
    while (lo <= hi && target >= arr[lo] && target <= arr[hi])
    {
        if (lo == hi) return arr[lo] == target ? lo : -1;

        // Estimate position
        int pos = lo + (int)((long)(target - arr[lo]) * (hi - lo) / (arr[hi] - arr[lo]));

        if (arr[pos] == target) return pos;
        if (arr[pos] < target) lo = pos + 1;
        else hi = pos - 1;
    }
    return -1;
}
// Time: O(log log n) average for uniform data, O(n) worst case
```

---

## Q10. How do you find the peak element in an array?
**Answer:**
A peak is an element greater than its neighbors. Binary search works because: if `arr[mid] < arr[mid+1]`, a peak must exist in the right half:

```csharp
int FindPeakElement(int[] nums)
{
    int lo = 0, hi = nums.Length - 1;
    while (lo < hi)
    {
        int mid = lo + (hi - lo) / 2;
        if (nums[mid] < nums[mid + 1]) lo = mid + 1; // peak is to the right
        else hi = mid;                                // peak is here or to the left
    }
    return lo;
}
// [1,2,3,1] → 2 (index of element 3)
// [1,2,1,3,5,6,4] → 5 or 1 (either peak is valid)
```

---

## Q11. How do you search a 2D matrix?
**Answer:**
**Approach 1: Treat as flattened sorted array — O(log(m*n))**
```csharp
bool SearchMatrix(int[][] matrix, int target)
{
    int m = matrix.Length, n = matrix[0].Length;
    int lo = 0, hi = m * n - 1;
    while (lo <= hi)
    {
        int mid = lo + (hi - lo) / 2;
        int val = matrix[mid / n][mid % n];
        if (val == target) return true;
        if (val < target) lo = mid + 1;
        else hi = mid - 1;
    }
    return false;
}
```

**Approach 2: Staircase search (each row ascending, each column ascending) — O(m+n)**
```csharp
bool SearchMatrix2(int[][] matrix, int target)
{
    int r = 0, c = matrix[0].Length - 1; // start at top-right
    while (r < matrix.Length && c >= 0)
    {
        if (matrix[r][c] == target) return true;
        if (matrix[r][c] > target) c--; // eliminate column
        else r++;                        // eliminate row
    }
    return false;
}
```

---

## Q12. What is ternary search and when is it used?
**Answer:**
Ternary search divides the search space into thirds, useful for finding the maximum/minimum of a **unimodal function** (one peak/valley):

```csharp
// Find maximum of a unimodal function f(x) on [lo, hi]
double TernarySearch(Func<double, double> f, double lo, double hi, int iterations = 200)
{
    for (int i = 0; i < iterations; i++)
    {
        double m1 = lo + (hi - lo) / 3;
        double m2 = hi - (hi - lo) / 3;
        if (f(m1) < f(m2)) lo = m1;
        else hi = m2;
    }
    return (lo + hi) / 2;
}
// Time: O(log₃(n)) = O(log n), slightly worse than binary search
```

Applications: convex/concave function optimization, geometry problems.

---

## Q13. What is exponential search?
**Answer:**
Finds the range where the target exists by doubling the index, then applies binary search — useful for **unbounded arrays** or when target is near the beginning:

```csharp
int ExponentialSearch(int[] arr, int target)
{
    if (arr[0] == target) return 0;

    int bound = 1;
    while (bound < arr.Length && arr[bound] <= target)
        bound *= 2; // double until we exceed target

    // Binary search in [bound/2, min(bound, n-1)]
    return BinarySearch(arr, target, bound / 2, Math.Min(bound, arr.Length - 1));
}
// Time: O(log n), Space: O(1)
```

---

## Q14. How do you count occurrences of a target in a sorted array?
**Answer:**
Use binary search to find first and last occurrences:

```csharp
int CountOccurrences(int[] arr, int target)
{
    int first = FirstOccurrence(arr, target);
    if (first == -1) return 0;
    int last = LastOccurrence(arr, target);
    return last - first + 1;
}
// [1,2,2,2,3,4,5], target=2 → 3
// Time: O(log n)
```

---

## Q15. What is the time complexity comparison of all search algorithms?
**Answer:**
| Algorithm | Best | Average | Worst | Space | Requires Sorted? |
|---|---|---|---|---|---|
| Linear Search | O(1) | O(n) | O(n) | O(1) | No |
| Binary Search | O(1) | O(log n) | O(log n) | O(1) | Yes |
| Jump Search | O(1) | O(√n) | O(√n) | O(1) | Yes |
| Interpolation | O(1) | O(log log n) | O(n) | O(1) | Yes (uniform) |
| Exponential | O(1) | O(log n) | O(log n) | O(1) | Yes |
| Ternary Search | O(1) | O(log₃ n) | O(log₃ n) | O(1) | Unimodal |
| Hash Search | O(1) | O(1) | O(n)* | O(n) | No |

*Hash search O(n) worst case due to collisions. In practice nearly always O(1).

**Rule of thumb:** For sorted data, binary search is the gold standard. For unsorted data on small inputs, linear search. For unsorted data at scale, build a hash map.
