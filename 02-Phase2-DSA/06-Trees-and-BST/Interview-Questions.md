# Topic 06: Trees and BST — Interview Questions

---

## Q1. What is a tree and what are its key terminologies?
**Answer:**
A tree is a hierarchical data structure of **nodes** connected by **edges**, with no cycles and a single root.

| Term | Definition |
|---|---|
| **Root** | Top-most node (no parent) |
| **Leaf** | Node with no children |
| **Height** | Longest path from a node to a leaf |
| **Depth** | Distance from root to the node |
| **Degree** | Number of children a node has |
| **Subtree** | A node and all its descendants |
| **Level** | Depth + 1 (root is level 1) |

```
        1          ← root (depth 0, height 2)
       / \
      2   3        ← depth 1
     / \
    4   5          ← leaves (depth 2, height 0)
```

---

## Q2. What is a Binary Search Tree (BST) and what are its properties?
**Answer:**
A BST is a binary tree where for every node:
- All values in the **left subtree** are **less than** the node's value.
- All values in the **right subtree** are **greater than** the node's value.
- Both subtrees are also BSTs.

```csharp
class TreeNode
{
    public int Val;
    public TreeNode? Left, Right;
    public TreeNode(int val) => Val = val;
}
```

Operations on a **balanced** BST:
| Operation | Time |
|---|---|
| Search | O(log n) |
| Insert | O(log n) |
| Delete | O(log n) |
| Min/Max | O(log n) |

On an **unbalanced** BST (e.g., sorted input): degrades to O(n).

---

## Q3. What are tree traversals and how are they implemented?
**Answer:**
**DFS traversals** (implemented recursively or with a stack):

```csharp
// Inorder: Left → Root → Right (gives sorted order for BST)
void Inorder(TreeNode? node, List<int> result)
{
    if (node == null) return;
    Inorder(node.Left, result);
    result.Add(node.Val);
    Inorder(node.Right, result);
}

// Preorder: Root → Left → Right (used to serialize/copy trees)
void Preorder(TreeNode? node, List<int> result)
{
    if (node == null) return;
    result.Add(node.Val);
    Preorder(node.Left, result);
    Preorder(node.Right, result);
}

// Postorder: Left → Right → Root (used to delete trees, evaluate expressions)
void Postorder(TreeNode? node, List<int> result)
{
    if (node == null) return;
    Postorder(node.Left, result);
    Postorder(node.Right, result);
    result.Add(node.Val);
}
```

**BFS / Level-order traversal** (uses a queue):
```csharp
IList<IList<int>> LevelOrder(TreeNode? root)
{
    var result = new List<IList<int>>();
    if (root == null) return result;
    var queue = new Queue<TreeNode>();
    queue.Enqueue(root);
    while (queue.Count > 0)
    {
        var level = new List<int>();
        int size = queue.Count;
        for (int i = 0; i < size; i++)
        {
            var node = queue.Dequeue();
            level.Add(node.Val);
            if (node.Left  != null) queue.Enqueue(node.Left);
            if (node.Right != null) queue.Enqueue(node.Right);
        }
        result.Add(level);
    }
    return result;
}
```

---

## Q4. How do you validate whether a tree is a valid BST?
**Answer:**
Check that every node's value lies within a valid range, propagated from the root:

```csharp
bool IsValidBST(TreeNode? root, long min = long.MinValue, long max = long.MaxValue)
{
    if (root == null) return true;
    if (root.Val <= min || root.Val >= max) return false;
    return IsValidBST(root.Left,  min,      root.Val) &&
           IsValidBST(root.Right, root.Val, max);
}

// Alternative: inorder traversal must be strictly increasing
bool IsValidBST_Inorder(TreeNode? root)
{
    long prev = long.MinValue;
    return Check(root);
    bool Check(TreeNode? node)
    {
        if (node == null) return true;
        if (!Check(node.Left)) return false;
        if (node.Val <= prev) return false;
        prev = node.Val;
        return Check(node.Right);
    }
}
```

---

