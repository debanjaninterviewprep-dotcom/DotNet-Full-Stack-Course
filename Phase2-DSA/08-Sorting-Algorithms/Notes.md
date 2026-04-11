# Topic 8: Sorting Algorithms

## Why Study Sorting?

Sorting is the most fundamental algorithmic problem. Understanding sorting teaches you:
- **Divide and conquer** (merge sort, quick sort)
- **Time-space tradeoffs** (counting sort vs comparison sorts)
- **Stability** (preserving relative order of equal elements)
- **In-place algorithms** (O(1) extra space)

---

## Sorting Algorithm Overview

| Algorithm | Best | Average | Worst | Space | Stable | In-Place |
|---|---|---|---|---|---|---|
| Bubble Sort | O(n) | O(n²) | O(n²) | O(1) | Yes | Yes |
| Selection Sort | O(n²) | O(n²) | O(n²) | O(1) | No | Yes |
| Insertion Sort | O(n) | O(n²) | O(n²) | O(1) | Yes | Yes |
| Merge Sort | O(n log n) | O(n log n) | O(n log n) | O(n) | Yes | No |
| Quick Sort | O(n log n) | O(n log n) | O(n²) | O(log n) | No | Yes |
| Heap Sort | O(n log n) | O(n log n) | O(n log n) | O(1) | No | Yes |
| Counting Sort | O(n+k) | O(n+k) | O(n+k) | O(k) | Yes | No |
| Radix Sort | O(d×(n+k)) | O(d×(n+k)) | O(d×(n+k)) | O(n+k) | Yes | No |

**Stable** = equal elements maintain their relative order.

---

## Bubble Sort

Repeatedly **swap adjacent** elements if they're in wrong order. Like bubbles rising to the surface.

```
Pass 1: [5, 3, 8, 4, 2]
  5>3? swap → [3, 5, 8, 4, 2]
  5>8? no   → [3, 5, 8, 4, 2]
  8>4? swap → [3, 5, 4, 8, 2]
  8>2? swap → [3, 5, 4, 2, 8] ← 8 is in place!

Pass 2: [3, 5, 4, 2, 8]
  → [3, 4, 2, 5, 8] ← 5 in place

Pass 3: [3, 4, 2, 5, 8]
  → [3, 2, 4, 5, 8] ← 4 in place

Pass 4: [3, 2, 4, 5, 8]
  → [2, 3, 4, 5, 8] ✓ Sorted!
```

```csharp
void BubbleSort(int[] arr)
{
    int n = arr.Length;
    for (int i = 0; i < n - 1; i++)
    {
        bool swapped = false;
        for (int j = 0; j < n - 1 - i; j++) // -i because last i elements are sorted
        {
            if (arr[j] > arr[j + 1])
            {
                (arr[j], arr[j + 1]) = (arr[j + 1], arr[j]);
                swapped = true;
            }
        }
        if (!swapped) break; // Already sorted — O(n) best case
    }
}
```

---

## Selection Sort

Find the **minimum** element and swap it to the front. Repeat for remaining.

```
[64, 25, 12, 22, 11]
Min=11 → swap with 64 → [11, 25, 12, 22, 64]
Min=12 → swap with 25 → [11, 12, 25, 22, 64]
Min=22 → swap with 25 → [11, 12, 22, 25, 64]
Min=25 → already there → [11, 12, 22, 25, 64] ✓
```

```csharp
void SelectionSort(int[] arr)
{
    int n = arr.Length;
    for (int i = 0; i < n - 1; i++)
    {
        int minIdx = i;
        for (int j = i + 1; j < n; j++)
        {
            if (arr[j] < arr[minIdx])
                minIdx = j;
        }
        if (minIdx != i)
            (arr[i], arr[minIdx]) = (arr[minIdx], arr[i]);
    }
}
// Always O(n²) — no best case improvement
// Minimum number of swaps: O(n)
```

---

## Insertion Sort

Build sorted array one element at a time — like sorting playing cards in your hand.

```
[5, 3, 8, 4, 2]
Insert 3: [3, 5, 8, 4, 2]    (3 < 5, shift 5 right, insert 3)
Insert 8: [3, 5, 8, 4, 2]    (8 > 5, already in place)
Insert 4: [3, 4, 5, 8, 2]    (4 < 8, 4 < 5, shift both, insert 4)
Insert 2: [2, 3, 4, 5, 8]    (shift everything, insert 2) ✓
```

```csharp
void InsertionSort(int[] arr)
{
    for (int i = 1; i < arr.Length; i++)
    {
        int key = arr[i];
        int j = i - 1;
        
        // Shift elements greater than key to the right
        while (j >= 0 && arr[j] > key)
        {
            arr[j + 1] = arr[j];
            j--;
        }
        arr[j + 1] = key;
    }
}
// Best case: O(n) when already sorted (inner loop never executes)
// Best for: small arrays, nearly sorted arrays
```

---

