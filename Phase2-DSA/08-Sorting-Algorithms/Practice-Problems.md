# Topic 8: Sorting Algorithms — Practice Problems

## Problem 1: Implement Basic Sorts (Easy)
**Concept**: O(n²) sorting algorithms

Implement all three from scratch and compare:

### 1a. Bubble Sort
### 1b. Selection Sort
### 1c. Insertion Sort

For each:
- Sort `[64, 34, 25, 12, 22, 11, 90]`
- Print the array after each pass/step
- Count the number of comparisons and swaps
- Test with: already sorted, reverse sorted, single element, empty array

**Expected Output:**
```
=== Bubble Sort ===
Pass 1: [34, 25, 12, 22, 11, 64, 90]
Pass 2: [25, 12, 22, 11, 34, 64, 90]
...
Result: [11, 12, 22, 25, 34, 64, 90]
Comparisons: 21, Swaps: 13

=== Selection Sort ===
Pass 1: [11, 34, 25, 12, 22, 64, 90] (min=11, swap with 64)
...
Comparisons: 21, Swaps: 4

=== Insertion Sort ===
Step 1: [34, 64, 25, 12, 22, 11, 90] (34 in place)
...
Comparisons: 13, Swaps: 13
```

---

## Problem 2: Divide and Conquer Sorts (Medium)
**Concept**: Merge sort and quick sort

### 2a. Merge Sort
- Implement merge sort with step-by-step visualization
- Print each split and merge operation
```
Splitting: [38, 27, 43, 3, 9, 82, 10]
  Left: [38, 27, 43, 3], Right: [9, 82, 10]
  ...
Merging: [27, 38] + [3, 43] → [3, 27, 38, 43]
...
```

### 2b. Quick Sort
- Implement with last element as pivot
- Print pivot choice and partition result each step
```
Array: [10, 7, 8, 9, 1, 5], Pivot: 5
After partition: [1, 5, 8, 9, 10, 7], Pivot at index 1
...
```

### 2c. Quick Sort with Random Pivot
Implement and run both versions 100 times on a reverse-sorted array of size 1000. Compare average step counts.

### 2d. Merge Sort vs Quick Sort Benchmark
Sort arrays of sizes 100, 1,000, 10,000, and 100,000 with both algorithms. 
Use `Stopwatch` to measure and compare execution times.

---

## Problem 3: Sorting Applications (Medium)
**Concept**: Using sorting to solve problems

### 3a. Sort an Array of Strings by Length
```
Input: ["banana", "kiwi", "apple", "fig", "cherry"]
Output: ["fig", "kiwi", "apple", "banana", "cherry"]
```
If same length, sort alphabetically.

### 3b. Sort an Array of 0s, 1s, and 2s (Dutch National Flag)
```
Input: [2, 0, 1, 2, 1, 0, 0, 1, 2]
Output: [0, 0, 0, 1, 1, 1, 2, 2, 2]
```
Do it in O(n) time, O(1) space — no counting sort!

### 3c. Kth Largest Element
Find the kth largest element without fully sorting.
```
Input: [3, 2, 1, 5, 6, 4], k = 2
Output: 5
```
Use QuickSelect (partition-based) for O(n) average.

### 3d. Merge Intervals
```
Input: [[1,3], [2,6], [8,10], [15,18]]
Output: [[1,6], [8,10], [15,18]]
```
Sort by start time, then merge overlapping.

### 3e. Sort Characters by Frequency
```
Input: "tree"
Output: "eert" or "eetr" (e appears 2 times)
```

---

## Problem 4: Non-Comparison Sorts & Analysis (Medium-Hard)
**Concept**: Counting sort, radix sort, stability

### 4a. Counting Sort
Implement counting sort and sort: `[4, 2, 2, 8, 3, 3, 1, 7, 5, 5, 5]`

### 4b. Stable Counting Sort
Implement the stable version that preserves relative order.
Test with objects: sort students by grade (students with same grade keep original order).
```
Input: [("Alice", B), ("Bob", A), ("Charlie", B), ("Dave", A)]
Output: [("Bob", A), ("Dave", A), ("Alice", B), ("Charlie", B)]
(Alice before Charlie because same grade, original order preserved)
```

### 4c. Radix Sort
Sort: `[170, 45, 75, 90, 802, 24, 2, 66]`
Print the array after sorting by each digit position.

### 4d. Stability Test
Create a test that proves:
- Merge sort IS stable
- Quick sort is NOT stable
- Counting sort (your implementation) IS stable

Use records like `(Value, OriginalIndex)` and verify order of equal elements after sorting.

---

## Problem 5: Sorting Challenge (Hard)
**Concept**: Build a sorting algorithm visualizer and analyzer

### Build a Sorting Algorithm Comparison Tool

Create a program that:

1. **Generates** test arrays: random, sorted, reverse-sorted, nearly sorted, many duplicates
2. **Runs** these algorithms: Bubble, Selection, Insertion, Merge, Quick, Counting
3. **Measures** for each: time (ms), comparisons, swaps/moves
4. **Displays** a comparison table

**Expected Output:**
```
=== Sorting Algorithm Comparison ===
Array Size: 10,000 | Type: Random

Algorithm       | Time (ms) | Comparisons  | Swaps/Moves  | Stable
----------------|-----------|-------------|-------------|-------
Bubble Sort     | 342       | 49,995,000  | 25,102,341  | Yes
Selection Sort  | 178       | 49,995,000  | 9,999       | No
Insertion Sort  | 156       | 24,897,234  | 24,897,234  | Yes
Merge Sort      | 3         | 120,472     | 133,616     | Yes
Quick Sort      | 2         | 156,234     | 67,890      | No
Counting Sort   | 1         | 10,000      | 10,000      | Yes

=== Nearly Sorted Array (10,000 elements) ===
Algorithm       | Time (ms) | Comparisons  | Swaps/Moves
----------------|-----------|-------------|------------
Bubble Sort     | 2         | 10,050      | 50
Insertion Sort  | 1         | 10,050      | 50
Quick Sort      | 2         | 156,000     | 67,000
(Notice: Insertion Sort dominates on nearly sorted data!)

=== Best Algorithm by Scenario ===
Random data:     Quick Sort / Merge Sort
Nearly sorted:   Insertion Sort
Integers 0-100:  Counting Sort
Stability needed: Merge Sort
Memory limited:   Heap Sort
```

**Bonus**: Add a `Custom Hybrid Sort` that picks the best algorithm based on input characteristics:
- Small array (< 50): Insertion sort
- Integer range < 1000: Counting sort
- General: Quick sort with random pivot

---

### Submission
- Create a new console project: `dotnet new console -n SortingPractice`
- Solve all problems
- Comment each with **Time: O(?), Space: O(?)**
- Test edge cases: empty, single element, all same, alternating
- Tell me "check" when you're ready for review!
