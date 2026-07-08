# Topic 08: Sorting Algorithms — Interview Questions

---

## Q1. What are the key properties to compare sorting algorithms?
**Answer:**
| Property | Description |
|---|---|
| **Time complexity** | Best, average, worst case |
| **Space complexity** | In-place (O(1)) vs extra memory |
| **Stable** | Equal elements maintain original relative order |
| **Adaptive** | Faster on partially sorted input |
| **Comparison-based** | Compares elements vs counts/indexes |

A **stable sort** is important when sorting by secondary keys or when equal elements have meaningful ordering (e.g., sort by name, then by age — maintain name order within same age).

---

## Q2. What is Bubble Sort and what is its complexity?
**Answer:**
Repeatedly swaps adjacent elements that are out of order — bubbles the largest to the end:

```csharp
void BubbleSort(int[] arr)
{
    int n = arr.Length;
    for (int i = 0; i < n - 1; i++)
    {
        bool swapped = false;
        for (int j = 0; j < n - i - 1; j++)
            if (arr[j] > arr[j + 1])
            {
                (arr[j], arr[j + 1]) = (arr[j + 1], arr[j]);
                swapped = true;
            }
        if (!swapped) break; // optimization: already sorted
    }
}
```

| | Complexity |
|---|---|
| Best | O(n) — already sorted (with swapped flag) |
| Average | O(n²) |
| Worst | O(n²) |
| Space | O(1) — in-place |
| Stable | ✓ Yes |

---

## Q3. What is Selection Sort?
**Answer:**
Finds the minimum element and swaps it to its correct position:

```csharp
void SelectionSort(int[] arr)
{
    for (int i = 0; i < arr.Length - 1; i++)
    {
        int minIdx = i;
        for (int j = i + 1; j < arr.Length; j++)
            if (arr[j] < arr[minIdx]) minIdx = j;
        (arr[i], arr[minIdx]) = (arr[minIdx], arr[i]);
    }
}
```

| | Complexity |
|---|---|
| Best/Average/Worst | O(n²) — always |
| Space | O(1) |
| Stable | ✗ No (can swap non-adjacent equal elements) |

Selection sort makes the minimum number of swaps (O(n)) — useful when write cost is high.

---

## Q4. What is Insertion Sort?
**Answer:**
Builds a sorted subarray by inserting each element into its correct position — like sorting playing cards:

```csharp
void InsertionSort(int[] arr)
{
    for (int i = 1; i < arr.Length; i++)
    {
        int key = arr[i], j = i - 1;
        while (j >= 0 && arr[j] > key) { arr[j + 1] = arr[j]; j--; }
        arr[j + 1] = key;
    }
}
```

| | Complexity |
|---|---|
| Best | O(n) — already sorted |
| Average/Worst | O(n²) |
| Space | O(1) |
| Stable | ✓ Yes |
| Adaptive | ✓ Yes |

**Best use case:** small arrays, nearly sorted data, online sorting (elements arrive one by one). Used internally by many sort implementations for small subarrays.

---

## Q5. What is Merge Sort and how does it work?
**Answer:**
Divide and conquer: split array in half, recursively sort each half, merge:

```csharp
void MergeSort(int[] arr, int lo, int hi)
{
    if (lo >= hi) return;
    int mid = lo + (hi - lo) / 2;
    MergeSort(arr, lo, mid);
    MergeSort(arr, mid + 1, hi);
    Merge(arr, lo, mid, hi);
}

void Merge(int[] arr, int lo, int mid, int hi)
{
    int[] temp = arr[lo..(hi + 1)];
    int left = 0, right = mid - lo + 1, k = lo;
    while (left <= mid - lo && right < temp.Length)
        arr[k++] = temp[left] <= temp[right] ? temp[left++] : temp[right++];
    while (left <= mid - lo)  arr[k++] = temp[left++];
    while (right < temp.Length) arr[k++] = temp[right++];
}
```

