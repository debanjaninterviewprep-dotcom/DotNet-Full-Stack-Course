# Topic 10: Recursion & Dynamic Programming — Practice Problems

## Problem 1: Recursion Warm-Up (Easy)
**Concept**: Basic recursion with base cases and recursive cases

Solve each **recursively** (no loops allowed):

### 1a. Sum of Natural Numbers
```
Input: 5
Output: 15 (1+2+3+4+5)
```

### 1b. Power Function
```
Input: base=2, exp=10
Output: 1024
```
Implement O(log n) version using: x^n = (x^(n/2))² if n even, x × x^(n-1) if n odd.

### 1c. Count Digits
```
Input: 12345
Output: 5
```

### 1d. Check if Array is Sorted
```
Input: [1, 3, 5, 7, 9] → true
Input: [1, 3, 2, 7, 9] → false
```

### 1e. Tower of Hanoi
Move n disks from source to destination using an auxiliary peg.
```
Input: n = 3
Output:
  Move disk 1 from A to C
  Move disk 2 from A to B
  Move disk 1 from C to B
  Move disk 3 from A to C
  Move disk 1 from B to A
  Move disk 2 from B to C
  Move disk 1 from A to C
Total moves: 7 (2^n - 1)
```

---

## Problem 2: Backtracking Problems (Medium)
**Concept**: Explore all possibilities, backtrack on invalid ones

### 2a. Generate All Subsets
```
Input: [1, 2, 3]
Output: [], [1], [2], [3], [1,2], [1,3], [2,3], [1,2,3]
```

### 2b. Generate All Permutations
```
Input: [1, 2, 3]
Output: [1,2,3], [1,3,2], [2,1,3], [2,3,1], [3,1,2], [3,2,1]
```

### 2c. Combination Sum
Find all unique combinations that sum to target (can reuse numbers).
```
Input: candidates = [2, 3, 6, 7], target = 7
Output: [[2,2,3], [7]]
```

### 2d. Generate Valid Parentheses
Generate all combinations of well-formed parentheses.
```
Input: n = 3
Output: ["((()))", "(()())", "(())()", "()(())", "()()()"]
```

### 2e. Sudoku Solver (Bonus)
Fill in a 9×9 Sudoku board. Print the solved board.

---

## Problem 3: DP Fundamental Problems (Medium)
**Concept**: Memoization and tabulation on classic problems

For each problem, implement BOTH memoization (top-down) and tabulation (bottom-up).

### 3a. Fibonacci with All Approaches
Compute F(40) using:
1. Naive recursion (show it's slow)
2. Memoization
3. Tabulation
4. Space-optimized

Print time taken for each approach using `Stopwatch`.

### 3b. Climbing Stairs
```
n = 5 → 8 ways
```

### 3c. Coin Change (Minimum Coins)
```
Coins: [1, 5, 10, 25], Amount: 30
Output: 2 (25 + 5)

Coins: [2], Amount: 3
Output: -1 (impossible)
```

### 3d. House Robber
Max money from non-adjacent houses.
```
Input: [2, 7, 9, 3, 1]
Output: 12 (rob houses 0, 2, 4: 2+9+1=12)
```

### 3e. Longest Increasing Subsequence
```
Input: [10, 9, 2, 5, 3, 7, 101, 18]
Output: 4 (subsequence: [2, 3, 7, 101] or [2, 5, 7, 18])
```
Implement both O(n²) DP and O(n log n) with binary search.

---

## Problem 4: Advanced DP Problems (Medium-Hard)
**Concept**: Multi-dimensional DP and common interview patterns

### 4a. 0/1 Knapsack
```
Weights: [1, 3, 4, 5], Values: [1, 4, 5, 7], Capacity: 7
Output: 9 (items with weights 3+4=7, values 4+5=9)
```
Print the items selected.

### 4b. Longest Common Subsequence
```
Input: "ABCBDAB", "BDCAB"
Output: 4 ("BCAB")
```
Print the actual subsequence, not just the length.

### 4c. Edit Distance (Levenshtein Distance)
Minimum operations (insert, delete, replace) to convert one string to another.
```
Input: "kitten", "sitting"
Output: 3 (k→s, e→i, +g)
```

### 4d. Unique Paths with Obstacles
Grid with obstacles (1 = blocked). Count paths from top-left to bottom-right.
```
Grid:
[0, 0, 0]
[0, 1, 0]
[0, 0, 0]
Output: 2
```

### 4e. Partition Equal Subset Sum
Can the array be split into two subsets with equal sum?
```
Input: [1, 5, 11, 5]
Output: true (subsets: {1,5,5} and {11})

Input: [1, 2, 3, 5]
Output: false
```

---

## Problem 5: DP Challenge (Hard)
**Concept**: Solve a real-world optimization problem using DP

### Build a Dynamic Programming Problem Solver

Create a console application that solves multiple DP problems with visualization.

**Required Problems:**

### 5a. Matrix Chain Multiplication
Find optimal way to multiply matrices to minimize total operations.
```
Dimensions: [10, 30, 5, 60]
(Matrix A: 10×30, B: 30×5, C: 5×60)

(AB)C = 10×30×5 + 10×5×60 = 1500 + 3000 = 4500
A(BC) = 30×5×60 + 10×30×60 = 9000 + 18000 = 27000

Optimal: (AB)C with cost 4500
```

### 5b. Word Break
Can the string be segmented into dictionary words?
```
Input: s = "leetcode", dict = ["leet", "code"]
Output: true ("leet" + "code")

Input: s = "catsandog", dict = ["cats", "dog", "sand", "and", "cat"]
Output: false
```

### 5c. Longest Palindromic Subsequence
```
Input: "bbbab"
Output: 4 ("bbbb")
```

### 5d. Stock Buy and Sell (Multiple Transactions with Cooldown)
After selling, must wait one day before buying again.
```
Input: [1, 2, 3, 0, 2]
Output: 3 (buy at 1, sell at 3, cooldown, buy at 0, sell at 2)
```

### 5e. DP Table Visualizer
For any of the above problems, print the complete DP table with:
- Row/column labels
- Cell values
- Highlighted optimal path
```
=== Coin Change DP Table ===
Coins: [1, 5, 10], Amount: 12

Amount: 0  1  2  3  4  5  6  7  8  9  10  11  12
Coins:  0  1  2  3  4  1  2  3  4  5   1   2   3*

Optimal: 10 + 1 + 1 = 12 (3 coins)
```

---

### Submission
- Create a new console project: `dotnet new console -n RecursionDPPractice`
- Solve all problems
- For each: implement brute force FIRST, then optimize with DP
- Comment with **Time: O(?), Space: O(?)** for BOTH approaches
- Test edge cases: empty input, single element, all same values
- Tell me "check" when you're ready for review!
