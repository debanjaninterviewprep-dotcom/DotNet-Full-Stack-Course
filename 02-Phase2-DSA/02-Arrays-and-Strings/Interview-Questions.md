# Topic 02: Arrays and Strings — Interview Questions

---

## Q1. What are the time complexities of common array operations?
**Answer:**
| Operation | Array | Dynamic Array (List) |
|---|---|---|
| Access by index | O(1) | O(1) |
| Search (unsorted) | O(n) | O(n) |
| Search (sorted, binary) | O(log n) | O(log n) |
| Insert at end | N/A (fixed) | O(1) amortized |
| Insert at middle/start | O(n) | O(n) |
| Delete at middle/start | O(n) | O(n) |
| Delete at end | N/A | O(1) |

Arrays provide O(1) random access because elements are stored contiguously in memory and the address of element `i` = `base + i × size`.

---

## Q2. What is the two-pointer technique?
**Answer:**
Use two indices (left and right, or slow and fast) to solve problems in O(n) that would naively be O(n²):

```csharp
// Two Sum in sorted array — O(n) time, O(1) space
int[] TwoSum(int[] sorted, int target)
{
    int l = 0, r = sorted.Length - 1;
    while (l < r)
    {
        int sum = sorted[l] + sorted[r];
        if (sum == target) return new[] { l, r };
        if (sum < target) l++;
        else r--;
    }
    return Array.Empty<int>();
}

// Remove duplicates from sorted array (slow/fast pointer)
int RemoveDups(int[] arr)
{
    int slow = 0;
    for (int fast = 1; fast < arr.Length; fast++)
        if (arr[fast] != arr[slow]) arr[++slow] = arr[fast];
    return slow + 1;
}
```

---

## Q3. What is the sliding window technique?
**Answer:**
Maintains a window (subarray/substring) that expands/shrinks from both ends to avoid recomputing from scratch on each step — reduces O(n²) or O(n³) to O(n):

```csharp
// Maximum sum subarray of size k — O(n)
int MaxSumSubarray(int[] arr, int k)
{
    int windowSum = arr.Take(k).Sum();
    int maxSum = windowSum;
    for (int i = k; i < arr.Length; i++)
    {
        windowSum += arr[i] - arr[i - k]; // slide: add new, remove old
        maxSum = Math.Max(maxSum, windowSum);
    }
    return maxSum;
}

// Longest substring without repeating chars — variable window, O(n)
int LengthOfLongestSubstring(string s)
{
    var seen = new Dictionary<char, int>();
    int maxLen = 0, start = 0;
    for (int end = 0; end < s.Length; end++)
    {
        if (seen.TryGetValue(s[end], out int prev) && prev >= start)
            start = prev + 1;
        seen[s[end]] = end;
        maxLen = Math.Max(maxLen, end - start + 1);
    }
    return maxLen;
}
```

---

## Q4. What is a prefix sum array and what problems does it solve?
**Answer:**
A prefix sum array `pre[i]` stores the cumulative sum of elements `arr[0..i]`. It enables O(1) range sum queries after O(n) preprocessing:

```csharp
// Build prefix sum — O(n)
int[] BuildPrefix(int[] arr)
{
    int[] pre = new int[arr.Length + 1];
    for (int i = 0; i < arr.Length; i++)
        pre[i + 1] = pre[i] + arr[i];
    return pre;
}

// Range sum query [l, r] — O(1)
int RangeSum(int[] pre, int l, int r) => pre[r + 1] - pre[l];

// Usage: count subarrays summing to target (hash map + prefix sum)
int SubarraySum(int[] nums, int target)
{
    var counts = new Dictionary<int, int> { [0] = 1 };
    int sum = 0, result = 0;
    foreach (int n in nums)
    {
        sum += n;
        result += counts.GetValueOrDefault(sum - target, 0);
        counts[sum] = counts.GetValueOrDefault(sum, 0) + 1;
    }
    return result;
}
```

---

## Q5. What is Kadane's algorithm?
**Answer:**
Kadane's algorithm finds the maximum sum contiguous subarray in O(n) time and O(1) space:

