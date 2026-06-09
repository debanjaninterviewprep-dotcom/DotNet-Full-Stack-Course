# Topic 1: Big-O Notation & Complexity Analysis

## Why Complexity Analysis?

When you write code, there are often **many ways** to solve the same problem. Complexity analysis helps you answer: **which solution is better?** — not by running it, but by **mathematically analyzing** how it scales.

```csharp
// Approach A: Check if a list contains a value
bool ContainsA(List<int> list, int target)
{
    foreach (int item in list)
        if (item == target) return true;
    return false;
}
// What happens when list has 1 million items?

// Approach B: Use a HashSet
bool ContainsB(HashSet<int> set, int target)
{
    return set.Contains(target);
}
// What happens when set has 1 million items?
```

Approach A checks items **one by one** — time grows linearly. Approach B uses hashing — time stays **constant** regardless of size.

---

## What is Big-O Notation?

Big-O describes the **upper bound** of how an algorithm's time or space grows as the input size `n` increases. It focuses on the **worst case** and **dominant terms**.

```
Big-O answers: "As input grows towards infinity, how does performance scale?"
```

### Common Complexities (Fastest → Slowest)

| Big-O | Name | Example | 1,000 items | 1,000,000 items |
|---|---|---|---|---|
| O(1) | Constant | Array access by index | 1 op | 1 op |
| O(log n) | Logarithmic | Binary search | ~10 ops | ~20 ops |
| O(n) | Linear | Loop through array | 1,000 ops | 1,000,000 ops |
| O(n log n) | Linearithmic | Merge sort, Quick sort | ~10,000 ops | ~20,000,000 ops |
| O(n²) | Quadratic | Nested loops | 1,000,000 ops | 1,000,000,000,000 ops |
| O(2ⁿ) | Exponential | Recursive Fibonacci | Forget it | Heat death of universe |
| O(n!) | Factorial | Permutations | Forget it | Not in this lifetime |

---

## Visualizing Growth Rates

```
Operations
    |
    |                                          O(n!)
    |                                    O(2ⁿ)
    |                              O(n²)
    |                      O(n log n)
    |                O(n)
    |        O(log n)
    |  O(1)
    |_______________________________________________
                    Input Size (n) →
```

---

## O(1) — Constant Time

The operation takes the **same time** regardless of input size.

```csharp
// O(1) — Array access by index
int GetFirst(int[] arr) => arr[0];

// O(1) — Dictionary lookup
string GetValue(Dictionary<string, string> dict, string key) => dict[key];

// O(1) — Stack push/pop
void PushItem(Stack<int> stack, int item) => stack.Push(item);

// O(1) — Check if number is even
bool IsEven(int n) => n % 2 == 0;
```

No matter if the array has 10 or 10 million elements, `arr[0]` takes the same time.

---

## O(log n) — Logarithmic Time

Each step **halves** the remaining work. Typically seen in **divide and conquer** algorithms.

```csharp
// O(log n) — Binary Search
int BinarySearch(int[] sorted, int target)
{
    int left = 0, right = sorted.Length - 1;
    
    while (left <= right)
    {
        int mid = left + (right - left) / 2;  // Avoid overflow
        
        if (sorted[mid] == target) return mid;
        else if (sorted[mid] < target) left = mid + 1;
        else right = mid - 1;
    }
    return -1; // Not found
}
```

For 1,000,000 elements, binary search needs at most **~20 comparisons** (log₂(1,000,000) ≈ 20).

---

## O(n) — Linear Time

Time grows **proportionally** with input size.

```csharp
// O(n) — Find maximum
int FindMax(int[] arr)
{
    int max = arr[0];
    for (int i = 1; i < arr.Length; i++)  // n-1 comparisons
    {
        if (arr[i] > max) max = arr[i];
    }
    return max;
}

// O(n) — Sum all elements
int Sum(int[] arr)
{
    int total = 0;
    foreach (int num in arr)  // n iterations
        total += num;
    return total;
}

// O(n) — Linear search
int LinearSearch(int[] arr, int target)
{
    for (int i = 0; i < arr.Length; i++)  // worst case: n iterations
    {
        if (arr[i] == target) return i;
    }
    return -1;
}
```

---

## O(n log n) — Linearithmic Time

Typical for **efficient sorting algorithms**. You divide (log n) and process each part (n).

```csharp
// O(n log n) — Merge Sort (we'll implement this in Topic 8)
// Divides array in half (log n levels), merges each level (n work per level)

// Built-in .Sort() uses a hybrid algorithm with O(n log n) average
int[] arr = { 5, 2, 8, 1, 9, 3 };
Array.Sort(arr); // O(n log n)

// LINQ OrderBy is also O(n log n)
var sorted = arr.OrderBy(x => x);
```

---

## O(n²) — Quadratic Time

Usually caused by **nested loops** over the same data.

```csharp
// O(n²) — Bubble Sort
void BubbleSort(int[] arr)
{
    for (int i = 0; i < arr.Length; i++)          // n iterations
    {
        for (int j = 0; j < arr.Length - i - 1; j++) // n iterations (roughly)
        {
            if (arr[j] > arr[j + 1])
            {
                (arr[j], arr[j + 1]) = (arr[j + 1], arr[j]);
            }
        }
    }
}

// O(n²) — Check for duplicates (brute force)
bool HasDuplicates(int[] arr)
{
    for (int i = 0; i < arr.Length; i++)
    {
        for (int j = i + 1; j < arr.Length; j++)
        {
            if (arr[i] == arr[j]) return true;
        }
    }
    return false;
}

// O(n) — Check for duplicates (optimized with HashSet)
bool HasDuplicatesOptimized(int[] arr)
{
    HashSet<int> seen = new HashSet<int>();
    foreach (int num in arr)
    {
        if (!seen.Add(num)) return true; // Add returns false if already exists
    }
    return false;
}
```

