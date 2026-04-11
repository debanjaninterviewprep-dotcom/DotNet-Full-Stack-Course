# Topic 11: Phase 2 Revision Test

## Instructions

This is your **comprehensive DSA assessment** covering all Phase 2 topics (Topics 1–10).

**Rules:**
- Time limit: **3 hours** (recommended, self-paced)
- No referring back to notes during the test
- Write clean, well-commented code
- State **Time: O(?) and Space: O(?)** for every solution
- Create a single console project: `dotnet new console -n Phase2RevisionTest`
- When done, tell me "check" to get your score and feedback

**Scoring:**
- Section A (Conceptual): 25 points
- Section B (Implementation): 35 points
- Section C (Problem Solving): 40 points
- **Total: 100 points**

---

## Section A: Conceptual Questions (25 points)
*Print answers to console as comments or strings.*

### Q1. Complexity Analysis (5 points)
State the time and space complexity for each:

```csharp
// a)
void Mystery1(int n)
{
    for (int i = 0; i < n; i++)
        for (int j = i; j < n; j++)
            Console.Write("*");
}

// b)
void Mystery2(int n)
{
    if (n <= 1) return;
    Mystery2(n / 2);
    Mystery2(n / 2);
    for (int i = 0; i < n; i++) Console.Write("*");
}

// c)
void Mystery3(int[] arr)
{
    HashSet<int> set = new(arr);
    foreach (int num in set)
        if (set.Contains(num * 2))
            Console.Write(num);
}

// d) What is the amortized complexity of adding n elements to a List<T>?

// e) What is the time complexity of BFS on a graph with V vertices and E edges?
```

### Q2. Data Structure Selection (5 points)
For each scenario, choose the **best** data structure and justify:

a) Implement an undo system — what data structure and why?
b) Find the shortest path in an unweighted graph — what algorithm and what supporting data structure?
c) Check if a string has all unique characters in O(1) space — what approach?
d) Merge k sorted lists efficiently — what data structure helps?
e) Implement a cache with O(1) get/put and automatic eviction of least recently used items

### Q3. True/False with Justification (5 points)
State True or False and explain WHY in one sentence:

a) Quick Sort is always faster than Merge Sort
b) A hash table guarantees O(1) lookup in all cases
c) BFS always finds the shortest path in any graph
d) Every recursive solution can be converted to an iterative one
e) A Binary Search Tree always has O(log n) search time

### Q4. Compare and Contrast (5 points)
In 2-3 sentences each:

a) Stack vs Queue — when to use each?
b) Adjacency Matrix vs Adjacency List
c) Memoization vs Tabulation
d) Merge Sort vs Quick Sort
e) HashSet vs SortedSet in C#

### Q5. Algorithm Identification (5 points)
Name the algorithm/technique for each description:

a) Two pointers moving at different speeds to detect a cycle in a linked list
b) Maintaining a stack in decreasing order to find next greater elements
c) Sorting by individual digit positions using counting sort as subroutine
d) Picking a pivot, partitioning array, recursing on halves
e) Computing cumulative sums for O(1) range queries

---

## Section B: Implementation (35 points)
*Write working code for each.*

### Q6. Linked List Operations (7 points)
Implement a function that:
1. Reverses a linked list iteratively (2 pts)
2. Detects if linked list has a cycle using Floyd's algorithm (2 pts)
3. Merges two sorted linked lists into one (3 pts)

```
Test Case:
List1: 1 → 3 → 5 → 7
List2: 2 → 4 → 6 → 8
Merged: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

Reverse of merged: 8 → 7 → 6 → 5 → 4 → 3 → 2 → 1
```

### Q7. Binary Search Tree (7 points)
Build a BST with insert, and implement:
1. Inorder traversal (sorted output) (2 pts)
2. Validate if a given binary tree is a valid BST (2 pts)
3. Find the Lowest Common Ancestor of two nodes (3 pts)

```
Insert: 50, 30, 70, 20, 40, 60, 80
LCA(20, 40) → 30
LCA(20, 60) → 50
LCA(60, 80) → 70
```

### Q8. Graph Traversal (7 points)
Build a graph and implement:
1. BFS traversal from a source (2 pts)
2. DFS traversal from a source (2 pts)
3. Detect cycle in directed graph (3 pts)

```
Graph (directed):
0 → 1, 0 → 2, 1 → 3, 2 → 3, 3 → 4
BFS from 0: 0, 1, 2, 3, 4
DFS from 0: 0, 1, 3, 4, 2
Has cycle: false

Add edge: 4 → 1
Has cycle: true (1 → 3 → 4 → 1)
```

### Q9. Sorting Implementation (7 points)
1. Implement Merge Sort (3 pts)
2. Implement Quick Sort with random pivot (2 pts)
3. Sort an array of objects by multiple criteria:
   - Sort students by grade (ascending), then by name (alphabetically) for same grade (2 pts)