```csharp
int MaxSubarraySum(int[] nums)
{
    int maxSoFar = nums[0];
    int maxEndingHere = nums[0];

    for (int i = 1; i < nums.Length; i++)
    {
        // Either extend current subarray or start fresh from current element
        maxEndingHere = Math.Max(nums[i], maxEndingHere + nums[i]);
        maxSoFar = Math.Max(maxSoFar, maxEndingHere);
    }
    return maxSoFar;
}
// [-2,1,-3,4,-1,2,1,-5,4] → 6 ([4,-1,2,1])
```

**Key insight:** if `maxEndingHere` becomes negative, it can only hurt the next element, so we reset to just the current element.

---

## Q6. How do you find all duplicates in an array?
**Answer:**
Multiple approaches depending on constraints:

```csharp
// O(n) time, O(n) space — hash set
IList<int> FindDuplicates_HashSet(int[] nums)
{
    var seen = new HashSet<int>();
    var result = new List<int>();
    foreach (int n in nums)
        if (!seen.Add(n)) result.Add(n);
    return result;
}

// O(n) time, O(1) space — only works when values are in [1, n]
// Use index as a marker: negate visited index
IList<int> FindDuplicates_InPlace(int[] nums)
{
    var result = new List<int>();
    for (int i = 0; i < nums.Length; i++)
    {
        int idx = Math.Abs(nums[i]) - 1;
        if (nums[idx] < 0) result.Add(Math.Abs(nums[i]));
        else nums[idx] = -nums[idx];
    }
    return result;
}
```

---

## Q7. How do you rotate an array by k positions?
**Answer:**
```csharp
// Rotate right by k — O(n) time, O(1) space (three reverses)
void Rotate(int[] nums, int k)
{
    k %= nums.Length;
    Reverse(nums, 0, nums.Length - 1); // reverse all
    Reverse(nums, 0, k - 1);           // reverse first k
    Reverse(nums, k, nums.Length - 1); // reverse rest
}

void Reverse(int[] arr, int l, int r)
{
    while (l < r) { (arr[l], arr[r]) = (arr[r], arr[l]); l++; r--; }
}

// Example: [1,2,3,4,5], k=2 → [4,5,1,2,3]
```

---

## Q8. How do you check if two strings are anagrams?
**Answer:**
```csharp
// O(n) time, O(1) space (fixed 26-letter alphabet)
bool IsAnagram(string s, string t)
{
    if (s.Length != t.Length) return false;
    int[] count = new int[26];
    foreach (char c in s) count[c - 'a']++;
    foreach (char c in t) count[c - 'a']--;
    return count.All(x => x == 0);
}

// With sorting — O(n log n)
bool IsAnagram_Sort(string s, string t)
    => s.Length == t.Length && string.Concat(s.Order()) == string.Concat(t.Order());
```

---

## Q9. How do you find the missing number in an array of 1..n?
**Answer:**
```csharp
// Approach 1: sum formula — O(n) time, O(1) space
int MissingNumber_Sum(int[] nums)
{
    int n = nums.Length;
    int expected = n * (n + 1) / 2;
    return expected - nums.Sum();
}

// Approach 2: XOR — O(n) time, O(1) space (handles larger values)
int MissingNumber_XOR(int[] nums)
{
    int xor = 0;
    for (int i = 0; i <= nums.Length; i++) xor ^= i;
    foreach (int n in nums) xor ^= n;
    return xor; // XOR of all 0..n XOR array values — mismatched number survives
}
```

---

## Q10. What is matrix traversal and what are common patterns?
**Answer:**
```csharp
int[][] matrix = ...;
int rows = matrix.Length, cols = matrix[0].Length;

// Row-by-row (most common)
for (int r = 0; r < rows; r++)
    for (int c = 0; c < cols; c++)
        Process(matrix[r][c]);

// Spiral order traversal — O(n*m)
// Maintain top/bottom/left/right boundaries, shrink inward

// Diagonal traversal
for (int d = 0; d < rows + cols - 1; d++)
    for (int r = Math.Max(0, d - cols + 1); r <= Math.Min(d, rows - 1); r++)
        Process(matrix[r][d - r]);

// Transpose matrix in-place
for (int r = 0; r < rows; r++)
    for (int c = r + 1; c < cols; c++)
        (matrix[r][c], matrix[c][r]) = (matrix[c][r], matrix[r][c]);
```

