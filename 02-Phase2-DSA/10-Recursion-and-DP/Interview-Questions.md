# Topic 10: Recursion and Dynamic Programming — Interview Questions

---

## Q1. What is recursion and what are its key components?
**Answer:**
Recursion is a technique where a function calls **itself** to solve a smaller version of the same problem.

Every recursive function needs:
1. **Base case** — the simplest case that can be solved directly (stops recursion).
2. **Recursive case** — reduces the problem towards the base case.
3. **Progress** — each call must move closer to the base case (otherwise: infinite loop / stack overflow).

```csharp
int Factorial(int n)
{
    if (n <= 1) return 1;          // base case
    return n * Factorial(n - 1);   // recursive case — n decreases toward 1
}

// Call stack: 5 → 4 → 3 → 2 → 1 → returns 1 → 2 → 6 → 24 → 120
```

---

## Q2. What is the difference between recursion and iteration?
**Answer:**
| | Recursion | Iteration |
|---|---|---|
| **State tracking** | Call stack (implicit) | Loop variable (explicit) |
| **Memory** | O(depth) — stack space | O(1) usually |
| **Readability** | Often cleaner for tree/divide-and-conquer | Cleaner for simple sequential tasks |
| **Risk** | Stack overflow for deep recursion | No stack overflow risk |
| **Performance** | Function call overhead | Slightly faster |

```csharp
// Recursive fibonacci — O(2ⁿ) time, O(n) space
int FibR(int n) => n <= 1 ? n : FibR(n - 1) + FibR(n - 2);

// Iterative fibonacci — O(n) time, O(1) space
int FibI(int n)
{
    if (n <= 1) return n;
    int a = 0, b = 1;
    for (int i = 2; i <= n; i++) (a, b) = (b, a + b);
    return b;
}
```

---

## Q3. What is Dynamic Programming (DP)?
**Answer:**
Dynamic Programming solves problems by breaking them into **overlapping subproblems**, solving each subproblem only **once**, and storing results for reuse:

**Two conditions for DP:**
1. **Optimal substructure** — optimal solution contains optimal solutions to subproblems.
2. **Overlapping subproblems** — same subproblems are solved multiple times.

**Two approaches:**
- **Top-down (Memoization)** — recursive + cache.
- **Bottom-up (Tabulation)** — iterative, fill a table from smallest to largest subproblem.

---

## Q4. What is memoization and how does it improve performance?
**Answer:**
Memoization stores the result of each unique function call in a cache (hash map or array) to avoid recomputation:

```csharp
// Fibonacci with memoization — O(n) time, O(n) space
int Fib(int n, Dictionary<int, int> memo = null)
{
    memo ??= new Dictionary<int, int>();
    if (n <= 1) return n;
    if (memo.TryGetValue(n, out int cached)) return cached;
    return memo[n] = Fib(n - 1, memo) + Fib(n - 2, memo);
}

// Without memo: O(2ⁿ) — recalculates Fib(2) ~Fib(n-2) times
// With memo:    O(n)  — each value computed exactly once
```

---

## Q5. What is tabulation (bottom-up DP)?
**Answer:**
Tabulation fills a table iteratively from base cases upward — no recursion, no stack overflow risk:

```csharp
// Fibonacci — bottom-up tabulation
int FibDP(int n)
{
    if (n <= 1) return n;
    int[] dp = new int[n + 1];
    dp[0] = 0; dp[1] = 1;
    for (int i = 2; i <= n; i++) dp[i] = dp[i - 1] + dp[i - 2];
    return dp[n];
}

// Space optimized — O(1) space
int FibOpt(int n)
{
    if (n <= 1) return n;
    int a = 0, b = 1;
    for (int i = 2; i <= n; i++) (a, b) = (b, a + b);
    return b;
}
```

---

## Q6. What is the 0/1 Knapsack problem?
**Answer:**
Given n items each with weight and value, find the maximum value that fits in a knapsack of capacity W. Each item can be taken at most once (0/1):

