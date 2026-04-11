# Topic 2: Arrays & Strings (DSA) — Practice Problems

## Problem 1: Array Warm-Up (Easy)
**Concept**: Basic array operations, two pointers

Solve these without using LINQ:

1. **Reverse an array** in-place using two pointers
2. **Find the second largest** element in an array (one pass, O(n))
3. **Move all zeroes to the end** while maintaining order of non-zero elements
   - Input: `[0, 1, 0, 3, 12]` → Output: `[1, 3, 12, 0, 0]`
4. **Check if array is sorted** (ascending) — return true/false
5. **Merge two sorted arrays** into one sorted array
   - Input: `[1, 3, 5]`, `[2, 4, 6]` → Output: `[1, 2, 3, 4, 5, 6]`

For each, state the **time and space complexity**.

**Expected Output:**
```
--- Reverse ---
[5, 4, 3, 2, 1] → [1, 2, 3, 4, 5]
Time: O(n), Space: O(1)

--- Second Largest ---
[12, 35, 1, 10, 34, 1] → 34
Time: O(n), Space: O(1)

--- Move Zeroes ---
[0, 1, 0, 3, 12] → [1, 3, 12, 0, 0]
Time: O(n), Space: O(1)
```

---

## Problem 2: Sliding Window Problems (Easy-Medium)
**Concept**: Fixed and variable sliding window

### 2a. Maximum Sum Subarray of Size K (Fixed Window)
```
Input: [2, 1, 5, 1, 3, 2], k = 3
Output: 9 (subarray [5, 1, 3])
```

### 2b. Smallest Subarray with Sum ≥ Target (Variable Window)
```
Input: [2, 3, 1, 2, 4, 3], target = 7
Output: 2 (subarray [4, 3])
```

### 2c. Longest Substring Without Repeating Characters
```
Input: "abcabcbb"
Output: 3 ("abc")
```

### 2d. Count Anagrams in a String
Given a string and a pattern, count how many anagrams of the pattern exist in the string.
```
Input: s = "cbaebabacd", p = "abc"
Output: 2 (found at index 0: "cba", index 6: "bac")
```

For each, implement both **brute force** and **optimal** solutions. Compare complexities.

---

## Problem 3: Two Pointer Challenges (Medium)
**Concept**: Two pointer patterns (opposite ends, same direction, fast/slow)

### 3a. Two Sum (sorted array)
```
Input: [2, 7, 11, 15], target = 9
Output: [0, 1]
```

### 3b. Three Sum
Find all unique triplets that sum to zero.
```
Input: [-1, 0, 1, 2, -1, -4]
Output: [[-1, -1, 2], [-1, 0, 1]]
```

### 3c. Container With Most Water
Given heights, find two lines that form a container holding the most water.
```
Input: [1, 8, 6, 2, 5, 4, 8, 3, 7]
Output: 49 (between index 1 and 8, height min(8,7)=7, width=7)
```

### 3d. Trapping Rain Water
Calculate how much rain water can be trapped between bars.
```
Input: [0, 1, 0, 2, 1, 0, 1, 3, 2, 1, 2, 1]
Output: 6
```

### 3e. Remove Duplicates from Sorted Array
Return new length after removing duplicates in-place.
```
Input: [1, 1, 2, 2, 3, 4, 4, 5]
Output: 5, array becomes [1, 2, 3, 4, 5, ...]
```

---

## Problem 4: String Algorithm Challenges (Medium-Hard)
**Concept**: String manipulation, pattern matching, character counting

### 4a. Valid Anagram
```
Input: s = "anagram", t = "nagaram" → true
Input: s = "rat", t = "car" → false
```

### 4b. Group Anagrams
```
Input: ["eat", "tea", "tan", "ate", "nat", "bat"]
Output: [["eat","tea","ate"], ["tan","nat"], ["bat"]]
```

### 4c. Longest Palindromic Substring
```
Input: "babad"
Output: "bab" or "aba" (both valid)
```
Hint: Expand from center technique — try each character (and each pair) as center.

### 4d. String Compression
```
Input: "aabcccccaaa"
Output: "a2b1c5a3"
If compressed is longer than original, return original.
```

### 4e. Implement strStr() — Find Needle in Haystack
```
Input: haystack = "hello", needle = "ll"
Output: 2 (first occurrence index)
```

---

## Problem 5: Array/String Hard Problems (Hard)
**Concept**: Combining multiple techniques

### 5a. Product of Array Except Self
Given an array, return a new array where each element is the product of all elements except itself. **No division allowed.**
```
Input: [1, 2, 3, 4]
Output: [24, 12, 8, 6]
```
Hint: Use prefix and suffix products.
Time: O(n), Space: O(1) extra (output array doesn't count)

### 5b. Spiral Matrix Traversal
Print a 2D matrix in spiral order.
```
Input: [[1,2,3],[4,5,6],[7,8,9]]
Output: [1,2,3,6,9,8,7,4,5]
```

### 5c. Rotate Image (Matrix) 90° Clockwise
Rotate in-place without extra matrix.
```
Input:         Output:
[1,2,3]        [7,4,1]
[4,5,6]   →    [8,5,2]
[7,8,9]        [9,6,3]
```

### 5d. Minimum Window Substring
Find the smallest substring of `s` containing all characters of `t`.
```
Input: s = "ADOBECODEBANC", t = "ABC"
Output: "BANC"
```
This is one of the hardest sliding window problems — take your time.

### 5e. Kadane's Algorithm Extended
Find the maximum sum subarray AND return the actual subarray (start and end indices), not just the sum.
```
Input: [-2, 1, -3, 4, -1, 2, 1, -5, 4]
Output: Sum = 6, Subarray = [4, -1, 2, 1] (indices 3 to 6)
```

---

### Submission
- Create a new console project: `dotnet new console -n ArraysStringsPractice`
- Solve all problems in `Program.cs`
- For each solution, add a comment with **Time: O(?), Space: O(?)**
- Test with edge cases: empty arrays, single element, all same elements
- Tell me "check" when you're ready for review!
