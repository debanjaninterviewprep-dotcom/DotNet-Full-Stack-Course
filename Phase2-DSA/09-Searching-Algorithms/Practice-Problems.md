# Topic 9: Searching Algorithms — Practice Problems

## Problem 1: Binary Search Fundamentals (Easy)
**Concept**: Basic binary search and variants

### 1a. Implement Binary Search
Both iterative and recursive. Test with:
```
Sorted array: [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]
Search 23 → found at index 5
Search 50 → not found (-1)
```

### 1b. First and Last Occurrence
Find the first and last position of a target in a sorted array with duplicates.
```
Input: [1, 2, 2, 2, 3, 4, 4], target = 2
Output: First = 1, Last = 3, Count = 3
```

### 1c. Search Insert Position
```
[1, 3, 5, 6], target = 5 → 2 (found)
[1, 3, 5, 6], target = 2 → 1 (insert position)
[1, 3, 5, 6], target = 7 → 4 (insert at end)
```

### 1d. Floor and Ceiling
```
Array: [1, 2, 8, 10, 10, 12, 19]
Floor(5) = 2  (largest ≤ 5)
Ceiling(5) = 8 (smallest ≥ 5)
Floor(10) = 10
Ceiling(10) = 10
```

**Expected Output:**
```
=== Binary Search ===
[2, 5, 8, 12, 16, 23, 38, 56, 72, 91]
Search(23): found at index 5
Search(50): not found

=== First/Last Occurrence ===
[1, 2, 2, 2, 3, 4, 4], target=2
First: 1, Last: 3, Count: 3

=== Insert Position ===
target=2 in [1,3,5,6] → position 1

=== Floor & Ceiling ===
Floor(5) = 2, Ceiling(5) = 8
```

---

## Problem 2: Binary Search Applications (Easy-Medium)
**Concept**: Using binary search creatively

### 2a. Find Square Root (Integer Part)
```
Input: 8 → Output: 2 (√8 ≈ 2.83, floor = 2)
Input: 16 → Output: 4
Input: 0 → Output: 0
```

### 2b. Find Peak Element
```
Input: [1, 2, 3, 1] → 2 (index of peak 3)
Input: [1, 2, 1, 3, 5, 6, 4] → 1 or 5 (any peak)
```

### 2c. Search a 2D Matrix
Matrix where each row is sorted, and first element of each row > last element of previous row.
```
Matrix:
[1,  3,  5,  7]
[10, 11, 16, 20]
[23, 30, 34, 60]

Search 3 → true (row 0, col 1)
Search 13 → false
```
Treat as a single sorted array → O(log(m×n))

### 2d. Find Missing Number
In a sorted array from 0 to n with one number missing:
```
Input: [0, 1, 2, 3, 5, 6, 7]
Output: 4
```
Use binary search: if `arr[mid] == mid`, missing is on right; else on left.

---

## Problem 3: Rotated Array Problems (Medium)
**Concept**: Binary search on rotated sorted arrays

### 3a. Search in Rotated Sorted Array
```
Input: [4, 5, 6, 7, 0, 1, 2], target = 0
Output: 4

Input: [4, 5, 6, 7, 0, 1, 2], target = 3
Output: -1
```

### 3b. Find Minimum in Rotated Array
```
Input: [3, 4, 5, 1, 2] → 1
Input: [4, 5, 6, 7, 0, 1, 2] → 0
Input: [11, 13, 15, 17] → 11 (not rotated)
```

### 3c. Find Rotation Count
How many times has a sorted array been rotated?
```
Input: [15, 18, 2, 3, 6, 12] → rotated 2 times
Input: [7, 9, 11, 12, 5] → rotated 4 times
```
Hint: This equals the index of the minimum element.

### 3d. Search in Rotated Array with Duplicates
```
Input: [2, 5, 6, 0, 0, 1, 2], target = 0
Output: true
```
This is harder because duplicates break the "which half is sorted?" check.

---

## Problem 4: Binary Search on Answer Space (Medium-Hard)
**Concept**: Binary search not on an array, but on the solution space

### 4a. Minimum Capacity to Ship Packages
Ship packages within `days` days. Find minimum weight capacity.
```
Weights: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], days = 5
Output: 15
(Day 1: [1,2,3,4,5], Day 2: [6,7], Day 3: [8], Day 4: [9], Day 5: [10])
```
Binary search between max(weights) and sum(weights).

### 4b. Koko Eating Bananas
Koko eats bananas at speed k per hour. Find minimum k to finish in h hours.
```
Piles: [3, 6, 7, 11], hours = 8
Output: 4
(With k=4: ceil(3/4)+ceil(6/4)+ceil(7/4)+ceil(11/4) = 1+2+2+3 = 8 hours)
```

### 4c. Find the Duplicate Number
Array of n+1 integers in range [1, n]. One number is duplicated. Find it.
```
Input: [1, 3, 4, 2, 2]
Output: 2
```
Solve with: (a) Binary search on count, (b) Floyd's cycle detection

### 4d. Split Array Largest Sum
Split array into m subarrays to minimize the largest sum.
```
Input: [7, 2, 5, 10, 8], m = 2
Output: 18 (split: [7,2,5] and [10,8], sums are 14 and 18)
```
Binary search between max(arr) and sum(arr).

---

## Problem 5: Comprehensive Search Challenge (Hard)
**Concept**: Build a search engine with multiple algorithms

### Build a Search Algorithm Benchmarker

Create a program that:
1. Generates sorted arrays of various sizes (100, 10K, 1M, 10M)
2. Implements: Linear, Binary, Interpolation, Exponential search
3. Measures and compares performance
4. Tests edge cases systematically

**Required Features:**
- Generate test data: uniform distribution, clustered, sparse
- Search random existing elements and non-existing elements
- Measure: time per search (averaged over 1000 searches), comparisons count

**Expected Output:**
```
=== Search Algorithm Benchmark ===

Array Size: 1,000,000 (Uniform Distribution)
Searching 1000 random existing targets...

Algorithm           | Avg Time (μs) | Avg Comparisons | Found All
--------------------|---------------|-----------------|----------
Linear Search       | 245.3         | 500,234         | Yes
Binary Search       | 0.8           | 19.9            | Yes
Interpolation Search| 0.5           | 4.2             | Yes
Exponential Search  | 1.1           | 21.3            | Yes

Array Size: 1,000,000 (Clustered Distribution)
Algorithm           | Avg Time (μs) | Avg Comparisons
--------------------|---------------|----------------
Interpolation Search| 5.3           | 12.8   ← worse on clustered!
Binary Search       | 0.8           | 19.9   ← consistent!

=== Edge Case Tests ===
Empty array:        All return -1 ✓
Single element:     Found/Not found ✓
Target at start:    All found ✓
Target at end:      All found ✓
All same elements:  Correct behavior ✓
Large values:       No overflow ✓
```

**Bonus:** Add a `SmartSearch` function that automatically picks the best algorithm based on:
- Array size (< 50? Use linear)
- Is it sorted? (No → linear or hash lookup)
- Distribution (uniform → interpolation, otherwise → binary)

---

### Submission
- Create a new console project: `dotnet new console -n SearchingPractice`
- Solve all problems
- Comment each with **Time: O(?), Space: O(?)**
- Test edge cases: empty array, single element, target at boundaries
- Tell me "check" when you're ready for review!
