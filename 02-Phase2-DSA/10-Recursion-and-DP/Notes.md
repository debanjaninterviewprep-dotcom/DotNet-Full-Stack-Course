# Topic 10: Recursion & Dynamic Programming

## Part 1: Recursion

### What is Recursion?

A function that **calls itself** to solve smaller subproblems. Every recursive solution has:
1. **Base case** — The simplest problem that can be answered directly (stops recursion)
2. **Recursive case** — Break the problem into smaller subproblems

```csharp
// Factorial: n! = n × (n-1) × (n-2) × ... × 1
int Factorial(int n)
{
    if (n <= 1) return 1;       // Base case
    return n * Factorial(n - 1); // Recursive case
}

// Call stack visualization for Factorial(4):
// Factorial(4) → 4 * Factorial(3)
//                    3 * Factorial(2)
//                        2 * Factorial(1)
//                            return 1     ← base case
//                        return 2 * 1 = 2
//                    return 3 * 2 = 6
//                return 4 * 6 = 24
```

### The Call Stack

```
Factorial(4):

Stack frames:
┌─────────────────┐
│ Factorial(1) = 1│ ← Top (base case, starts returning)
├─────────────────┤
│ Factorial(2)    │
├─────────────────┤
│ Factorial(3)    │
├─────────────────┤
│ Factorial(4)    │ ← Bottom (first call)
└─────────────────┘

Too many calls → StackOverflowException!
```

---

### Classic Recursion Examples

```csharp
// Fibonacci: F(n) = F(n-1) + F(n-2)
int Fibonacci(int n)
{
    if (n <= 1) return n;  // F(0)=0, F(1)=1
    return Fibonacci(n - 1) + Fibonacci(n - 2);
}
// F(5) = F(4) + F(3)
//      = (F(3) + F(2)) + (F(2) + F(1))
//      = ((F(2)+F(1)) + (F(1)+F(0))) + ((F(1)+F(0)) + 1)
// PROBLEM: F(2) calculated 3 times! → O(2^n) time!

// Power: x^n
int Power(int x, int n)
{
    if (n == 0) return 1;
    if (n % 2 == 0)
    {
        int half = Power(x, n / 2);
        return half * half;
    }
    return x * Power(x, n - 1);
}
// O(log n) — fast exponentiation

// Sum of array
int Sum(int[] arr, int index)
{
    if (index == arr.Length) return 0;
    return arr[index] + Sum(arr, index + 1);
}

// Reverse a string
string Reverse(string s)
{
    if (s.Length <= 1) return s;
    return Reverse(s[1..]) + s[0];
}

// Check palindrome
bool IsPalindrome(string s, int left, int right)
{
    if (left >= right) return true;
    if (s[left] != s[right]) return false;
    return IsPalindrome(s, left + 1, right - 1);
}
```

### Backtracking

A recursive technique that builds solutions incrementally and **abandons** (backtracks) if a partial solution can't lead to a valid result.

```csharp
// Generate all subsets (power set)
void Subsets(int[] nums, int index, List<int> current, List<List<int>> result)
{
    result.Add(new List<int>(current)); // Add current subset
    
    for (int i = index; i < nums.Length; i++)
    {
        current.Add(nums[i]);                    // Choose
        Subsets(nums, i + 1, current, result);   // Explore
        current.RemoveAt(current.Count - 1);     // Un-choose (backtrack)
    }
}
// Subsets([1,2,3]) → [], [1], [1,2], [1,2,3], [1,3], [2], [2,3], [3]

// Generate all permutations
void Permutations(int[] nums, List<int> current, bool[] used, List<List<int>> result)
{
    if (current.Count == nums.Length)
    {
        result.Add(new List<int>(current));
        return;
    }
    
    for (int i = 0; i < nums.Length; i++)
    {
        if (used[i]) continue;
        
        used[i] = true;
        current.Add(nums[i]);
        Permutations(nums, current, used, result);
        current.RemoveAt(current.Count - 1);
        used[i] = false;
    }
}
// Permutations([1,2,3]) → [1,2,3], [1,3,2], [2,1,3], [2,3,1], [3,1,2], [3,2,1]

// N-Queens: Place N queens on N×N board so no two attack each other
void SolveNQueens(int n, int row, int[] cols, List<int[]> solutions)
{
    if (row == n)
    {
        solutions.Add((int[])cols.Clone());
        return;
    }
    
    for (int col = 0; col < n; col++)
    {
        if (IsSafe(cols, row, col))
        {
            cols[row] = col;
            SolveNQueens(n, row + 1, cols, solutions);
        }
    }
}

bool IsSafe(int[] cols, int row, int col)
{
    for (int i = 0; i < row; i++)
    {
        if (cols[i] == col) return false;                   // Same column
        if (Math.Abs(cols[i] - col) == Math.Abs(i - row)) return false; // Same diagonal
    }
    return true;
}
```

