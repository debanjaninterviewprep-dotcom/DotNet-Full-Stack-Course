# Topic 6: Trees & Binary Search Trees — Practice Problems

## Problem 1: Binary Tree Basics (Easy)
**Concept**: Tree construction and traversals

### 1a. Build a Binary Tree
Manually construct this tree using `TreeNode` class:
```
        1
       / \
      2   3
     / \   \
    4   5   6
```

### 1b. Implement All 4 Traversals
Print the tree in:
1. **Preorder** (both recursive and iterative)
2. **Inorder** (both recursive and iterative)
3. **Postorder** (recursive)
4. **Level Order** (BFS with queue)

### 1c. Tree Properties
For the tree above, write functions to find:
- Height of tree
- Total number of nodes
- Number of leaf nodes
- Is the tree balanced?

**Expected Output:**
```
Preorder:    1, 2, 4, 5, 3, 6
Inorder:     4, 2, 5, 1, 3, 6
Postorder:   4, 5, 2, 6, 3, 1
Level Order: [[1], [2, 3], [4, 5, 6]]
Height: 2
Total Nodes: 6
Leaf Nodes: 3 (4, 5, 6)
Balanced: true
```

---

## Problem 2: BST Operations (Easy-Medium)
**Concept**: BST insert, search, delete, traversal

### 2a. Build a BST
Insert these values in order: `8, 3, 10, 1, 6, 14, 4, 7, 13`

Draw the resulting tree (in comments), then verify with inorder traversal (should be sorted).

### 2b. Implement BST Operations
- `Search(val)` — return true/false
- `Insert(val)` — add to correct position
- `Delete(val)` — handle all 3 cases
- `FindMin()` and `FindMax()`
- `Inorder()` — print sorted output

### 2c. Test Deletion
Starting from the BST built in 2a:
1. Delete a leaf (13)
2. Delete a node with one child (14)
3. Delete a node with two children (3)
Print inorder after each deletion.

**Expected Output:**
```
Initial BST (inorder): 1, 3, 4, 6, 7, 8, 10, 13, 14
After delete 13:       1, 3, 4, 6, 7, 8, 10, 14
After delete 14:       1, 3, 4, 6, 7, 8, 10
After delete 3:        1, 4, 6, 7, 8, 10
Min: 1, Max: 10
Search(6): true
Search(15): false
```

---

## Problem 3: Tree Problem-Solving (Medium)
**Concept**: Classic binary tree interview problems

### 3a. Check if Two Trees are Identical
```
Tree A:  1        Tree B:  1
        / \              / \
       2   3            2   3
Output: true
```

### 3b. Mirror (Invert) a Binary Tree
```
Input:       1          Output:    1
            / \                   / \
           2   3                 3   2
          / \                       / \
         4   5                     5   4
```

### 3c. Maximum Depth and Minimum Depth
```
Tree:     1
         / \
        2   3
       /
      4
Max Depth: 3 (path: 1→2→4)
Min Depth: 2 (path: 1→3)
```

### 3d. Check if Tree is Symmetric
```
Symmetric:       1          Not Symmetric:   1
                / \                         / \
               2   2                       2   2
              / \ / \                       \   \
             3  4 4  3                       3   3
```

### 3e. Path Sum
Check if there's a root-to-leaf path that sums to a target.
```
Tree:     5        Target: 22
         / \
        4   8
       /   / \
      11  13  4
     / \       \
    7   2       1

Path: 5→4→11→2 = 22 → true
```

---

## Problem 4: Advanced Tree Problems (Medium-Hard)
**Concept**: Complex BST and binary tree algorithms

### 4a. Validate BST
Given a binary tree, determine if it's a valid BST.
```
     5
    / \
   1   7       → true
      / \
     6   8

     5
    / \
   1   4       → false (4 < 5 but in right subtree!)
      / \
     3   6
```

### 4b. Kth Smallest Element in BST
```
BST:      5
         / \
        3   6
       / \
      2   4
     /
    1
k = 3 → Output: 3 (elements in order: 1,2,3,4,5,6)
```

### 4c. Lowest Common Ancestor
Find LCA in a BST and in a regular Binary Tree.
```
BST:    6
       / \
      2   8
     / \ / \
    0  4 7  9
      / \
     3   5

LCA(2, 8) = 6
LCA(2, 4) = 2
LCA(3, 5) = 4
```

### 4d. Convert Sorted Array to Balanced BST
```
Input: [1, 2, 3, 4, 5, 6, 7]
Output (inorder should be same, tree should be balanced):
        4
       / \
      2   6
     / \ / \
    1  3 5  7
```

### 4e. Serialize and Deserialize Binary Tree
Convert a binary tree to a string and back.
```
Tree:     1
         / \
        2   3
           / \
          4   5

Serialize: "1,2,null,null,3,4,null,null,5,null,null"
Deserialize: reconstructs the same tree
```

---

## Problem 5: Tree Design Challenge (Hard)
**Concept**: Complete BST implementation with advanced features

### Build a Complete Binary Search Tree Library

Implement a `BinarySearchTree<T>` class supporting:

1. **Core Operations**: Insert, Delete, Search, FindMin, FindMax
2. **Traversals**: Preorder, Inorder, Postorder, LevelOrder — each returning `List<T>`
3. **Properties**: Height, Count, IsBalanced, IsEmpty
4. **Advanced**: 
   - `KthSmallest(k)` — return kth smallest element
   - `RangeSearch(min, max)` — return all values in range [min, max]
   - `Floor(val)` — largest value ≤ val
   - `Ceiling(val)` — smallest value ≥ val
   - `PrintTree()` — visual representation

**Expected Output:**
```
=== BST Library Demo ===
Insert: 50, 30, 70, 20, 40, 60, 80, 10, 25

Tree Visualization:
            50
          /    \
        30      70
       /  \    /  \
      20   40 60   80
     / \
    10  25

Inorder:  [10, 20, 25, 30, 40, 50, 60, 70, 80]
Height: 3
Count: 9
Balanced: true

Search(40): true
Search(55): false
Min: 10, Max: 80
KthSmallest(3): 25
RangeSearch(25, 60): [25, 30, 40, 50, 60]
Floor(45): 40
Ceiling(45): 50

Delete(30): Success
Inorder: [10, 20, 25, 40, 50, 60, 70, 80]
```

---

### Submission
- Create a new console project: `dotnet new console -n TreesBSTPractice`
- Solve all problems in `Program.cs`
- Comment each solution with **Time: O(?), Space: O(?)**
- Test with edge cases: empty tree, single node, skewed tree
- Tell me "check" when you're ready for review!