```csharp
// O(n * W) time and space
int Knapsack(int[] weights, int[] values, int W)
{
    int n = weights.Length;
    int[,] dp = new int[n + 1, W + 1];

    for (int i = 1; i <= n; i++)
        for (int w = 0; w <= W; w++)
        {
            dp[i, w] = dp[i - 1, w]; // don't take item i
            if (weights[i - 1] <= w)  // take item i if it fits
                dp[i, w] = Math.Max(dp[i, w], dp[i - 1, w - weights[i - 1]] + values[i - 1]);
        }

    return dp[n, W];
}

// Space optimized to O(W) — process weights in reverse to avoid using item twice
int KnapsackOpt(int[] weights, int[] values, int W)
{
    int[] dp = new int[W + 1];
    for (int i = 0; i < weights.Length; i++)
        for (int w = W; w >= weights[i]; w--) // reverse to prevent reuse
            dp[w] = Math.Max(dp[w], dp[w - weights[i]] + values[i]);
    return dp[W];
}
```

---

## Q7. What is the Coin Change problem?
**Answer:**
Find the **minimum number of coins** to make amount using unlimited coins of each denomination:

```csharp
// O(amount * coins.Length) time and space
int CoinChange(int[] coins, int amount)
{
    int[] dp = new int[amount + 1];
    Array.Fill(dp, amount + 1); // sentinel: impossible value
    dp[0] = 0;

    for (int i = 1; i <= amount; i++)
        foreach (int coin in coins)
            if (coin <= i)
                dp[i] = Math.Min(dp[i], dp[i - coin] + 1);

    return dp[amount] > amount ? -1 : dp[amount];
}
// coins=[1,5,11], amount=15 → 3 (11+1+1+1 vs 5+5+5)
```

**Variation — Count ways:** Replace `Min` with `+=` (unbounded knapsack variant).

---

## Q8. What is the Longest Common Subsequence (LCS)?
**Answer:**
Find the longest subsequence present in both strings (not necessarily contiguous):

```csharp
// O(m * n) time and space
int LCS(string s1, string s2)
{
    int m = s1.Length, n = s2.Length;
    int[,] dp = new int[m + 1, n + 1];

    for (int i = 1; i <= m; i++)
        for (int j = 1; j <= n; j++)
            dp[i, j] = s1[i - 1] == s2[j - 1]
                ? dp[i - 1, j - 1] + 1            // characters match
                : Math.Max(dp[i - 1, j], dp[i, j - 1]); // take best

    return dp[m, n];
}
// "abcde", "ace" → 3 (ace)
```

Related problems: Longest Common Substring, Edit Distance, Shortest Common Supersequence.

---

## Q9. What is the Longest Increasing Subsequence (LIS)?
**Answer:**
```csharp
// O(n²) DP
int LIS(int[] nums)
{
    int n = nums.Length;
    int[] dp = new int[n];
    Array.Fill(dp, 1); // each element alone is a LIS of length 1
    int max = 1;

    for (int i = 1; i < n; i++)
        for (int j = 0; j < i; j++)
            if (nums[j] < nums[i])
            {
                dp[i] = Math.Max(dp[i], dp[j] + 1);
                max = Math.Max(max, dp[i]);
            }
    return max;
}

// O(n log n) — using patience sorting + binary search
int LIS_NLogN(int[] nums)
{
    var tails = new List<int>();
    foreach (int n in nums)
    {
        int pos = tails.BinarySearch(n);
        if (pos < 0) pos = ~pos;
        if (pos == tails.Count) tails.Add(n);
        else tails[pos] = n;
    }
    return tails.Count;
}
```

---

## Q10. What is the edit distance (Levenshtein distance) problem?
**Answer:**
Minimum number of insertions, deletions, or substitutions to transform word1 into word2:

```csharp
int EditDistance(string s1, string s2)
{
    int m = s1.Length, n = s2.Length;
    int[,] dp = new int[m + 1, n + 1];

    for (int i = 0; i <= m; i++) dp[i, 0] = i; // delete all of s1
    for (int j = 0; j <= n; j++) dp[0, j] = j; // insert all of s2

    for (int i = 1; i <= m; i++)
        for (int j = 1; j <= n; j++)
            dp[i, j] = s1[i - 1] == s2[j - 1]
                ? dp[i - 1, j - 1]              // characters match — no operation
                : 1 + Math.Min(dp[i - 1, j - 1],   // substitute
                      Math.Min(dp[i - 1, j],          // delete
                               dp[i, j - 1]));         // insert

    return dp[m, n];
}
// "horse" → "ros" = 3 operations
```

