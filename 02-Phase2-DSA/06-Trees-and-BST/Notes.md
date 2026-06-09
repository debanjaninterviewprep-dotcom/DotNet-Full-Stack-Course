# Topic 6: Trees & Binary Search Trees

## What is a Tree?

A **tree** is a hierarchical data structure consisting of **nodes** connected by **edges**. Unlike linear structures (arrays, linked lists), trees represent parent-child relationships.

```
           1          ← Root (level 0)
         /   \
        2     3       ← Level 1
       / \     \
      4   5     6     ← Level 2 (Leaves)
     /
    7                 ← Level 3
```

### Tree Terminology

| Term | Definition |
|---|---|
| **Root** | Topmost node (no parent) |
| **Parent** | Node directly above another |
| **Child** | Node directly below another |
| **Sibling** | Nodes sharing the same parent |
| **Leaf** | Node with no children |
| **Edge** | Connection between parent and child |
| **Depth** | Distance from root to node |
| **Height** | Distance from node to deepest leaf |
| **Level** | All nodes at same depth |
| **Subtree** | A node and all its descendants |
| **Degree** | Number of children a node has |

```
For the tree above:
- Root: 1
- Leaves: 5, 6, 7
- Parent of 4: 2
- Children of 2: 4, 5
- Siblings: 2 and 3
- Depth of 4: 2
- Height of tree: 3
- Degree of 2: 2, Degree of 3: 1, Degree of 6: 0
```

---

## Binary Tree

A binary tree is a tree where each node has **at most 2 children** (left and right).

### Node Structure

```csharp
public class TreeNode
{
    public int Val;
    public TreeNode? Left;
    public TreeNode? Right;
    
    public TreeNode(int val, TreeNode? left = null, TreeNode? right = null)
    {
        Val = val;
        Left = left;
        Right = right;
    }
}
```

### Types of Binary Trees

```
Full Binary Tree:           Complete Binary Tree:
Every node has 0 or 2       All levels filled except
children                    possibly last (filled left to right)
      1                           1
     / \                        /   \
    2   3                      2     3
   / \                        / \   /
  4   5                      4   5 6

Perfect Binary Tree:        Balanced Binary Tree:
All levels completely       Height difference between
filled                      left/right subtrees ≤ 1
      1                           1
     / \                        /   \
    2   3                      2     3
   / \ / \                    / \     \
  4  5 6  7                  4   5     6

Degenerate (Skewed):
Every node has 1 child — essentially a linked list!
  1
   \
    2
     \
      3   ← O(n) operations, defeats the purpose
       \
        4
```

---

## Tree Traversals

The 4 ways to visit every node in a binary tree.

### Depth-First Traversals

```
Tree:
        1
       / \
      2   3
     / \
    4   5
```

#### 1. Preorder (Root → Left → Right)

```csharp
// Recursive
void Preorder(TreeNode? node)
{
    if (node == null) return;
    Console.Write($"{node.Val} ");  // Visit root
    Preorder(node.Left);             // Traverse left
    Preorder(node.Right);            // Traverse right
}
// Output: 1 2 4 5 3

// Iterative (using stack)
List<int> PreorderIterative(TreeNode? root)
{
    List<int> result = new();
    if (root == null) return result;
    
    Stack<TreeNode> stack = new();
    stack.Push(root);
    
    while (stack.Count > 0)
    {
        TreeNode node = stack.Pop();
        result.Add(node.Val);
        if (node.Right != null) stack.Push(node.Right); // Right first!
        if (node.Left != null) stack.Push(node.Left);
    }
    return result;
}
```

#### 2. Inorder (Left → Root → Right)

```csharp
void Inorder(TreeNode? node)
{
    if (node == null) return;
    Inorder(node.Left);              // Traverse left
    Console.Write($"{node.Val} ");  // Visit root
    Inorder(node.Right);             // Traverse right
}
// Output: 4 2 5 1 3
// For BST: Inorder gives SORTED order!

// Iterative
List<int> InorderIterative(TreeNode? root)
{
    List<int> result = new();
    Stack<TreeNode> stack = new();
    TreeNode? current = root;
    
    while (current != null || stack.Count > 0)
    {
        while (current != null)
        {
            stack.Push(current);
            current = current.Left;
        }
        current = stack.Pop();
        result.Add(current.Val);
        current = current.Right;
    }
    return result;
}
```

#### 3. Postorder (Left → Right → Root)

```csharp
void Postorder(TreeNode? node)
{
    if (node == null) return;
    Postorder(node.Left);
    Postorder(node.Right);
    Console.Write($"{node.Val} ");
}
// Output: 4 5 2 3 1
```

### Breadth-First Traversal

#### 4. Level Order (BFS)

