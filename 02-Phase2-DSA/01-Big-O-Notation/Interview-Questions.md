# Topic 01: Big O Notation — Interview Questions

---

## Q1. What is Big O notation and why is it important?
**Answer:**
Big O notation describes the **upper bound** on the growth rate of an algorithm's time or space requirements as the input size `n` approaches infinity. It abstracts away hardware and implementation details to compare algorithms by their scalability.

```
O(1) < O(log n) < O(n) < O(n log n) < O(n²) < O(2ⁿ) < O(n!)
```

It is important because:
- It predicts performance at scale before writing code.
- It guides data structure and algorithm selection.
- It is the universal language for algorithm analysis in interviews.

---

## Q2. What is the difference between Big O (O), Big Theta (Θ), and Big Omega (Ω)?
**Answer:**
| Notation | Meaning | Describes |
|---|---|---|
| **O(f(n))** | Upper bound | Worst case — algorithm runs *at most* this fast |
| **Θ(f(n))** | Tight bound | Exact growth — algorithm runs *exactly* this fast (both upper and lower) |
| **Ω(f(n))** | Lower bound | Best case — algorithm runs *at least* this fast |

```
Example: Binary Search
- Ω(1)      — best case: element found at midpoint immediately
- Θ(log n)  — average case: halving repeatedly
- O(log n)  — worst case: element not found
```

In interviews, "Big O" is commonly used informally to mean "worst-case complexity". Technically, Θ is the most precise.

---

## Q3. What are the most common time complexities and an example of each?
**Answer:**
| Complexity | Name | Example |
|---|---|---|
| O(1) | Constant | Array index access, hash map lookup |
| O(log n) | Logarithmic | Binary search, balanced BST operations |
| O(n) | Linear | Linear search, single loop over array |
| O(n log n) | Linearithmic | Merge sort, heap sort, efficient sorting |
| O(n²) | Quadratic | Bubble/selection/insertion sort, nested loops |
| O(n³) | Cubic | Matrix multiplication (naive), triple nested loops |
| O(2ⁿ) | Exponential | Recursive Fibonacci, subsets enumeration |
| O(n!) | Factorial | Permutation generation, brute-force TSP |

---

## Q4. How do you analyze the time complexity of nested loops?
**Answer:**
For **independent nested loops**, multiply the loop counts. For **dependent** loops, analyze carefully:

```csharp
// O(n²) — classic double loop
for (int i = 0; i < n; i++)
    for (int j = 0; j < n; j++)
        DoWork(); // n * n = n²

// O(n²) — triangle pattern (still O(n²))
for (int i = 0; i < n; i++)
    for (int j = i; j < n; j++)  // n + (n-1) + ... + 1 = n(n+1)/2 → O(n²)
        DoWork();

// O(n * m) — two different sizes
for (int i = 0; i < n; i++)
    for (int j = 0; j < m; j++)
        DoWork(); // n * m

// O(n log n) — loop + binary search inside
for (int i = 0; i < n; i++)          // O(n)
    BinarySearch(arr, target);        // O(log n) each
```

---

## Q5. What does "drop constants and non-dominant terms" mean?
**Answer:**
Big O ignores constant factors and keeps only the fastest-growing term because as `n → ∞`, smaller terms become negligible:

```
O(2n)        → O(n)       — drop constant multiplier
O(n + 500)   → O(n)       — drop constant additive term
O(n² + n)    → O(n²)      — drop lower-order term
O(n log n + n) → O(n log n) — drop n (slower growth)
O(3n² + 5n + 100) → O(n²) — keep dominant term only
```

---

## Q6. What is the difference between time complexity and space complexity?
**Answer:**
- **Time complexity** — how the **runtime** grows with input size (CPU cost).
- **Space complexity** — how the **memory usage** grows with input size.

```csharp
// O(n) time, O(1) space — in-place reverse
void Reverse(int[] arr) {
    int l = 0, r = arr.Length - 1;
    while (l < r) { (arr[l], arr[r]) = (arr[r], arr[l]); l++; r--; }
}

// O(n) time, O(n) space — creates new array
int[] ReverseNew(int[] arr) => arr.Reverse().ToArray();
```

Space complexity counts **extra** memory used by the algorithm, not the input itself (this is called **auxiliary space**).

---

## Q7. What is auxiliary space and how does it differ from total space complexity?
**Answer:**
- **Auxiliary space** — extra memory the algorithm uses beyond the input.
- **Total space complexity** — auxiliary space + space for the input.

```csharp
// Merge Sort — O(n) auxiliary space (temporary arrays for merging)
// Input: n elements, Auxiliary: n more elements for merging

// In-place Bubble Sort — O(1) auxiliary space
// Input: n elements, Auxiliary: just a few variables
```

Interview questions about space complexity usually ask for **auxiliary space**.

---

## Q8. What is amortized time complexity?
**Answer:**
Amortized analysis averages the cost of an operation over a **sequence** of operations, even if some individual operations are expensive:

```
List<T>.Add() — amortized O(1):
- Most adds: O(1) — just write to existing slot
- Occasional add: O(n) — list doubles capacity, copies all elements
- Over n adds: total work = n + n/2 + n/4 + ... ≈ 2n → amortized O(1) per add
```