---

## Q11. How do you find the longest common prefix of an array of strings?
**Answer:**
```csharp
// Horizontal scan — O(S) where S = total characters
string LongestCommonPrefix(string[] strs)
{
    if (strs.Length == 0) return "";
    string prefix = strs[0];
    for (int i = 1; i < strs.Length; i++)
        while (!strs[i].StartsWith(prefix))
            prefix = prefix[..^1]; // trim last character
    return prefix;
}

// Vertical scan — compare column by column
string LongestCommonPrefix_Vertical(string[] strs)
{
    for (int c = 0; c < strs[0].Length; c++)
        foreach (var s in strs)
            if (c >= s.Length || s[c] != strs[0][c])
                return strs[0][..c];
    return strs[0];
}
```

---

## Q12. What is the Dutch National Flag problem (3-way partition)?
**Answer:**
Sort an array containing only 0s, 1s, and 2s in O(n) time and O(1) space using three pointers:

```csharp
void SortColors(int[] nums)
{
    int low = 0, mid = 0, high = nums.Length - 1;
    while (mid <= high)
    {
        if (nums[mid] == 0)      { Swap(nums, low++, mid++); }
        else if (nums[mid] == 1) { mid++; }
        else                     { Swap(nums, mid, high--); }
    }
}
// [2,0,2,1,1,0] → [0,0,1,1,2,2]
```

This is a generalization of the two-pointer approach, also used in QuickSort's partition step.

---

## Q13. How do you find the first and last position of a target in a sorted array?
**Answer:**
Two binary searches — one for the left bound, one for the right bound — O(log n):

```csharp
int[] SearchRange(int[] nums, int target)
{
    return new[] { FindBound(nums, target, true), FindBound(nums, target, false) };
}

int FindBound(int[] nums, int target, bool isLeft)
{
    int lo = 0, hi = nums.Length - 1, bound = -1;
    while (lo <= hi)
    {
        int mid = lo + (hi - lo) / 2;
        if (nums[mid] == target)
        {
            bound = mid;
            if (isLeft) hi = mid - 1; // keep searching left
            else        lo = mid + 1; // keep searching right
        }
        else if (nums[mid] < target) lo = mid + 1;
        else hi = mid - 1;
    }
    return bound;
}
```

---

## Q14. What is the Boyer-Moore majority vote algorithm?
**Answer:**
Finds the majority element (appearing more than n/2 times) in O(n) time and O(1) space:

```csharp
int MajorityElement(int[] nums)
{
    int candidate = nums[0], count = 1;
    for (int i = 1; i < nums.Length; i++)
    {
        if (count == 0) { candidate = nums[i]; count = 1; }
        else if (nums[i] == candidate) count++;
        else count--;
    }
    return candidate; // guaranteed to be majority if one exists
}
// [2,2,1,1,1,2,2] → 2 (appears 4 > 7/2 times)
```

**Key insight:** majority votes cancel out minority votes. The surviving candidate must be the majority.

---

## Q15. How do you find the product of all elements except self without division?
**Answer:**
Build a prefix product array and a suffix product array, then multiply:

```csharp
// O(n) time, O(1) extra space (output array doesn't count)
int[] ProductExceptSelf(int[] nums)
{
    int n = nums.Length;
    int[] result = new int[n];
    result[0] = 1;

    // Left pass: result[i] = product of all elements to the left
    for (int i = 1; i < n; i++)
        result[i] = result[i - 1] * nums[i - 1];

    // Right pass: multiply by product of all elements to the right
    int right = 1;
    for (int i = n - 1; i >= 0; i--)
    {
        result[i] *= right;
        right *= nums[i];
    }
    return result;
}
// [1,2,3,4] → [24,12,8,6]
```