## Q5. What is the height/depth of a binary tree and how do you compute it?
**Answer:**
```csharp
// Height: longest path from root to any leaf — O(n)
int Height(TreeNode? node)
{
    if (node == null) return -1; // or 0 if counting nodes not edges
    return 1 + Math.Max(Height(node.Left), Height(node.Right));
}

// Check if balanced — height difference of subtrees ≤ 1 at every node
bool IsBalanced(TreeNode? node)
{
    return CheckHeight(node) != -2;

    int CheckHeight(TreeNode? n)
    {
        if (n == null) return -1;
        int left = CheckHeight(n.Left);
        if (left == -2) return -2;
        int right = CheckHeight(n.Right);
        if (right == -2) return -2;
        if (Math.Abs(left - right) > 1) return -2; // unbalanced sentinel
        return 1 + Math.Max(left, right);
    }
}
```

---

## Q6. What is the Lowest Common Ancestor (LCA)?
**Answer:**
The LCA of two nodes `p` and `q` is the deepest node that is an ancestor of both:

```csharp
// In a BST — O(log n) for balanced tree
TreeNode? LCA_BST(TreeNode? root, int p, int q)
{
    while (root != null)
    {
        if (p < root.Val && q < root.Val) root = root.Left;
        else if (p > root.Val && q > root.Val) root = root.Right;
        else return root; // one on each side, or one equals root
    }
    return null;
}

// In a general binary tree — O(n)
TreeNode? LCA_BinaryTree(TreeNode? root, TreeNode p, TreeNode q)
{
    if (root == null || root == p || root == q) return root;
    var left  = LCA_BinaryTree(root.Left,  p, q);
    var right = LCA_BinaryTree(root.Right, p, q);
    return left != null && right != null ? root : left ?? right;
}
```

---

## Q7. How do you find the diameter of a binary tree?
**Answer:**
Diameter = longest path between any two nodes (may or may not pass through root):

```csharp
int DiameterOfBinaryTree(TreeNode? root)
{
    int diameter = 0;
    Depth(root);
    return diameter;

    int Depth(TreeNode? node)
    {
        if (node == null) return 0;
        int left  = Depth(node.Left);
        int right = Depth(node.Right);
        diameter = Math.Max(diameter, left + right); // path through this node
        return 1 + Math.Max(left, right);
    }
}
```

---

## Q8. How do you serialize and deserialize a binary tree?
**Answer:**
Use preorder traversal with null markers:

```csharp
string Serialize(TreeNode? root)
{
    var sb = new System.Text.StringBuilder();
    void Dfs(TreeNode? node)
    {
        if (node == null) { sb.Append("null,"); return; }
        sb.Append(node.Val + ",");
        Dfs(node.Left);
        Dfs(node.Right);
    }
    Dfs(root);
    return sb.ToString();
}

TreeNode? Deserialize(string data)
{
    var vals = new Queue<string>(data.Split(','));
    TreeNode? Build()
    {
        var val = vals.Dequeue();
        if (val == "null") return null;
        var node = new TreeNode(int.Parse(val));
        node.Left  = Build();
        node.Right = Build();
        return node;
    }
    return Build();
}
```

---

## Q9. What is a balanced BST? What are AVL trees and Red-Black trees?
**Answer:**
A **balanced BST** maintains O(log n) height by rebalancing after insertions/deletions.

**AVL Tree:**
- Strictly balanced: height difference (balance factor) of any node ≤ 1.
- Uses rotations (left, right, left-right, right-left) to maintain balance.
- Faster lookups than Red-Black; slower insertions/deletions.

**Red-Black Tree:**
- Each node is red or black; maintains color rules to guarantee height ≤ 2 log(n+1).
- More relaxed balancing than AVL → faster insertions/deletions.
- Used by `SortedDictionary<K,V>` and `SortedSet<T>` in .NET.

**B-Tree / B+ Tree:**
- Multi-way search tree optimized for disk access (databases, file systems).
- Nodes hold multiple keys, reducing tree height.

---

## Q10. How do you find the Kth smallest element in a BST?
**Answer:**
Inorder traversal yields sorted order — stop at the Kth element:

```csharp
int KthSmallest(TreeNode? root, int k)
{
    int result = 0, count = 0;
    void Inorder(TreeNode? node)
    {
        if (node == null || count >= k) return;
        Inorder(node.Left);
        if (++count == k) { result = node.Val; return; }
        Inorder(node.Right);
    }
    Inorder(root);
    return result;
}

// Iterative (space-efficient — no full traversal)
int KthSmallest_Iter(TreeNode? root, int k)
{
    var stack = new Stack<TreeNode>();
    while (true)
    {
        while (root != null) { stack.Push(root); root = root.Left; }
        root = stack.Pop();
        if (--k == 0) return root.Val;
        root = root.Right;
    }
}
```

