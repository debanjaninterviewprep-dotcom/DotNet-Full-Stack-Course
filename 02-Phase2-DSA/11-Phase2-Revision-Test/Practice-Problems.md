# Topic 11: Phase 2 Revision Test — Practice Problems

## Pre-Test Preparation Checklist

Before taking the revision test in `Notes.md`, make sure you can confidently solve these warm-up problems. These cover the core concepts from each topic.

---

## Warm-Up 1: Complexity Analysis
Determine the time and space complexity of:
```csharp
// a) Nested loop with dependent inner bound
for (int i = 0; i < n; i++)
    for (int j = 0; j < i; j++)
        sum++;

// b) Recursive halving
void F(int n) { if (n > 1) { F(n/2); F(n/2); } }

// c) Linear scan with hash lookup
foreach (var x in arr) if (set.Contains(x)) count++;
```

---

## Warm-Up 2: Arrays & Strings Quick-Fire
Solve in under 5 minutes each:

1. Find the maximum subarray sum (Kadane's)
2. Check if two strings are anagrams
3. Reverse words in a sentence
4. Find the first non-repeating character
5. Rotate an array by k positions

---

## Warm-Up 3: Linked List Quick-Fire
1. Reverse a singly linked list
2. Find the middle node
3. Detect cycle
4. Merge two sorted lists
5. Remove Nth node from end

---

## Warm-Up 4: Stack & Queue Quick-Fire
1. Check balanced parentheses
2. Implement queue using two stacks
3. Next greater element for each in array
4. Evaluate postfix expression
5. Min stack (O(1) GetMin)

---

## Warm-Up 5: Trees Quick-Fire
1. Inorder, Preorder, Postorder traversal
2. Height of binary tree
3. Validate BST
4. Level order traversal
5. Lowest Common Ancestor in BST

---

## Warm-Up 6: Graphs Quick-Fire
1. BFS from a source
2. DFS from a source
3. Detect cycle in directed graph
4. Topological sort
5. Count connected components

---

## Warm-Up 7: Sorting & Searching Quick-Fire
1. Implement binary search (iterative)
2. Search in rotated sorted array
3. Implement merge sort
4. Find kth largest element (QuickSelect)
5. Count occurrences in sorted array

---

## Warm-Up 8: DP Quick-Fire
1. Fibonacci (space-optimized)
2. Coin change (minimum coins)
3. Longest common subsequence (length)
4. 0/1 Knapsack
5. House robber (max non-adjacent sum)

---

## How to Use This

1. **Time yourself** on each warm-up section (aim for 15-20 minutes per section)
2. **Identify weak areas** — topics where you need to peek at notes
3. **Re-study** those topics before attempting the full revision test
4. **Take the test** in `Notes.md` only when you can solve ALL warm-ups confidently
5. Tell me "check" after the test for detailed review and scoring

---

## Self-Assessment Tracker

After each warm-up, rate yourself:

| Topic | Confidence (1-5) | Need Review? |
|---|---|---|
| Complexity Analysis | ___ | Yes / No |
| Arrays & Strings | ___ | Yes / No |
| Linked Lists | ___ | Yes / No |
| Stacks & Queues | ___ | Yes / No |
| Hash Tables | ___ | Yes / No |
| Trees & BST | ___ | Yes / No |
| Graphs | ___ | Yes / No |
| Sorting | ___ | Yes / No |
| Searching | ___ | Yes / No |
| Recursion & DP | ___ | Yes / No |

**Target: Score 4+ on every topic before taking the revision test.**