```csharp
List<List<int>> LevelOrder(TreeNode? root)
{
    List<List<int>> result = new();
    if (root == null) return result;
    
    Queue<TreeNode> queue = new();
    queue.Enqueue(root);
    
    while (queue.Count > 0)
    {
        int levelSize = queue.Count;
        List<int> level = new();
        
        for (int i = 0; i < levelSize; i++)
        {
            TreeNode node = queue.Dequeue();
            level.Add(node.Val);
            if (node.Left != null) queue.Enqueue(node.Left);
            if (node.Right != null) queue.Enqueue(node.Right);
        }
        result.Add(level);
    }
    return result;
}
// Output: [[1], [2, 3], [4, 5]]
```

### Traversal Cheat Sheet

```
              1
            /   \
           2     3
          / \   / \
         4   5 6   7

Preorder  (NLR): 1, 2, 4, 5, 3, 6, 7  → Used for: copying tree, serialization
Inorder   (LNR): 4, 2, 5, 1, 6, 3, 7  → Used for: BST sorted output
Postorder (LRN): 4, 5, 2, 6, 7, 3, 1  → Used for: deletion, expression eval
Level Order:     1, 2, 3, 4, 5, 6, 7   → Used for: BFS, shortest path in tree
```

---

## Common Binary Tree Operations

```csharp
// Height of binary tree — O(n)
int Height(TreeNode? node)
{
    if (node == null) return -1; // or 0 depending on convention
    return 1 + Math.Max(Height(node.Left), Height(node.Right));
}

// Count total nodes — O(n)
int CountNodes(TreeNode? node)
{
    if (node == null) return 0;
    return 1 + CountNodes(node.Left) + CountNodes(node.Right);
}

// Count leaf nodes — O(n)
int CountLeaves(TreeNode? node)
{
    if (node == null) return 0;
    if (node.Left == null && node.Right == null) return 1;
    return CountLeaves(node.Left) + CountLeaves(node.Right);
}

// Check if tree is balanced — O(n)
bool IsBalanced(TreeNode? node)
{
    return CheckHeight(node) != -1;
}

int CheckHeight(TreeNode? node)
{
    if (node == null) return 0;
    int left = CheckHeight(node.Left);
    if (left == -1) return -1;
    int right = CheckHeight(node.Right);
    if (right == -1) return -1;
    if (Math.Abs(left - right) > 1) return -1;
    return 1 + Math.Max(left, right);
}

// Maximum path sum — O(n)
int maxSum = int.MinValue;
int MaxPathSum(TreeNode? node)
{
    if (node == null) return 0;
    int left = Math.Max(0, MaxPathSum(node.Left));
    int right = Math.Max(0, MaxPathSum(node.Right));
    maxSum = Math.Max(maxSum, left + right + node.Val);
    return node.Val + Math.Max(left, right);
}
```

---

## Binary Search Tree (BST)

A BST is a binary tree with an ordering property:
- **Left subtree** values < current node value
- **Right subtree** values > current node value
- This applies to **every** node

```
        8
       / \
      3   10
     / \    \
    1   6    14
       / \   /
      4   7 13

Inorder: 1, 3, 4, 6, 7, 8, 10, 13, 14 (sorted!)
```

### BST Operations

```csharp
public class BST
{
    public TreeNode? Root;
    
    // Search — O(h) where h = height
    public TreeNode? Search(TreeNode? node, int val)
    {
        if (node == null || node.Val == val) return node;
        return val < node.Val ? Search(node.Left, val) : Search(node.Right, val);
    }
    
    // Insert — O(h)
    public TreeNode Insert(TreeNode? node, int val)
    {
        if (node == null) return new TreeNode(val);
        if (val < node.Val)
            node.Left = Insert(node.Left, val);
        else if (val > node.Val)
            node.Right = Insert(node.Right, val);
        return node;
    }
    
    // Delete — O(h) — three cases
    public TreeNode? Delete(TreeNode? node, int val)
    {
        if (node == null) return null;
        
        if (val < node.Val)
            node.Left = Delete(node.Left, val);
        else if (val > node.Val)
            node.Right = Delete(node.Right, val);
        else
        {
            // Case 1: Leaf node — just remove
            if (node.Left == null && node.Right == null)
                return null;
            
            // Case 2: One child — replace with child
            if (node.Left == null) return node.Right;
            if (node.Right == null) return node.Left;
            
            // Case 3: Two children — replace with inorder successor
            TreeNode successor = FindMin(node.Right);
            node.Val = successor.Val;
            node.Right = Delete(node.Right, successor.Val);
        }
        return node;
    }
    
    // Find minimum (leftmost node) — O(h)
    public TreeNode FindMin(TreeNode node)
    {
        while (node.Left != null)
            node = node.Left;
        return node;
    }
    
    // Find maximum (rightmost node) — O(h)
    public TreeNode FindMax(TreeNode node)
    {
        while (node.Right != null)
            node = node.Right;
        return node;
    }
    
    // Inorder traversal (sorted output)
    public void Inorder(TreeNode? node)
    {
        if (node == null) return;
        Inorder(node.Left);
        Console.Write($"{node.Val} ");
        Inorder(node.Right);
    }
}
```