---

## Q11. How do you convert a sorted array to a balanced BST?
**Answer:**
Use the middle element as root — O(n) time:

```csharp
TreeNode? SortedArrayToBST(int[] nums, int lo = 0, int hi = -1)
{
    if (hi == -1) hi = nums.Length - 1;
    if (lo > hi) return null;
    int mid = lo + (hi - lo) / 2;
    return new TreeNode(nums[mid])
    {
        Left  = SortedArrayToBST(nums, lo, mid - 1),
        Right = SortedArrayToBST(nums, mid + 1, hi)
    };
}
// [1,2,3,4,5,6,7] → balanced BST of height 2
```

---

## Q12. What is a trie (prefix tree) and what are its uses?
**Answer:**
A **trie** is a tree where each path from root to leaf represents a word. Each node holds a character and children:

```csharp
class TrieNode { public TrieNode[] Children = new TrieNode[26]; public bool IsEnd; }

class Trie
{
    private TrieNode _root = new();

    public void Insert(string word)
    {
        var node = _root;
        foreach (char c in word)
        {
            int i = c - 'a';
            node.Children[i] ??= new TrieNode();
            node = node.Children[i];
        }
        node.IsEnd = true;
    }

    public bool Search(string word)
    {
        var node = _root;
        foreach (char c in word)
        {
            int i = c - 'a';
            if (node.Children[i] == null) return false;
            node = node.Children[i];
        }
        return node.IsEnd;
    }
}
// Insert: O(m), Search: O(m) where m = word length
```

Applications: autocomplete, spell check, IP routing, word search.

---

## Q13. How do you find all paths from root to leaf that sum to a target?
**Answer:**
```csharp
IList<IList<int>> PathSum(TreeNode? root, int target)
{
    var result = new List<IList<int>>();
    var path = new List<int>();

    void Dfs(TreeNode? node, int remaining)
    {
        if (node == null) return;
        path.Add(node.Val);
        remaining -= node.Val;
        if (node.Left == null && node.Right == null && remaining == 0)
            result.Add(new List<int>(path)); // found valid path
        else { Dfs(node.Left, remaining); Dfs(node.Right, remaining); }
        path.RemoveAt(path.Count - 1); // backtrack
    }

    Dfs(root, target);
    return result;
}
```

---

## Q14. What is the maximum path sum in a binary tree?
**Answer:**
A path can go through any node, not necessarily the root. At each node, decide whether to extend one child path or form a peak:

```csharp
int MaxPathSum(TreeNode? root)
{
    int maxSum = int.MinValue;
    int Gain(TreeNode? node)
    {
        if (node == null) return 0;
        int leftGain  = Math.Max(Gain(node.Left),  0); // ignore negative paths
        int rightGain = Math.Max(Gain(node.Right), 0);
        maxSum = Math.Max(maxSum, node.Val + leftGain + rightGain); // path through node
        return node.Val + Math.Max(leftGain, rightGain); // best single-branch extension
    }
    Gain(root);
    return maxSum;
}
```

---

## Q15. What are segment trees and Fenwick trees (Binary Indexed Trees)?
**Answer:**
**Segment Tree:**
- Tree structure that stores information about array intervals/segments.
- Supports range queries (sum, min, max) and point updates in O(log n).
- Space: O(4n) for an array of size n.

**Fenwick Tree (BIT):**
- Simpler, more space-efficient — O(n) space.
- Supports prefix sum queries and point updates in O(log n).
- Only works for associative, invertible operations (sum, XOR — not min/max).

```csharp
class FenwickTree
{
    private int[] _tree;
    public FenwickTree(int n) => _tree = new int[n + 1];

    public void Update(int i, int delta) // 1-indexed
    {
        for (; i < _tree.Length; i += i & (-i)) _tree[i] += delta;
    }

    public int PrefixSum(int i) // sum of [1..i]
    {
        int sum = 0;
        for (; i > 0; i -= i & (-i)) sum += _tree[i];
        return sum;
    }

    public int RangeSum(int l, int r) => PrefixSum(r) - PrefixSum(l - 1);
}
```