---

## O(2ⁿ) — Exponential Time

Each step **doubles** the work. Seen in naive recursive solutions.

```csharp
// O(2ⁿ) — Naive Recursive Fibonacci
int Fib(int n)
{
    if (n <= 1) return n;
    return Fib(n - 1) + Fib(n - 2); // Each call creates 2 more calls
}
// Fib(40) makes over 300 million calls!

// O(n) — Optimized with memoization (Dynamic Programming)
int FibDP(int n)
{
    if (n <= 1) return n;
    int prev2 = 0, prev1 = 1;
    for (int i = 2; i <= n; i++)
    {
        int current = prev1 + prev2;
        prev2 = prev1;
        prev1 = current;
    }
    return prev1;
}
// FibDP(40) does only 39 iterations
```

---

## Space Complexity

Space complexity measures how much **extra memory** your algorithm needs.

```csharp
// O(1) space — constant extra memory
int Sum(int[] arr)
{
    int total = 0;  // Only 1 extra variable
    foreach (int n in arr)
        total += n;
    return total;
}

// O(n) space — extra memory proportional to input
int[] Duplicate(int[] arr)
{
    int[] copy = new int[arr.Length]; // New array of same size
    Array.Copy(arr, copy, arr.Length);
    return copy;
}

// O(n) space — HashSet grows with input
bool HasDuplicates(int[] arr)
{
    HashSet<int> seen = new HashSet<int>(); // Could store up to n items
    foreach (int n in arr)
        if (!seen.Add(n)) return true;
    return false;
}

// O(n) space — Recursion uses stack space
int Factorial(int n)
{
    if (n <= 1) return 1;
    return n * Factorial(n - 1); // n stack frames
}
```

---

## How to Analyze Complexity

### Rules for Big-O

**Rule 1: Drop constants**
```
O(2n) → O(n)
O(100n) → O(n)
O(n/2) → O(n)
```

**Rule 2: Drop lower-order terms**
```
O(n² + n) → O(n²)
O(n + log n) → O(n)
O(n³ + n² + n) → O(n³)
```

**Rule 3: Different inputs → different variables**
```csharp
// This is O(a + b), NOT O(n)
void PrintBoth(int[] arrA, int[] arrB)
{
    foreach (int a in arrA) Console.WriteLine(a); // O(a)
    foreach (int b in arrB) Console.WriteLine(b); // O(b)
}

// This is O(a × b), NOT O(n²)
void PrintPairs(int[] arrA, int[] arrB)
{
    foreach (int a in arrA)
        foreach (int b in arrB)
            Console.WriteLine($"{a},{b}");
}
```

### Analysis Walkthrough

```csharp
void Mystery(int[] arr)
{
    int n = arr.Length;                    // O(1)
    
    for (int i = 0; i < n; i++)           // O(n)
        Console.WriteLine(arr[i]);
    
    for (int i = 0; i < n; i++)           // O(n²) — nested
        for (int j = 0; j < n; j++)
            Console.WriteLine(arr[i] + arr[j]);
    
    Console.WriteLine("Done");            // O(1)
}
// Total: O(1) + O(n) + O(n²) + O(1) = O(n²)  (drop lower terms)
```

---

## Best, Average, and Worst Case

```csharp
int LinearSearch(int[] arr, int target)
{
    for (int i = 0; i < arr.Length; i++)
        if (arr[i] == target) return i;
    return -1;
}

// Best case: O(1) — target is first element
// Average case: O(n/2) → O(n) — target is in the middle
// Worst case: O(n) — target is last or not found
```

**Big-O typically refers to the worst case** unless stated otherwise.

---

## Common Operations Complexity

| Operation | Array | List\<T\> | Dictionary | HashSet | Sorted Array |
|---|---|---|---|---|---|
| Access by index | O(1) | O(1) | N/A | N/A | O(1) |
| Search | O(n) | O(n) | O(1) | O(1) | O(log n) |
| Insert (end) | N/A | O(1)* | O(1)* | O(1)* | O(n) |
| Insert (middle) | N/A | O(n) | N/A | N/A | O(n) |
| Delete | O(n) | O(n) | O(1) | O(1) | O(n) |
| Sort | O(n log n) | O(n log n) | N/A | N/A | N/A |

*Amortized — occasional O(n) when internal array resizes

---

## Amortized Analysis (Brief)

`List<T>.Add()` is O(1) **amortized**:
- Most `Add` calls are O(1)
- When the internal array is full, it doubles in size → O(n) for that one operation
- Over n insertions, total work is ~2n → average per operation is O(1)

---

## Key Takeaways

| Concept | Summary |
|---|---|
| Big-O | Upper bound of growth rate as input scales |
| O(1) | Constant — doesn't grow with input |
| O(log n) | Logarithmic — halving each step (binary search) |
| O(n) | Linear — one pass through data |
| O(n log n) | Linearithmic — efficient sorting |
| O(n²) | Quadratic — nested loops (usually avoidable) |
| O(2ⁿ) | Exponential — brute force recursion |
| Space complexity | Extra memory used by the algorithm |
| Drop constants | O(2n) = O(n) |
| Drop lower terms | O(n² + n) = O(n²) |
| Different inputs | Use different variables: O(a × b) |

---

*Next Topic: Arrays & Strings (DSA) →*