---

## Part 2: Dynamic Programming (DP)

### What is DP?

DP solves problems by breaking them into **overlapping subproblems** and storing results to avoid recomputation. It's recursion + **caching**.

### Two Approaches

```
Top-Down (Memoization):          Bottom-Up (Tabulation):
Start from big problem           Start from smallest subproblems
Cache recursive results           Build up solution iteratively
Uses recursion + dictionary       Uses loops + array
```

---

### Problem 1: Fibonacci (DP Introduction)

```csharp
// ❌ Naive Recursive — O(2^n) time, O(n) space
int FibNaive(int n)
{
    if (n <= 1) return n;
    return FibNaive(n - 1) + FibNaive(n - 2);
}

// ✅ Top-Down (Memoization) — O(n) time, O(n) space
int FibMemo(int n, Dictionary<int, int> memo)
{
    if (n <= 1) return n;
    if (memo.ContainsKey(n)) return memo[n];
    memo[n] = FibMemo(n - 1, memo) + FibMemo(n - 2, memo);
    return memo[n];
}

// ✅ Bottom-Up (Tabulation) — O(n) time, O(n) space
int FibTab(int n)
{
    if (n <= 1) return n;
    int[] dp = new int[n + 1];
    dp[0] = 0;
    dp[1] = 1;
    for (int i = 2; i <= n; i++)
        dp[i] = dp[i - 1] + dp[i - 2];
    return dp[n];
}

// ✅ Space-Optimized — O(n) time, O(1) space
int FibOptimal(int n)
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
```

### Recursion Tree for Fib(5):

```
                    F(5)
                  /      \
               F(4)      F(3)        ← F(3) computed twice!
              /    \     /   \
           F(3)   F(2) F(2) F(1)    ← F(2) computed three times!
          /   \   / \   / \
        F(2) F(1) F(1) F(0) F(1) F(0)
        / \
      F(1) F(0)

Without DP: 15 function calls for F(5)
With DP:    6 function calls (each F(i) computed once)
```

---

### Problem 2: Climbing Stairs

You can climb 1 or 2 steps at a time. How many ways to reach step n?

```csharp
// dp[i] = number of ways to reach step i
// dp[i] = dp[i-1] + dp[i-2]  (come from 1 step back OR 2 steps back)

int ClimbStairs(int n)
{
    if (n <= 2) return n;
    int prev2 = 1, prev1 = 2;
    for (int i = 3; i <= n; i++)
    {
        int current = prev1 + prev2;
        prev2 = prev1;
        prev1 = current;
    }
    return prev1;
}
// n=1: 1 way (1)
// n=2: 2 ways (1+1, 2)
// n=3: 3 ways (1+1+1, 1+2, 2+1)
// n=4: 5 ways
// Pattern: Fibonacci!
```

---

### Problem 3: 0/1 Knapsack

Given items with weights and values, maximize value within weight capacity.