## Merge Sort

**Divide and conquer** — split array in half, sort each half, merge them back.

```
[38, 27, 43, 3, 9, 82, 10]

Split:  [38, 27, 43, 3] | [9, 82, 10]
Split:  [38, 27] [43, 3] | [9, 82] [10]
Split:  [38][27] [43][3] | [9][82] [10]

Merge:  [27, 38] [3, 43] | [9, 82] [10]
Merge:  [3, 27, 38, 43]  | [9, 10, 82]
Merge:  [3, 9, 10, 27, 38, 43, 82] ✓
```

```csharp
void MergeSort(int[] arr, int left, int right)
{
    if (left >= right) return;
    
    int mid = left + (right - left) / 2;
    MergeSort(arr, left, mid);        // Sort left half
    MergeSort(arr, mid + 1, right);   // Sort right half
    Merge(arr, left, mid, right);     // Merge sorted halves
}

void Merge(int[] arr, int left, int mid, int right)
{
    // Create temp arrays
    int[] leftArr = arr[left..(mid + 1)];
    int[] rightArr = arr[(mid + 1)..(right + 1)];
    
    int i = 0, j = 0, k = left;
    
    while (i < leftArr.Length && j < rightArr.Length)
    {
        if (leftArr[i] <= rightArr[j]) // <= for stability
            arr[k++] = leftArr[i++];
        else
            arr[k++] = rightArr[j++];
    }
    
    while (i < leftArr.Length) arr[k++] = leftArr[i++];
    while (j < rightArr.Length) arr[k++] = rightArr[j++];
}

// Usage:
int[] arr = { 38, 27, 43, 3, 9, 82, 10 };
MergeSort(arr, 0, arr.Length - 1);
// Always O(n log n) — guaranteed performance
// Requires O(n) extra space
```

---

## Quick Sort

**Divide and conquer** — pick a **pivot**, partition array into elements < pivot and > pivot.

```
[10, 7, 8, 9, 1, 5]  pivot = 5

Partition: [1, 5, 8, 9, 10, 7]  (1 < 5 goes left, rest goes right)
After:     [1] [5] [8, 9, 10, 7]  (5 is in correct position!)

Recurse on [8, 9, 10, 7], pivot = 7
After:     [1, 5] [7] [8, 9, 10]

Continue until sorted: [1, 5, 7, 8, 9, 10] ✓
```

```csharp
void QuickSort(int[] arr, int low, int high)
{
    if (low >= high) return;
    
    int pivotIndex = Partition(arr, low, high);
    QuickSort(arr, low, pivotIndex - 1);  // Sort left of pivot
    QuickSort(arr, pivotIndex + 1, high); // Sort right of pivot
}

int Partition(int[] arr, int low, int high)
{
    int pivot = arr[high]; // Choose last element as pivot
    int i = low - 1;       // Index of smaller element boundary
    
    for (int j = low; j < high; j++)
    {
        if (arr[j] < pivot)
        {
            i++;
            (arr[i], arr[j]) = (arr[j], arr[i]);
        }
    }
    
    (arr[i + 1], arr[high]) = (arr[high], arr[i + 1]); // Place pivot
    return i + 1;
}

// Usage:
int[] arr = { 10, 7, 8, 9, 1, 5 };
QuickSort(arr, 0, arr.Length - 1);
// Average: O(n log n), Worst: O(n²) when already sorted
// In practice: fastest general-purpose sort
```

### Improving Quick Sort

```csharp
// Random pivot to avoid worst case
int RandomPartition(int[] arr, int low, int high)
{
    int randomIndex = new Random().Next(low, high + 1);
    (arr[randomIndex], arr[high]) = (arr[high], arr[randomIndex]);
    return Partition(arr, low, high);
}

// Median of three pivot
int MedianOfThree(int[] arr, int low, int high)
{
    int mid = low + (high - low) / 2;
    if (arr[low] > arr[mid]) (arr[low], arr[mid]) = (arr[mid], arr[low]);
    if (arr[low] > arr[high]) (arr[low], arr[high]) = (arr[high], arr[low]);
    if (arr[mid] > arr[high]) (arr[mid], arr[high]) = (arr[high], arr[mid]);
    (arr[mid], arr[high - 1]) = (arr[high - 1], arr[mid]);
    return arr[high - 1]; // Median is the pivot
}
```

---

## Heap Sort

Uses a **max-heap** to repeatedly extract the maximum element.

```csharp
void HeapSort(int[] arr)
{
    int n = arr.Length;
    
    // Build max-heap — O(n)
    for (int i = n / 2 - 1; i >= 0; i--)
        Heapify(arr, n, i);
    
    // Extract elements one by one — O(n log n)
    for (int i = n - 1; i > 0; i--)
    {
        (arr[0], arr[i]) = (arr[i], arr[0]); // Move max to end
        Heapify(arr, i, 0);                   // Fix heap
    }
}

void Heapify(int[] arr, int n, int i)
{
    int largest = i;
    int left = 2 * i + 1;
    int right = 2 * i + 2;
    
    if (left < n && arr[left] > arr[largest]) largest = left;
    if (right < n && arr[right] > arr[largest]) largest = right;
    
    if (largest != i)
    {
        (arr[i], arr[largest]) = (arr[largest], arr[i]);
        Heapify(arr, n, largest);
    }
}
// Always O(n log n), O(1) space, but not stable
```