| | Complexity |
|---|---|
| All cases | O(n log n) |
| Space | O(n) — temporary arrays |
| Stable | ✓ Yes |

**Best use:** large data, linked lists, external sorting (data doesn't fit in RAM).

---

## Q6. What is Quick Sort and how does it work?
**Answer:**
Partition array around a pivot; recursively sort partitions:

```csharp
void QuickSort(int[] arr, int lo, int hi)
{
    if (lo >= hi) return;
    int pivot = Partition(arr, lo, hi);
    QuickSort(arr, lo, pivot - 1);
    QuickSort(arr, pivot + 1, hi);
}

int Partition(int[] arr, int lo, int hi)
{
    int pivot = arr[hi]; // last element as pivot
    int i = lo - 1;
    for (int j = lo; j < hi; j++)
        if (arr[j] <= pivot) (arr[++i], arr[j]) = (arr[j], arr[i]);
    (arr[i + 1], arr[hi]) = (arr[hi], arr[i + 1]);
    return i + 1;
}
```

| | Complexity |
|---|---|
| Best/Average | O(n log n) |
| Worst | O(n²) — sorted array with bad pivot |
| Space | O(log n) recursion stack |
| Stable | ✗ No |

**Optimizations:** random pivot, median-of-three pivot, 3-way partition for duplicates.

---

## Q7. What is Heap Sort?
**Answer:**
Build a max-heap, then repeatedly extract the maximum:

```csharp
void HeapSort(int[] arr)
{
    int n = arr.Length;
    for (int i = n / 2 - 1; i >= 0; i--) Heapify(arr, n, i); // build max-heap
    for (int i = n - 1; i > 0; i--)
    {
        (arr[0], arr[i]) = (arr[i], arr[0]); // move max to end
        Heapify(arr, i, 0);                   // re-heapify reduced heap
    }
}

void Heapify(int[] arr, int n, int i)
{
    int largest = i, l = 2*i+1, r = 2*i+2;
    if (l < n && arr[l] > arr[largest]) largest = l;
    if (r < n && arr[r] > arr[largest]) largest = r;
    if (largest != i) { (arr[i], arr[largest]) = (arr[largest], arr[i]); Heapify(arr, n, largest); }
}
```

| | Complexity |
|---|---|
| All cases | O(n log n) |
| Space | O(1) — in-place |
| Stable | ✗ No |

---

## Q8. What is Counting Sort and when can it be used?
**Answer:**
Non-comparison sort for integers in a known range [0, k]:

```csharp
void CountingSort(int[] arr, int k)
{
    int[] count = new int[k + 1];
    foreach (int n in arr) count[n]++;

    int idx = 0;
    for (int i = 0; i <= k; i++)
        while (count[i]-- > 0) arr[idx++] = i;
}
// Time: O(n + k), Space: O(k)
```

**When to use:** integers with a small, known range (ages 0-120, scores 0-100). Faster than comparison sorts when k = O(n).

---

## Q9. What is Radix Sort?
**Answer:**
Sorts integers digit by digit (least to most significant), using Counting Sort as a subroutine:

```csharp
void RadixSort(int[] arr)
{
    int max = arr.Max();
    for (int exp = 1; max / exp > 0; exp *= 10)
        CountSortByDigit(arr, exp);
}

void CountSortByDigit(int[] arr, int exp)
{
    int n = arr.Length;
    int[] output = new int[n], count = new int[10];
    foreach (int a in arr) count[(a / exp) % 10]++;
    for (int i = 1; i < 10; i++) count[i] += count[i - 1];
    for (int i = n - 1; i >= 0; i--)
    {
        int digit = (arr[i] / exp) % 10;
        output[--count[digit]] = arr[i];
    }
    Array.Copy(output, arr, n);
}
// Time: O(d * (n + k)) where d=digits, k=base(10)
// For integers: O(n * log(max)) ≈ O(n) for fixed-size integers
```

---

## Q10. What sorting algorithm does C# use internally?
**Answer:**
`Array.Sort()` and `List<T>.Sort()` use **Introsort**:
- Starts as **Quick Sort** (fast average case).
- Switches to **Heap Sort** when recursion depth exceeds 2 × log₂(n) (prevents O(n²) worst case).
- Switches to **Insertion Sort** for small subarrays (≤ 16 elements) where overhead of recursion isn't worth it.

LINQ's `OrderBy()` uses a **stable merge sort** to preserve the relative order of equal elements.

```csharp
Array.Sort(arr);                       // Introsort — O(n log n) guaranteed
arr.OrderBy(x => x).ToArray();         // Stable merge sort
arr.OrderBy(x => x.Key).ThenBy(x => x.Name); // multi-key stable sort
```

---

## Q11. What is the difference between stable and unstable sort?
**Answer:**
```
// Input: [(Alice, 30), (Bob, 25), (Charlie, 30), (Dave, 25)]
// Sort by Age:

// Stable sort result: [(Bob, 25), (Dave, 25), (Alice, 30), (Charlie, 30)]
// (Bob before Dave — preserved original order for equal ages)

// Unstable sort result: [(Dave, 25), (Bob, 25), (Charlie, 30), (Alice, 30)]
// (relative order of equal elements NOT preserved)
```

Stable sorts: Merge Sort, Insertion Sort, Bubble Sort, Tim Sort, LINQ's `OrderBy`.
Unstable sorts: Quick Sort, Heap Sort, Selection Sort.

---

## Q12. When would you use each sorting algorithm in practice?
**Answer:**
| Scenario | Recommended Algorithm |
|---|---|
| General purpose | Quick Sort / Introsort |
| Stability required | Merge Sort / Tim Sort |
| Memory constrained | Heap Sort (O(1) space) |
| Nearly sorted data | Insertion Sort / Tim Sort |
| Small arrays (< 20) | Insertion Sort |
| Large datasets (disk) | External Merge Sort |
| Integer range known | Counting Sort / Radix Sort |
| Linked lists | Merge Sort |

---

## Q13. What is Tim Sort?
**Answer:**
**Tim Sort** is a hybrid of Merge Sort and Insertion Sort, used in Python and Java's built-in sort:
- Divides array into natural **runs** (already sorted subarrays).
- Sorts short runs with **Insertion Sort** (fast for small, nearly sorted data).
- Merges runs with **Merge Sort**.
- O(n log n) worst case, O(n) best case (already sorted), stable.

.NET uses Introsort (not Tim Sort) for `Array.Sort`. The difference in performance for real-world data is usually negligible.

---

## Q14. What is the lower bound for comparison-based sorting?
**Answer:**
**Ω(n log n)** — no comparison-based sorting algorithm can do better than O(n log n) in the worst case.

**Proof intuition (decision tree):**
- n! possible orderings of n elements.
- Each comparison gives 1 bit of information (greater/less).
- Decision tree must have at least n! leaves.
- Height of a binary tree with n! leaves ≥ log₂(n!) ≈ n log n (Stirling's approximation).

This is why Counting Sort and Radix Sort can beat O(n log n) — they are **not comparison-based**.

---

## Q15. What is the 0/1 knapsack problem and how does sorting help?
**Answer:**
Sorting helps solve the **fractional knapsack** greedily but NOT the 0/1 knapsack:

```csharp
// Fractional knapsack — sort by value/weight ratio, take greedily
double FractionalKnapsack(int[] values, int[] weights, int capacity)
{
    var items = values.Zip(weights, (v, w) => (v, w, ratio: (double)v / w))
                      .OrderByDescending(x => x.ratio).ToArray();
    double total = 0;
    foreach (var (v, w, _) in items)
    {
        if (capacity >= w) { total += v; capacity -= w; }
        else { total += (double)capacity / w * v; break; }
    }
    return total;
}

// 0/1 knapsack — cannot be solved greedily, requires Dynamic Programming
// Sort can be used as a preprocessing step but doesn't yield the optimal solution directly
```