```csharp
// Items: [(weight=1, value=6), (weight=2, value=10), (weight=3, value=12)]
// Capacity: 5

// Recursive with memoization
int Knapsack(int[] weights, int[] values, int capacity, int index, 
             Dictionary<(int, int), int> memo)
{
    if (index == weights.Length || capacity == 0) return 0;
    
    var key = (index, capacity);
    if (memo.ContainsKey(key)) return memo[key];
    
    // Don't take item[index]
    int skip = Knapsack(weights, values, capacity, index + 1, memo);
    
    // Take item[index] (if it fits)
    int take = 0;
    if (weights[index] <= capacity)
        take = values[index] + Knapsack(weights, values, capacity - weights[index], index + 1, memo);
    
    memo[key] = Math.Max(skip, take);
    return memo[key];
}

// Bottom-Up DP — O(n × capacity) time, O(n × capacity) space
int KnapsackDP(int[] weights, int[] values, int capacity)
{
    int n = weights.Length;
    int[,] dp = new int[n + 1, capacity + 1];
    
    for (int i = 1; i <= n; i++)
    {
        for (int w = 0; w <= capacity; w++)
        {
            dp[i, w] = dp[i - 1, w]; // Don't take
            if (weights[i - 1] <= w)
                dp[i, w] = Math.Max(dp[i, w], values[i - 1] + dp[i - 1, w - weights[i - 1]]);
        }
    }
    return dp[n, capacity];
}
```

### Knapsack DP Table:

```
Items: (w=1,v=6), (w=2,v=10), (w=3,v=12)
Capacity: 5

     Cap→  0   1   2   3   4   5
Item 0:    0   0   0   0   0   0
Item 1:    0   6   6   6   6   6
Item 2:    0   6  10  16  16  16
Item 3:    0   6  10  16  18  22

Answer: dp[3][5] = 22 (take item 1 + item 3: value 6+12=18? No, 6+10+... hmm)
Actually: take all three: 1+2+3=6 > 5, so take items 2+3: weight=5, value=22 ✓
```

---

### Problem 4: Longest Common Subsequence (LCS)

```csharp
// LCS of "ABCBDAB" and "BDCAB" → "BCAB" (length 4)

int LCS(string s1, string s2)
{
    int m = s1.Length, n = s2.Length;
    int[,] dp = new int[m + 1, n + 1];
    
    for (int i = 1; i <= m; i++)
    {
        for (int j = 1; j <= n; j++)
        {
            if (s1[i - 1] == s2[j - 1])
                dp[i, j] = dp[i - 1, j - 1] + 1; // Characters match
            else
                dp[i, j] = Math.Max(dp[i - 1, j], dp[i, j - 1]); // Take best skip
        }
    }
    return dp[m, n];
}
```

---

### Problem 5: Coin Change

Find minimum coins to make a target amount.

```csharp
// Coins: [1, 5, 10, 25], Target: 30
// Answer: 2 (25 + 5)

int CoinChange(int[] coins, int amount)
{
    int[] dp = new int[amount + 1];
    Array.Fill(dp, amount + 1); // Initialize with "impossible" value
    dp[0] = 0;
    
    for (int i = 1; i <= amount; i++)
    {
        foreach (int coin in coins)
        {
            if (coin <= i)
                dp[i] = Math.Min(dp[i], dp[i - coin] + 1);
        }
    }
    return dp[amount] > amount ? -1 : dp[amount];
}
// dp[0]=0, dp[1]=1, dp[5]=1, dp[6]=2, dp[10]=1, dp[25]=1, dp[30]=2
```

---

### Problem 6: Longest Increasing Subsequence (LIS)

