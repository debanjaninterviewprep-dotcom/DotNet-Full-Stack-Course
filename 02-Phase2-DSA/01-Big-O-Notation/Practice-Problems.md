# Topic 1: Big-O Notation & Complexity Analysis — Practice Problems

## Problem 1: Complexity Identifier (Easy)
**Concept**: Identify Big-O from code

For each code snippet below, determine the **time complexity** and **space complexity**. Write your answers as comments.

```csharp
// Snippet A
void PrintFirst(int[] arr) => Console.WriteLine(arr[0]);

// Snippet B
int Sum(int[] arr)
{
    int total = 0;
    foreach (int n in arr) total += n;
    return total;
}

// Snippet C
void PrintPairs(int[] arr)
{
    for (int i = 0; i < arr.Length; i++)
        for (int j = 0; j < arr.Length; j++)
            Console.WriteLine($"{arr[i]}, {arr[j]}");
}

// Snippet D
int BinarySearch(int[] sorted, int target)
{
    int left = 0, right = sorted.Length - 1;
    while (left <= right)
    {
        int mid = (left + right) / 2;
        if (sorted[mid] == target) return mid;
        else if (sorted[mid] < target) left = mid + 1;
        else right = mid - 1;
    }
    return -1;
}

// Snippet E
void PrintTriangle(int n)
{
    for (int i = 0; i < n; i++)
        for (int j = 0; j <= i; j++)
            Console.Write("*");
}

// Snippet F
void PrintUniquePairs(int[] arr)
{
    for (int i = 0; i < arr.Length; i++)
        for (int j = i + 1; j < arr.Length; j++)
            Console.WriteLine($"{arr[i]}, {arr[j]}");
}

// Snippet G
int Recursive(int n)
{
    if (n <= 0) return 0;
    return Recursive(n - 1) + Recursive(n - 1);
}

// Snippet H
void ThreeLoops(int[] arr)
{
    foreach (int a in arr) Console.Write(a);
    foreach (int b in arr) Console.Write(b);
    foreach (int c in arr) Console.Write(c);
}
```

**Expected Format:**
```
Snippet A: Time O(?), Space O(?)
Snippet B: Time O(?), Space O(?)
...
```

---

## Problem 2: Complexity Comparison Tool (Easy-Medium)
**Concept**: Measure actual performance, compare algorithms

Build a program that **measures execution time** for different complexities:

1. Implement these operations:
   - `O1_Access(int[] arr)` — access middle element
   - `OLogN_BinarySearch(int[] sorted, int target)` — binary search
   - `ON_LinearSearch(int[] arr, int target)` — linear search
   - `ONLogN_Sort(int[] arr)` — Array.Sort
   - `ON2_BubbleSort(int[] arr)` — bubble sort

2. Run each on arrays of sizes: 1,000 / 10,000 / 100,000 / 1,000,000
3. Use `Stopwatch` to measure time in milliseconds
4. Display a comparison table
5. Show how time grows as input doubles

**Expected Output:**
```
=== Complexity Benchmark ===

| Algorithm       | 1,000  | 10,000  | 100,000  | 1,000,000 | Growth   |
|-----------------|--------|---------|----------|-----------|----------|
| O(1) Access     | 0.001ms| 0.001ms | 0.001ms  | 0.001ms   | Constant |
| O(log n) Binary | 0.002ms| 0.003ms | 0.004ms  | 0.005ms   | ~log     |
| O(n) Linear     | 0.01ms | 0.1ms   | 1ms      | 10ms      | ~10x     |
| O(n log n) Sort | 0.05ms | 0.8ms   | 10ms     | 120ms     | ~12x     |
| O(n²) Bubble    | 2ms    | 200ms   | 20,000ms | TOO SLOW  | ~100x    |

Observation: Bubble sort becomes impractical above 100K items.
```

---

## Problem 3: Optimize the Brute Force (Medium)
**Concept**: Identify inefficiency, optimize with better data structures

For each problem below, first write a **brute force O(n²)** solution, then optimize to **O(n)** or **O(n log n)**. Report both complexities.

### 3a. Two Sum
Given an array and a target, find two numbers that add up to the target. Return their indices.
```
Input: [2, 7, 11, 15], target = 9
Output: [0, 1] (because 2 + 7 = 9)
```

### 3b. Find Duplicates
Return all duplicate elements in an array.
```
Input: [1, 3, 4, 2, 2, 3]
Output: [2, 3]
```

### 3c. Intersection of Two Arrays
Return elements common to both arrays (unique).
```
Input: [1, 2, 2, 1], [2, 2, 3]
Output: [2]
```

### 3d. First Non-Repeating Character
Find the first character in a string that doesn't repeat.
```
Input: "aabbcdd"
Output: 'c'
```

For each, print:
```
=== Two Sum ===
Brute Force: O(n²) — 45.2ms for 100,000 items
Optimized:   O(n)  — 1.3ms for 100,000 items
Speedup: 34.8x
```

---