Other amortized O(1) examples:
- `Stack.Push()` / `Queue.Enqueue()`
- Dynamic hash table insert (before rehash)

---

## Q9. What is the time and space complexity of recursion?
**Answer:**
Each recursive call adds a **stack frame**. The space complexity of recursion is at minimum O(depth of recursion tree):

```csharp
// Factorial — O(n) time, O(n) space (n stack frames)
int Factorial(int n) => n <= 1 ? 1 : n * Factorial(n - 1);

// Fibonacci (naive) — O(2ⁿ) time, O(n) space (tree height = n)
int Fib(int n) => n <= 1 ? n : Fib(n-1) + Fib(n-2);

// Binary search (recursive) — O(log n) time, O(log n) space
int BinarySearch(int[] arr, int lo, int hi, int target) { ... }
```

**Tail recursion** — a recursive call that is the last operation can theoretically be optimized to O(1) space. C# does NOT optimize tail calls (unlike F#).

---

## Q10. How do you calculate the Big O of a recursive algorithm?
**Answer:**
Use the **Master Theorem** for divide-and-conquer recurrences of the form `T(n) = aT(n/b) + O(nᵈ)`:

| Condition | Result |
|---|---|
| d > log_b(a) | O(nᵈ) |
| d = log_b(a) | O(nᵈ log n) |
| d < log_b(a) | O(n^log_b(a)) |

```
Merge Sort: T(n) = 2T(n/2) + O(n)
  a=2, b=2, d=1 → log_2(2) = 1 = d → O(n log n) ✓

Binary Search: T(n) = T(n/2) + O(1)
  a=1, b=2, d=0 → log_2(1) = 0 = d → O(log n) ✓

Fibonacci (naive): T(n) = 2T(n-1) + O(1) → O(2ⁿ) ✓
```

---

## Q11. What is the Big O of common data structure operations?
**Answer:**
| Structure | Access | Search | Insert | Delete |
|---|---|---|---|---|
| Array | O(1) | O(n) | O(n) | O(n) |
| Linked List | O(n) | O(n) | O(1)* | O(1)* |
| Stack/Queue | O(n) | O(n) | O(1) | O(1) |
| Hash Table | — | O(1) avg | O(1) avg | O(1) avg |
| BST (balanced) | O(log n) | O(log n) | O(log n) | O(log n) |
| BST (unbalanced) | O(n) | O(n) | O(n) | O(n) |
| Heap | — | O(n) | O(log n) | O(log n) |

*Linked List insert/delete is O(1) if you already have the node reference; O(n) to find the position first.

---

## Q12. What is the best, worst, and average case complexity?
**Answer:**
- **Best case (Ω)** — most favorable input; algorithm does minimum work.
- **Worst case (O)** — most unfavorable input; algorithm does maximum work.
- **Average case (Θ)** — expected complexity over all possible inputs.

```
Quick Sort:
- Best case:  O(n log n) — pivot always splits array in half
- Average:    O(n log n) — random pivot distribution
- Worst case: O(n²)      — pivot is always min or max (sorted array with first-element pivot)

Linear Search:
- Best:    O(1) — target is first element
- Average: O(n/2) → O(n)
- Worst:   O(n) — target is last or absent
```

---

## Q13. How does Big O apply to space complexity in common algorithms?
**Answer:**
```
Algorithm          Time       Space (Auxiliary)
---------------------------------------------------
Bubble Sort        O(n²)      O(1)       — in-place
Merge Sort         O(n log n) O(n)       — temp arrays
Quick Sort         O(n log n) O(log n)   — recursion stack
Hash Map ops       O(1) avg   O(n)       — stores n entries
Recursive DFS      O(V+E)     O(V)       — recursion depth = V
BFS                O(V+E)     O(V)       — queue holds V nodes
```

---

## Q14. Why is O(log n) so efficient and where does it come from?
**Answer:**
O(log n) means the problem is **halved** at each step. Starting from n, it takes log₂(n) halvings to reach 1:

```
n=1,000,000  → log₂(1,000,000) ≈ 20 steps
n=1,000,000,000 → ≈ 30 steps
```

Sources of O(log n):
- **Binary search** — halve the search space each step.
- **Balanced BST** — height is log(n).
- **Heap operations** — tree height is log(n).
- **Divide and conquer** — each level halves the problem.

Doubling the input adds only **one extra step** in O(log n) algorithms — extremely scalable.

---

## Q15. What is the difference between O(n) and O(n²) in practice?
**Answer:**
```
n = 1,000:
  O(n)   = 1,000 operations         → ~microseconds
  O(n²)  = 1,000,000 operations     → ~milliseconds

n = 1,000,000:
  O(n)   = 1,000,000 operations     → ~milliseconds
  O(n²)  = 10¹² operations          → ~days

n = 100,000,000:
  O(n log n) ≈ 2.7 × 10⁹            → ~seconds
  O(n²)      = 10¹⁶                  → thousands of years
```

This is why choosing the right algorithm matters far more than micro-optimizations like loop unrolling or avoiding null checks.