```csharp
// [10, 9, 2, 5, 3, 7, 101, 18] → [2, 3, 7, 101] or [2, 5, 7, 18] → length 4

// O(n²) DP
int LIS(int[] nums)
{
    int n = nums.Length;
    int[] dp = new int[n];
    Array.Fill(dp, 1); // Every element is a subsequence of length 1
    
    for (int i = 1; i < n; i++)
    {
        for (int j = 0; j < i; j++)
        {
            if (nums[j] < nums[i])
                dp[i] = Math.Max(dp[i], dp[j] + 1);
        }
    }
    return dp.Max();
}

// O(n log n) with binary search — optimal
int LISOptimal(int[] nums)
{
    List<int> tails = new(); // Smallest tail for each length
    
    foreach (int num in nums)
    {
        int pos = tails.BinarySearch(num);
        if (pos < 0) pos = ~pos;
        
        if (pos == tails.Count)
            tails.Add(num);
        else
            tails[pos] = num;
    }
    return tails.Count;
}
```

---

## DP Framework: How to Solve Any DP Problem

### Step 1: Identify if it's a DP problem
- Can the problem be broken into overlapping subproblems?
- Does it ask for optimal (min/max), count, or feasibility?
- Keywords: "minimum", "maximum", "count ways", "is it possible"

### Step 2: Define the state
- What variables define a subproblem?
- `dp[i]` = answer for first i elements, or `dp[i][j]` = answer for subproblem (i, j)

### Step 3: Write the recurrence
- How does `dp[i]` relate to smaller subproblems?
- Usually involves decisions: take/skip, use/don't use

### Step 4: Identify base cases
- What are the trivial subproblems?

### Step 5: Determine computation order
- Bottom-up: smaller subproblems first
- Can you optimize space?

---

## Common DP Patterns

| Pattern | Example | Recurrence |
|---|---|---|
| Linear | Fibonacci, Climbing Stairs | `dp[i] = dp[i-1] + dp[i-2]` |
| Knapsack | 0/1 Knapsack, Subset Sum | `dp[i][w] = max(skip, take)` |
| String | LCS, Edit Distance | `dp[i][j]` based on `s1[i]` vs `s2[j]` |
| Interval | Matrix Chain, Burst Balloons | `dp[i][j] = min/max over k in [i,j]` |
| Grid | Unique Paths, Min Path Sum | `dp[i][j] = dp[i-1][j] + dp[i][j-1]` |
| State Machine | Stock Buy/Sell | Multiple states: hold, not-hold, cooldown |

---

## Grid DP Example

```csharp
// Unique Paths: top-left to bottom-right, only right or down
int UniquePaths(int m, int n)
{
    int[,] dp = new int[m, n];
    
    // First row and column: only one way to reach
    for (int i = 0; i < m; i++) dp[i, 0] = 1;
    for (int j = 0; j < n; j++) dp[0, j] = 1;
    
    for (int i = 1; i < m; i++)
        for (int j = 1; j < n; j++)
            dp[i, j] = dp[i - 1, j] + dp[i, j - 1];
    
    return dp[m - 1, n - 1];
}
// 3×3 grid → 6 unique paths

// Minimum Path Sum
int MinPathSum(int[,] grid)
{
    int m = grid.GetLength(0), n = grid.GetLength(1);
    
    for (int i = 1; i < m; i++) grid[i, 0] += grid[i - 1, 0];
    for (int j = 1; j < n; j++) grid[0, j] += grid[0, j - 1];
    
    for (int i = 1; i < m; i++)
        for (int j = 1; j < n; j++)
            grid[i, j] += Math.Min(grid[i - 1, j], grid[i, j - 1]);
    
    return grid[m - 1, n - 1];
}
```

---

## Key Takeaways

| Concept | Summary |
|---|---|
| Recursion | Function calls itself; needs base case to stop |
| Call Stack | Each recursive call adds a frame; too deep → stack overflow |
| Backtracking | Try choices, undo (backtrack) if invalid |
| Memoization | Top-down DP — cache recursive results |
| Tabulation | Bottom-up DP — build solution from base cases |
| Overlapping subproblems | Same subproblem solved multiple times |
| Optimal substructure | Optimal solution contains optimal sub-solutions |
| State definition | Most important step — defines what dp[i] means |
| Space optimization | Often reduce 2D table to 1D array |

---

*Next Topic: Phase 2 Revision Test →*