---

## Counting Sort (Non-Comparison)

Counts occurrences of each value. Only works for **non-negative integers** within a known range.

```
Input:  [4, 2, 2, 8, 3, 3, 1]  Range: 0-8

Count:  [0, 1, 2, 2, 1, 0, 0, 0, 1]
         0  1  2  3  4  5  6  7  8

Output: [1, 2, 2, 3, 3, 4, 8]
```

```csharp
int[] CountingSort(int[] arr)
{
    if (arr.Length == 0) return arr;
    
    int max = arr.Max();
    int[] count = new int[max + 1];
    
    // Count occurrences
    foreach (int num in arr)
        count[num]++;
    
    // Build output
    int idx = 0;
    for (int i = 0; i <= max; i++)
        while (count[i]-- > 0)
            arr[idx++] = i;
    
    return arr;
}
// Time: O(n + k) where k = max value
// Space: O(k)
// NOT comparison-based → beats O(n log n) lower bound!
```

---

## Radix Sort

Sort by individual digits, from least significant to most. Uses counting sort as a subroutine.

```
Input: [170, 45, 75, 90, 802, 24, 2, 66]

Sort by ones:   [170, 90, 802, 2, 24, 45, 75, 66]
Sort by tens:   [802, 2, 24, 45, 66, 170, 75, 90]
Sort by hundreds:[2, 24, 45, 66, 75, 90, 170, 802] ✓
```

```csharp
void RadixSort(int[] arr)
{
    int max = arr.Max();
    
    for (int exp = 1; max / exp > 0; exp *= 10)
        CountingSortByDigit(arr, exp);
}

void CountingSortByDigit(int[] arr, int exp)
{
    int n = arr.Length;
    int[] output = new int[n];
    int[] count = new int[10]; // Digits 0-9
    
    foreach (int num in arr)
        count[(num / exp) % 10]++;
    
    for (int i = 1; i < 10; i++)
        count[i] += count[i - 1];
    
    for (int i = n - 1; i >= 0; i--)
    {
        int digit = (arr[i] / exp) % 10;
        output[count[digit] - 1] = arr[i];
        count[digit]--;
    }
    
    Array.Copy(output, arr, n);
}
// Time: O(d × (n + k)) where d = digits, k = base (10)
```

---

## C# Built-in Sorting

```csharp
// Array.Sort — uses IntroSort (QuickSort + HeapSort + InsertionSort)
int[] arr = { 5, 2, 8, 1, 9 };
Array.Sort(arr); // [1, 2, 5, 8, 9]

// Custom comparison
Array.Sort(arr, (a, b) => b.CompareTo(a)); // Descending

// List<T>.Sort
List<int> list = new List<int> { 5, 2, 8, 1, 9 };
list.Sort();

// LINQ OrderBy (creates new sequence, stable)
var sorted = arr.OrderBy(x => x).ToArray();
var desc = arr.OrderByDescending(x => x).ToArray();

// Sort custom objects
Person[] people = { new("Alice", 30), new("Bob", 25), new("Charlie", 30) };
Array.Sort(people, (a, b) => a.Age.CompareTo(b.Age));
// Or implement IComparable<T>
```

---

## When to Use Which Sort?

| Scenario | Best Choice | Why |
|---|---|---|
| Small array (< 50) | Insertion Sort | Low overhead, fast for small inputs |
| Nearly sorted | Insertion Sort | O(n) best case |
| General purpose | Quick Sort | Fastest average case |
| Guaranteed O(n log n) | Merge Sort | No worst-case degradation |
| Limited memory | Heap Sort | O(1) extra space |
| Integers in small range | Counting Sort | O(n+k) — linear! |
| Stable sort needed | Merge Sort | Preserves relative order |
| Linked list | Merge Sort | No random access needed |

---

## Key Takeaways

| Concept | Summary |
|---|---|
| O(n²) sorts | Bubble, Selection, Insertion — simple but slow |
| O(n log n) sorts | Merge, Quick, Heap — efficient for large data |
| Merge Sort | Stable, always O(n log n), needs O(n) space |
| Quick Sort | Fastest on average, O(n²) worst case |
| Counting Sort | O(n+k) for integers — beats comparison sorts |
| Stability | Equal elements keep original order |
| In-place | O(1) extra space (Quick, Heap, Selection) |
| C# default | IntroSort (hybrid of Quick+Heap+Insertion) |

---

*Next Topic: Searching Algorithms →*