---

## Q11. What is the climbing stairs problem?
**Answer:**
Count ways to climb n stairs, taking 1 or 2 steps at a time — equivalent to Fibonacci:

```csharp
int ClimbStairs(int n)
{
    if (n <= 2) return n;
    int prev2 = 1, prev1 = 2;
    for (int i = 3; i <= n; i++) (prev2, prev1) = (prev1, prev2 + prev1);
    return prev1;
}
// n=5 → 8 ways
```

**Generalization:** if you can take 1, 2, or 3 steps, recurrence is `dp[i] = dp[i-1] + dp[i-2] + dp[i-3]`.

---

## Q12. What is the subset sum problem?
**Answer:**
Determine if a subset of the array sums to a target:

```csharp
bool SubsetSum(int[] nums, int target)
{
    bool[] dp = new bool[target + 1];
    dp[0] = true; // empty subset sums to 0

    foreach (int num in nums)
        for (int j = target; j >= num; j--) // reverse to avoid reuse
            dp[j] = dp[j] || dp[j - num];

    return dp[target];
}
// [3, 34, 4, 12, 5, 2], target=9 → true (4+5 or 3+4+2)
```

---

## Q13. What is the house robber problem?
**Answer:**
Maximum sum without taking adjacent elements:

```csharp
int Rob(int[] nums)
{
    if (nums.Length == 1) return nums[0];
    int prev2 = nums[0], prev1 = Math.Max(nums[0], nums[1]);

    for (int i = 2; i < nums.Length; i++)
    {
        int curr = Math.Max(prev1, prev2 + nums[i]);
        prev2 = prev1;
        prev1 = curr;
    }
    return prev1;
}
// [2,7,9,3,1] → 12 (2+9+1)
```

**Circular variant (House Robber II):** Run the algorithm twice — once on `nums[0..n-2]` and once on `nums[1..n-1]`, take the max.

---

## Q14. What is memoization vs tabulation — which to use when?
**Answer:**
| | Memoization (Top-down) | Tabulation (Bottom-up) |
|---|---|---|
| **Implementation** | Recursive + cache | Iterative, fill table |
| **Subproblems** | Only solves needed subproblems | Solves all subproblems |
| **Stack usage** | O(depth) — stack overflow risk | O(1) — no recursion |
| **Code clarity** | Often closer to problem definition | More boilerplate |
| **Space optimization** | Harder | Easy (rolling array) |
| **When to use** | Sparse subproblem space | Dense subproblem space |

**Rule of thumb:** Start with memoization for clarity. Switch to tabulation if recursion depth is a concern or you need to optimize space.

---

## Q15. What are common DP patterns and how do you recognize them?
**Answer:**
| Pattern | Description | Examples |
|---|---|---|
| **Linear DP** | State depends on previous element(s) | Fibonacci, Climbing Stairs, House Robber |
| **Knapsack** | Include/exclude items | 0/1 Knapsack, Subset Sum, Coin Change |
| **Interval DP** | Subproblem = subarray/substring | Matrix Chain Multiplication, Burst Balloons, Palindrome Partitioning |
| **Grid DP** | Move through a 2D grid | Unique Paths, Minimum Path Sum |
| **String DP** | Two strings | LCS, Edit Distance, Longest Common Substring |
| **State machine** | Finite states (hold/not hold stock) | Best Time to Buy Stock |
| **Bitmask DP** | Subset represented as bitmask | Traveling Salesman, Set Cover |

**How to recognize DP:**
- Problem asks for min/max/count/true-false of all possibilities.
- Naive brute force has exponential time.
- Subproblems overlap (same inputs computed multiple times).
- Optimal answer can be built from optimal subproblem answers.