### BST Delete Visualization

```
Delete 3 from:
        8                    8
       / \                  / \
      3   10       →       4   10
     / \    \             / \    \
    1   6    14          1   6    14
       / \   /              / \   /
      4   7 13             5   7 13

(Replace 3 with inorder successor 4, then delete 4 from right subtree)
```

### BST Complexity

| Operation | Average | Worst (Skewed) |
|---|---|---|
| Search | O(log n) | O(n) |
| Insert | O(log n) | O(n) |
| Delete | O(log n) | O(n) |
| Traversal | O(n) | O(n) |

Worst case happens when tree is skewed (inserting sorted data).

---

## Common BST Problems

```csharp
// Validate BST — O(n)
bool IsValidBST(TreeNode? node, long min = long.MinValue, long max = long.MaxValue)
{
    if (node == null) return true;
    if (node.Val <= min || node.Val >= max) return false;
    return IsValidBST(node.Left, min, node.Val) &&
           IsValidBST(node.Right, node.Val, max);
}

// Lowest Common Ancestor in BST — O(h)
TreeNode LCA_BST(TreeNode node, int p, int q)
{
    if (p < node.Val && q < node.Val) return LCA_BST(node.Left!, p, q);
    if (p > node.Val && q > node.Val) return LCA_BST(node.Right!, p, q);
    return node; // Split point — this is the LCA
}

// Lowest Common Ancestor in Binary Tree (not BST) — O(n)
TreeNode? LCA(TreeNode? node, int p, int q)
{
    if (node == null || node.Val == p || node.Val == q) return node;
    TreeNode? left = LCA(node.Left, p, q);
    TreeNode? right = LCA(node.Right, p, q);
    if (left != null && right != null) return node;
    return left ?? right;
}

// Kth Smallest Element in BST — O(h + k)
int KthSmallest(TreeNode? node, ref int k)
{
    if (node == null) return -1;
    int left = KthSmallest(node.Left, ref k);
    if (left != -1) return left;
    k--;
    if (k == 0) return node.Val;
    return KthSmallest(node.Right, ref k);
}

// Convert Sorted Array to Balanced BST — O(n)
TreeNode? SortedArrayToBST(int[] arr, int left, int right)
{
    if (left > right) return null;
    int mid = left + (right - left) / 2;
    TreeNode node = new TreeNode(arr[mid]);
    node.Left = SortedArrayToBST(arr, left, mid - 1);
    node.Right = SortedArrayToBST(arr, mid + 1, right);
    return node;
}
// [1,2,3,4,5,6,7] →     4
//                       / \
//                      2   6
//                     / \ / \
//                    1  3 5  7
```

---

## Self-Balancing BSTs (Concept Overview)

Regular BSTs can become skewed. Self-balancing trees fix this automatically.

| Tree Type | Balance Method | Operations |
|---|---|---|
| **AVL Tree** | Height difference ≤ 1, rotations after insert/delete | O(log n) guaranteed |
| **Red-Black Tree** | Node coloring rules + rotations | O(log n) guaranteed |
| **B-Tree** | Multiple keys per node, used in databases | O(log n) |

C# uses **Red-Black Trees** internally for `SortedSet<T>` and `SortedDictionary<TKey, TValue>`.

### AVL Rotations (Conceptual)

```
Right Rotation (when left-heavy):      Left Rotation (when right-heavy):
       3                1                  1                3
      /        →         \                  \      →       /
     2                    2                  2            2
    /                      \                  \          /
   1                        3                  3        1
```

---

## Key Takeaways

| Concept | Summary |
|---|---|
| Binary Tree | Each node has ≤ 2 children |
| BST Property | Left < Node < Right for every node |
| Preorder | Root → Left → Right (copying, serialization) |
| Inorder | Left → Root → Right (sorted for BST) |
| Postorder | Left → Right → Root (deletion) |
| Level Order | BFS with queue |
| BST Search | O(log n) avg — go left or right |
| BST Insert | Add as leaf in correct position |
| BST Delete | 3 cases — leaf, one child, two children |
| Balanced BST | AVL or Red-Black — O(log n) guaranteed |
| LCA | Split point in BST, recursion in Binary Tree |

---

*Next Topic: Graphs (BFS, DFS) →*
