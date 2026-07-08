# Topic 07: Graphs, BFS & DFS — Interview Questions

---

## Q1. What is a graph and what are its basic components?
**Answer:**
A graph is a collection of **vertices (nodes)** connected by **edges**. It models relationships between entities.

| Term | Definition |
|---|---|
| **Vertex (V)** | A node/point in the graph |
| **Edge (E)** | A connection between two vertices |
| **Directed** | Edges have direction (A → B, not B → A) |
| **Undirected** | Edges are bidirectional (A — B means A↔B) |
| **Weighted** | Edges have a numerical weight/cost |
| **Degree** | Number of edges connected to a vertex |
| **In-degree / Out-degree** | For directed graphs: edges coming in / going out |
| **Path** | Sequence of vertices connected by edges |
| **Cycle** | Path that starts and ends at the same vertex |

---

## Q2. What are adjacency matrix and adjacency list representations?
**Answer:**
**Adjacency Matrix — O(V²) space:**
```csharp
int[,] graph = new int[V, V];
graph[0, 1] = 1; // edge from 0 to 1
graph[1, 0] = 1; // undirected: also add reverse
```
- O(1) edge lookup
- O(V²) space — wastes memory for sparse graphs

**Adjacency List — O(V + E) space:**
```csharp
var graph = new List<List<int>>();
for (int i = 0; i < V; i++) graph.Add(new List<int>());
graph[0].Add(1); graph[1].Add(0); // undirected edge 0-1
```
- O(degree) edge lookup
- O(V + E) space — efficient for sparse graphs

**Prefer adjacency list** for most problems. Use matrix only when V is small and you need O(1) edge lookup.

---

## Q3. What is BFS and how is it implemented?
**Answer:**
**Breadth-First Search** explores nodes level by level using a **queue** — visits all neighbors before going deeper:

```csharp
void BFS(List<List<int>> graph, int start)
{
    bool[] visited = new bool[graph.Count];
    var queue = new Queue<int>();
    visited[start] = true;
    queue.Enqueue(start);

    while (queue.Count > 0)
    {
        int node = queue.Dequeue();
        Console.Write(node + " ");
        foreach (int neighbor in graph[node])
        {
            if (!visited[neighbor])
            {
                visited[neighbor] = true;
                queue.Enqueue(neighbor);
            }
        }
    }
}
// Time: O(V + E), Space: O(V)
```

BFS is used for: **shortest path in unweighted graphs**, level-order traversal, finding connected components.

---

## Q4. What is DFS and how is it implemented?
**Answer:**
**Depth-First Search** explores as far as possible along each branch before backtracking, using a **stack** (or recursion):

```csharp
// Recursive DFS
void DFS(List<List<int>> graph, int node, bool[] visited)
{
    visited[node] = true;
    Console.Write(node + " ");
    foreach (int neighbor in graph[node])
        if (!visited[neighbor])
            DFS(graph, neighbor, visited);
}

// Iterative DFS (explicit stack)
void DFS_Iter(List<List<int>> graph, int start)
{
    bool[] visited = new bool[graph.Count];
    var stack = new Stack<int>();
    stack.Push(start);
    while (stack.Count > 0)
    {
        int node = stack.Pop();
        if (visited[node]) continue;
        visited[node] = true;
        Console.Write(node + " ");
        foreach (int nb in graph[node]) if (!visited[nb]) stack.Push(nb);
    }
}
// Time: O(V + E), Space: O(V)
```

DFS is used for: **cycle detection**, topological sort, finding strongly connected components, maze solving.

---