```
Input: [("Charlie", 85), ("Alice", 92), ("Bob", 85), ("Dave", 92)]
Output: [("Bob", 85), ("Charlie", 85), ("Alice", 92), ("Dave", 92)]
```

### Q10. Dynamic Programming (7 points)
1. Coin Change — minimum coins for amount (3 pts)
2. Longest Common Subsequence — return length AND the actual subsequence (4 pts)

```
Coin Change:
Coins: [1, 5, 10, 25], Amount: 63
Output: 6 coins (25+25+10+1+1+1)

LCS:
s1 = "AGGTAB", s2 = "GXTXAYB"
Length: 4
Subsequence: "GTAB"
```

---

## Section C: Problem Solving (40 points)
*These are interview-style problems. Think before coding.*

### Q11. Two Sum Variants (8 points)

Solve ALL three variants:

**a) Two Sum (unsorted array)** — O(n) time (2 pts)
```
Input: [2, 7, 11, 15], target = 9
Output: [0, 1]
```

**b) Three Sum** — find all unique triplets summing to zero (3 pts)
```
Input: [-1, 0, 1, 2, -1, -4]
Output: [[-1, -1, 2], [-1, 0, 1]]
```

**c) Four Sum** — find all unique quadruplets summing to target (3 pts)
```
Input: [1, 0, -1, 0, -2, 2], target = 0
Output: [[-2, -1, 1, 2], [-2, 0, 0, 2], [-1, 0, 0, 1]]
```

### Q12. Sliding Window + HashMap (8 points)
**Minimum Window Substring**

Find the smallest window in `s` that contains all characters of `t`.
```
Input: s = "ADOBECODEBANC", t = "ABC"
Output: "BANC"

Input: s = "a", t = "aa"
Output: "" (impossible)
```
State your approach before coding. Time must be O(n).

### Q13. Stack Application (8 points)
**Evaluate Complex Expression**

Build a calculator that evaluates expressions with `+`, `-`, `*`, `/`, `(`, `)` and respects operator precedence.
```
Input: "3 + 4 * 2 / (1 - 5)"
Output: 1

Input: "((2 + 1) * 3 + (4 - 1)) / 2"
Output: 6

Input: "10 + 2 * 6"
Output: 22
```

### Q14. Tree + Recursion (8 points)
**Serialize and Deserialize Binary Tree**

Convert a binary tree to a string and reconstruct it.
```
Tree:      1
          / \
         2   3
            / \
           4   5

Serialize:   "1,2,null,null,3,4,null,null,5,null,null"
Deserialize: Reconstructs exact same tree

Verify: Inorder of original == Inorder of reconstructed
```

### Q15. DP Challenge (8 points)
**Longest Palindromic Subsequence**

Find the length of the longest palindromic subsequence AND print it.
```
Input: "bbbab"
Output: Length = 4, Subsequence = "bbbb"

Input: "cbbd"
Output: Length = 2, Subsequence = "bb"

Input: "character"
Output: Length = 3, Subsequence = "carac"? Let me recalculate...
"character" → "carac" is length 5? No...
"c-h-a-r-a-c-t-e-r" → "c-a-r-a-c" = wait, is that a subsequence?
Indices: c(0), a(2), r(3) or a(4), c(5) → "carac" needs checking...
Actually: c(0), a(2), r(8)? No, r is at 3 and 8.
c(0), a(4), r(8) — not palindrome.
The answer for "character" is "carac" = length 5:
c(0), a(2), r(3), a(4), c(5) → "carac" — yes, it's a palindrome and subsequence! ✓
```

---

## Bonus Challenge (10 extra points)

### Q16. Design an LRU Cache (5 points)
Implement with O(1) `Get` and `Put` using HashMap + Doubly Linked List.

### Q17. Topological Sort Application (5 points)
Given a list of courses and prerequisites, return the order to take them (or "impossible").
```
Courses: 6 (numbered 0-5)
Prerequisites: [[1,0], [2,0], [3,1], [3,2], [4,3], [5,4]]
Output: [0, 1, 2, 3, 4, 5] or [0, 2, 1, 3, 4, 5]

Courses: 2
Prerequisites: [[0,1], [1,0]]
Output: "Impossible — circular dependency!"
```

---

## Grading Rubric

| Criteria | Points |
|---|---|
| Correct output | 40% |
| Optimal time/space complexity | 25% |
| Code quality & clarity | 15% |
| Edge case handling | 10% |
| Complexity analysis accuracy | 10% |

**Grade Scale:**
- 90-100: Outstanding — Ready for interviews!
- 75-89: Great — Minor gaps to fill
- 60-74: Good — Review weak topics before moving on
- Below 60: Needs more practice — Revisit topics before Phase 3

---

Good luck, Debanjan! Take your time, think through each problem, and write clean code. 🚀