## Problem 4: Space-Time Tradeoff Analyzer (Medium-Hard)
**Concept**: Demonstrate space-time tradeoffs

Show how using **extra memory** can dramatically improve **time**, and vice versa.

### Scenarios:

1. **Anagram Checker** — Are two strings anagrams?
   - Version A: Sort both strings, compare → Time: O(n log n), Space: O(n)
   - Version B: Count characters with int[26] → Time: O(n), Space: O(1)
   - Version C: Count characters with Dictionary → Time: O(n), Space: O(n)

2. **Fibonacci**
   - Version A: Naive recursion → Time: O(2ⁿ), Space: O(n) stack
   - Version B: Memoization (array) → Time: O(n), Space: O(n)
   - Version C: Iterative → Time: O(n), Space: O(1)

3. **Contains Duplicate within K distance**
   Given array and k, check if there are duplicates within k indices of each other.
   - Version A: Brute force nested loop → Time: O(n×k), Space: O(1)
   - Version B: Sliding window HashSet → Time: O(n), Space: O(k)

For each scenario:
- Implement ALL versions
- Benchmark with increasing input sizes
- Display the tradeoff table

**Expected Output:**
```
=== Space-Time Tradeoffs ===

--- Anagram Checker (n = 1,000,000) ---
| Version     | Time    | Space  | Approach          |
|-------------|---------|--------|-------------------|
| Sort-based  | 120ms   | O(n)   | Sort + compare    |
| Array count | 5ms     | O(1)   | Fixed array[26]   |
| Dict count  | 15ms    | O(n)   | Dictionary        |
Winner: Array count (fastest + least space)

--- Fibonacci (n = 40) ---
| Version     | Time      | Space | Approach       |
|-------------|-----------|-------|----------------|
| Recursive   | 1,200ms   | O(n)  | 2^n calls      |
| Memoized    | 0.001ms   | O(n)  | Cache results  |
| Iterative   | 0.001ms   | O(1)  | Two variables  |
Winner: Iterative (same speed, less space)
```

---

## Problem 5: Algorithm Complexity Analyzer Tool (Hard)
**Concept**: Empirically determine Big-O of unknown functions

Build a tool that **automatically determines the Big-O** of a given function by running it at multiple input sizes and analyzing the growth pattern.

**ComplexityAnalyzer Class:**
```csharp
class ComplexityAnalyzer
{
    // Takes a function that accepts input size and runs the algorithm
    // Returns the detected complexity as a string
    string Analyze(Action<int> algorithm, int[] testSizes);
}
```

**How it works:**
1. Run the algorithm at sizes: 100, 200, 400, 800, 1600, 3200
2. Measure execution time for each
3. Calculate the **ratio** of time between consecutive sizes:
   - Ratio ≈ 1.0 → O(1)
   - Ratio ≈ 1.0-1.2 → O(log n) (grows very slowly)
   - Ratio ≈ 2.0 → O(n)
   - Ratio ≈ 2.0-2.5 → O(n log n)
   - Ratio ≈ 4.0 → O(n²)
   - Ratio ≈ 8.0 → O(n³)
4. Display analysis with confidence level

**Test with these mystery functions:**
```csharp
// Mystery 1
void Mystery1(int n) { /* some algorithm */ }

// Mystery 2
void Mystery2(int n) { /* some algorithm */ }

// Mystery 3
void Mystery3(int n) { /* some algorithm */ }
```

Create at least 5 mystery functions with different complexities. The analyzer should correctly identify each.

**Expected Output:**
```
=== Complexity Analyzer ===

Analyzing Mystery1...
  n=100:  0.01ms
  n=200:  0.02ms  (ratio: 2.0)
  n=400:  0.04ms  (ratio: 2.0)
  n=800:  0.08ms  (ratio: 2.0)
  n=1600: 0.16ms  (ratio: 2.0)
  n=3200: 0.32ms  (ratio: 2.0)
  Average ratio: 2.0
  → Detected: O(n) [Confidence: HIGH]

Analyzing Mystery2...
  n=100:  1ms
  n=200:  4ms     (ratio: 4.0)
  n=400:  16ms    (ratio: 4.0)
  n=800:  64ms    (ratio: 4.0)
  → Detected: O(n²) [Confidence: HIGH]

Analyzing Mystery3...
  n=100:  0.05ms
  n=200:  0.12ms  (ratio: 2.4)
  n=400:  0.28ms  (ratio: 2.3)
  → Detected: O(n log n) [Confidence: MEDIUM]

Summary:
  Mystery1: O(n)       ✓
  Mystery2: O(n²)      ✓
  Mystery3: O(n log n) ✓
  Mystery4: O(1)       ✓
  Mystery5: O(log n)   ✓
```

---

### Submission
- Create a new console project: `dotnet new console -n BigOPractice`
- Solve all 5 problems in `Program.cs`
- For Problem 1, write answers as comments
- For Problems 2-5, include actual benchmarks
- Tell me "check" when you're ready for review!