## Q5. What is the difference between BFS and DFS?
**Answer:**
| | BFS | DFS |
|---|---|---|
| **Data structure** | Queue (FIFO) | Stack / Recursion |
| **Traversal** | Level by level | Branch by branch |
| **Shortest path** | ✓ (unweighted graphs) | ✗ |
| **Memory (sparse)** | O(width of tree) | O(depth of tree) |
| **Cycle detection** | ✓ | ✓ |
| **Topological sort** | ✓ (Kahn's algorithm) | ✓ (DFS-based) |
| **Best for** | Shortest paths, connectivity | Backtracking, cycle detection, SCCs |

---

## Q6. How do you detect a cycle in a directed graph?
**Answer:**
Use DFS with three states: unvisited (0), in-progress (1), done (2). A back edge to an in-progress node indicates a cycle:

```csharp
bool HasCycleDirected(int V, List<List<int>> graph)
{
    int[] state = new int[V]; // 0=unvisited, 1=in-stack, 2=done

    bool Dfs(int node)
    {
        state[node] = 1; // mark in-progress
        foreach (int nb in graph[node])
        {
            if (state[nb] == 1) return true; // back edge → cycle
            if (state[nb] == 0 && Dfs(nb)) return true;
        }
        state[node] = 2; // mark done
        return false;
    }

    for (int i = 0; i < V; i++)
        if (state[i] == 0 && Dfs(i)) return true;
    return false;
}
```

---

## Q7. How do you detect a cycle in an undirected graph?
**Answer:**
```csharp
// DFS — back edge to visited node (that isn't the parent) means cycle
bool HasCycleUndirected(int V, List<List<int>> graph)
{
    bool[] visited = new bool[V];

    bool Dfs(int node, int parent)
    {
        visited[node] = true;
        foreach (int nb in graph[node])
        {
            if (!visited[nb]) { if (Dfs(nb, node)) return true; }
            else if (nb != parent) return true; // back edge to non-parent
        }
        return false;
    }

    for (int i = 0; i < V; i++)
        if (!visited[i] && Dfs(i, -1)) return true;
    return false;
}

// Union-Find (Disjoint Set) approach — O(E α(V)) ≈ O(E)
// Each edge: if both endpoints in same set → cycle
```

---

## Q8. What is topological sort?
**Answer:**
Topological sort orders the vertices of a **Directed Acyclic Graph (DAG)** such that for every edge `u → v`, `u` appears before `v`. Only possible for DAGs (no cycles).

**DFS-based (Kahn's is alternative using BFS + in-degree):**
```csharp
IList<int> TopologicalSort(int V, List<List<int>> graph)
{
    bool[] visited = new bool[V];
    var result = new Stack<int>();

    void Dfs(int node)
    {
        visited[node] = true;
        foreach (int nb in graph[node])
            if (!visited[nb]) Dfs(nb);
        result.Push(node); // push after all descendants are processed
    }

    for (int i = 0; i < V; i++)
        if (!visited[i]) Dfs(i);

    return result.ToList();
}
// Applications: build systems, task scheduling, course prerequisites
```

---

## Q9. What is Dijkstra's algorithm?
**Answer:**
Dijkstra finds the **shortest path** from a source to all other vertices in a weighted graph with **non-negative** edge weights:

```csharp
int[] Dijkstra(int V, List<List<(int node, int weight)>> graph, int src)
{
    int[] dist = new int[V];
    Array.Fill(dist, int.MaxValue);
    dist[src] = 0;

    // (distance, node) min-heap
    var pq = new PriorityQueue<int, int>();
    pq.Enqueue(src, 0);

    while (pq.Count > 0)
    {
        int u = pq.Dequeue();
        foreach (var (v, w) in graph[u])
        {
            if (dist[u] + w < dist[v])
            {
                dist[v] = dist[u] + w;
                pq.Enqueue(v, dist[v]);
            }
        }
    }
    return dist;
}
// Time: O((V + E) log V) with priority queue
```

**Limitation:** Does NOT work with negative edge weights (use Bellman-Ford instead).

---

## Q10. What is the number of islands problem?
**Answer:**
Classic BFS/DFS flood-fill on a 2D grid:

```csharp
int NumIslands(char[][] grid)
{
    int islands = 0;
    int rows = grid.Length, cols = grid[0].Length;

    void Dfs(int r, int c)
    {
        if (r < 0 || r >= rows || c < 0 || c >= cols || grid[r][c] == '0') return;
        grid[r][c] = '0'; // mark visited (in-place)
        Dfs(r+1, c); Dfs(r-1, c); Dfs(r, c+1); Dfs(r, c-1);
    }

    for (int r = 0; r < rows; r++)
        for (int c = 0; c < cols; c++)
            if (grid[r][c] == '1') { islands++; Dfs(r, c); }

    return islands;
}
// O(rows * cols) time and space
```

---

## Q11. What is Union-Find (Disjoint Set Union)?
**Answer:**
Union-Find tracks which elements belong to the same set, supporting two operations in near O(1) amortized:

```csharp
class UnionFind
{
    private int[] parent, rank;

    public UnionFind(int n)
    {
        parent = Enumerable.Range(0, n).ToArray();
        rank = new int[n];
    }

    public int Find(int x)
    {
        if (parent[x] != x) parent[x] = Find(parent[x]); // path compression
        return parent[x];
    }

    public bool Union(int x, int y)
    {
        int px = Find(x), py = Find(y);
        if (px == py) return false; // already connected
        if (rank[px] < rank[py]) (px, py) = (py, px);
        parent[py] = px;
        if (rank[px] == rank[py]) rank[px]++;
        return true;
    }
}
// Applications: cycle detection, Kruskal's MST, number of connected components
```

---

## Q12. What is Bellman-Ford algorithm?
**Answer:**
Bellman-Ford finds shortest paths from a source, handling **negative edge weights**, and detects **negative cycles**:

```csharp
int[] BellmanFord(int V, List<(int u, int v, int w)> edges, int src)
{
    int[] dist = new int[V];
    Array.Fill(dist, int.MaxValue);
    dist[src] = 0;

    // Relax all edges V-1 times
    for (int i = 0; i < V - 1; i++)
        foreach (var (u, v, w) in edges)
            if (dist[u] != int.MaxValue && dist[u] + w < dist[v])
                dist[v] = dist[u] + w;

    // Check for negative cycles
    foreach (var (u, v, w) in edges)
        if (dist[u] != int.MaxValue && dist[u] + w < dist[v])
            throw new Exception("Negative cycle detected");

    return dist;
}
// Time: O(V * E), slower than Dijkstra but handles negative weights
```

---

## Q13. What is a minimum spanning tree (MST)?
**Answer:**
An MST connects all vertices of a weighted undirected graph with the minimum total edge weight and no cycles.

**Kruskal's Algorithm** (sort edges + Union-Find): O(E log E)
```csharp
// Sort edges by weight, add edge if it doesn't create a cycle
int Kruskal(int V, List<(int u, int v, int w)> edges)
{
    var uf = new UnionFind(V);
    int totalWeight = 0;
    foreach (var (u, v, w) in edges.OrderBy(e => e.w))
        if (uf.Union(u, v)) totalWeight += w;
    return totalWeight;
}
```

**Prim's Algorithm** (greedy, grows from a source): O(E log V) with priority queue.

---

## Q14. How do you find all connected components in an undirected graph?
**Answer:**
```csharp
int CountComponents(int V, List<List<int>> graph)
{
    bool[] visited = new bool[V];
    int components = 0;

    void Dfs(int node)
    {
        visited[node] = true;
        foreach (int nb in graph[node])
            if (!visited[nb]) Dfs(nb);
    }

    for (int i = 0; i < V; i++)
        if (!visited[i]) { Dfs(i); components++; }

    return components;
}

// Also solvable with Union-Find:
// Count distinct roots after processing all edges
```

---

## Q15. What is the course schedule problem (cycle detection in a directed graph)?
**Answer:**
**LeetCode 207 — Course Schedule:** Can you finish all courses given prerequisites?

```csharp
bool CanFinish(int numCourses, int[][] prerequisites)
{
    var graph = new List<List<int>>(numCourses);
    for (int i = 0; i < numCourses; i++) graph.Add(new List<int>());
    foreach (var p in prerequisites) graph[p[1]].Add(p[0]);

    // 0=unvisited, 1=in-progress, 2=completed
    int[] state = new int[numCourses];

    bool HasCycle(int course)
    {
        if (state[course] == 1) return true;  // cycle
        if (state[course] == 2) return false; // already checked
        state[course] = 1;
        foreach (int next in graph[course])
            if (HasCycle(next)) return true;
        state[course] = 2;
        return false;
    }

    for (int i = 0; i < numCourses; i++)
        if (HasCycle(i)) return false;
    return true;
}
```
