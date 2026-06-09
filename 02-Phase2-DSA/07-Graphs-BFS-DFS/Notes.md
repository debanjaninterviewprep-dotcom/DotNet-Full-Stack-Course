# Topic 7: Graphs (BFS, DFS)

## What is a Graph?

A **graph** is a collection of **vertices (nodes)** connected by **edges**. Unlike trees, graphs can have cycles, multiple paths, and disconnected components.

```
Vertices: {A, B, C, D, E}
Edges: {(A,B), (A,C), (B,D), (C,D), (D,E)}

    A --- B
    |     |
    C --- D --- E
```

---

## Graph Terminology

| Term | Definition |
|---|---|
| **Vertex/Node** | A point in the graph |
| **Edge** | A connection between two vertices |
| **Directed** | Edges have direction (A → B ≠ B → A) |
| **Undirected** | Edges are bidirectional (A — B) |
| **Weighted** | Edges have associated costs/distances |
| **Unweighted** | All edges have equal cost |
| **Adjacent** | Two vertices connected by an edge |
| **Degree** | Number of edges connected to a vertex |
| **Path** | Sequence of vertices connected by edges |
| **Cycle** | Path that starts and ends at same vertex |
| **Connected** | Path exists between every pair of vertices |
| **Component** | A maximal connected subgraph |
| **DAG** | Directed Acyclic Graph (no cycles) |

### Types of Graphs

```
Undirected:          Directed:             Weighted:
A --- B              A → B                 A --5-- B
|     |              ↓   ↓                 |       |
C --- D              C → D                 3       2
                                           |       |
                                           C --4-- D

Cyclic:              Acyclic (DAG):
A → B                A → B
↑   ↓                    ↓
D ← C                    C → D
(A→B→C→D→A)
```

---

## Graph Representation

### Method 1: Adjacency Matrix

Use a 2D array. `matrix[i][j] = 1` if edge exists from i to j.

```
Graph:   A-B, A-C, B-D, C-D

     A  B  C  D
A  [ 0, 1, 1, 0 ]
B  [ 1, 0, 0, 1 ]
C  [ 1, 0, 0, 1 ]
D  [ 0, 1, 1, 0 ]
```

```csharp
public class AdjacencyMatrix
{
    private int[,] _matrix;
    private int _vertices;
    
    public AdjacencyMatrix(int vertices)
    {
        _vertices = vertices;
        _matrix = new int[vertices, vertices];
    }
    
    public void AddEdge(int from, int to, bool directed = false)
    {
        _matrix[from, to] = 1;
        if (!directed) _matrix[to, from] = 1;
    }
    
    public bool HasEdge(int from, int to) => _matrix[from, to] == 1;
    
    public List<int> GetNeighbors(int vertex)
    {
        List<int> neighbors = new();
        for (int i = 0; i < _vertices; i++)
            if (_matrix[vertex, i] == 1)
                neighbors.Add(i);
        return neighbors;
    }
}
// Space: O(V²) — good for dense graphs
// Check edge: O(1) — fast!
// Get neighbors: O(V) — must scan entire row
```

### Method 2: Adjacency List (Preferred)

Each vertex stores a list of its neighbors.

```
A → [B, C]
B → [A, D]
C → [A, D]
D → [B, C]
```

```csharp
public class Graph
{
    private Dictionary<int, List<int>> _adjList;
    
    public Graph()
    {
        _adjList = new Dictionary<int, List<int>>();
    }
    
    public void AddVertex(int vertex)
    {
        if (!_adjList.ContainsKey(vertex))
            _adjList[vertex] = new List<int>();
    }
    
    public void AddEdge(int from, int to, bool directed = false)
    {
        AddVertex(from);
        AddVertex(to);
        _adjList[from].Add(to);
        if (!directed) _adjList[to].Add(from);
    }
    
    public List<int> GetNeighbors(int vertex) => _adjList.GetValueOrDefault(vertex, new List<int>());
    public IEnumerable<int> GetVertices() => _adjList.Keys;
    public int VertexCount => _adjList.Count;
    
    public void Print()
    {
        foreach (var kvp in _adjList)
            Console.WriteLine($"{kvp.Key} → [{string.Join(", ", kvp.Value)}]");
    }
}
// Space: O(V + E) — good for sparse graphs
// Check edge: O(degree) — must search neighbor list
// Get neighbors: O(1) — direct access
```

### When to Use Which?

| Feature | Adjacency Matrix | Adjacency List |
|---|---|---|
| Space | O(V²) | O(V + E) |
| Check edge | O(1) | O(degree) |
| Get neighbors | O(V) | O(degree) |
| Add edge | O(1) | O(1) |
| Best for | Dense graphs (E ≈ V²) | Sparse graphs (E << V²) |
| Real-world use | Rare | Most common |

---

## Breadth-First Search (BFS)

BFS explores **level by level** — visit all neighbors before going deeper. Uses a **queue**.

```
Start at A:
Level 0: A
Level 1: B, C (neighbors of A)
Level 2: D    (neighbor of B and C, not yet visited)
Level 3: E    (neighbor of D)

Visit order: A → B → C → D → E
```

```csharp
// BFS — O(V + E) time, O(V) space
List<int> BFS(Graph graph, int start)
{
    List<int> result = new();
    HashSet<int> visited = new();
    Queue<int> queue = new();
    
    visited.Add(start);
    queue.Enqueue(start);
    
    while (queue.Count > 0)
    {
        int vertex = queue.Dequeue();
        result.Add(vertex);
        
        foreach (int neighbor in graph.GetNeighbors(vertex))
        {
            if (!visited.Contains(neighbor))
            {
                visited.Add(neighbor);
                queue.Enqueue(neighbor);
            }
        }
    }
    return result;
}
```

### BFS for Shortest Path (Unweighted)

```csharp
// Shortest path from source to all vertices — O(V + E)
Dictionary<int, int> ShortestPath(Graph graph, int source)
{
    Dictionary<int, int> distance = new();
    Dictionary<int, int> parent = new();
    Queue<int> queue = new();
    
    distance[source] = 0;
    parent[source] = -1;
    queue.Enqueue(source);
    
    while (queue.Count > 0)
    {
        int vertex = queue.Dequeue();
        
        foreach (int neighbor in graph.GetNeighbors(vertex))
        {
            if (!distance.ContainsKey(neighbor))
            {
                distance[neighbor] = distance[vertex] + 1;
                parent[neighbor] = vertex;
                queue.Enqueue(neighbor);
            }
        }
    }
    return distance;
}

// Reconstruct path from source to target
List<int> GetPath(Dictionary<int, int> parent, int target)
{
    List<int> path = new();
    int current = target;
    while (current != -1)
    {
        path.Add(current);
        current = parent[current];
    }
    path.Reverse();
    return path;
}
```

---

## Depth-First Search (DFS)

DFS explores **as deep as possible** before backtracking. Uses a **stack** (or recursion).

```
Start at A, go deep:
A → B → D → E (dead end, backtrack)
        D (backtrack) → B → A → C → D (already visited)

Visit order: A → B → D → E → C
```

```csharp
// DFS Recursive — O(V + E) time, O(V) space
void DFS(Graph graph, int vertex, HashSet<int> visited, List<int> result)
{
    visited.Add(vertex);
    result.Add(vertex);
    
    foreach (int neighbor in graph.GetNeighbors(vertex))
    {
        if (!visited.Contains(neighbor))
            DFS(graph, neighbor, visited, result);
    }
}

// DFS Iterative (using stack)
List<int> DFSIterative(Graph graph, int start)
{
    List<int> result = new();
    HashSet<int> visited = new();
    Stack<int> stack = new();
    
    stack.Push(start);
    
    while (stack.Count > 0)
    {
        int vertex = stack.Pop();
        if (visited.Contains(vertex)) continue;
        
        visited.Add(vertex);
        result.Add(vertex);
        
        foreach (int neighbor in graph.GetNeighbors(vertex))
        {
            if (!visited.Contains(neighbor))
                stack.Push(neighbor);
        }
    }
    return result;
}
```

### BFS vs DFS

| Feature | BFS | DFS |
|---|---|---|
| Data structure | Queue | Stack/Recursion |
| Strategy | Level by level | Go deep, backtrack |
| Shortest path | Yes (unweighted) | No |
| Space | O(V) (width of graph) | O(V) (depth of graph) |
| Use case | Shortest path, level order | Cycle detection, topological sort |
| Connected components | Yes | Yes |

---

## Cycle Detection

### In Undirected Graph (using DFS)

```csharp
bool HasCycleUndirected(Graph graph)
{
    HashSet<int> visited = new();
    foreach (int vertex in graph.GetVertices())
    {
        if (!visited.Contains(vertex))
        {
            if (DFSCycleUndirected(graph, vertex, -1, visited))
                return true;
        }
    }
    return false;
}

bool DFSCycleUndirected(Graph graph, int vertex, int parent, HashSet<int> visited)
{
    visited.Add(vertex);
    foreach (int neighbor in graph.GetNeighbors(vertex))
    {
        if (!visited.Contains(neighbor))
        {
            if (DFSCycleUndirected(graph, neighbor, vertex, visited))
                return true;
        }
        else if (neighbor != parent) // Visited and not parent → cycle!
        {
            return true;
        }
    }
    return false;
}
```

### In Directed Graph (using colors/states)

```csharp
bool HasCycleDirected(Graph graph)
{
    // 0 = white (unvisited), 1 = gray (in progress), 2 = black (done)
    Dictionary<int, int> color = new();
    foreach (int v in graph.GetVertices()) color[v] = 0;
    
    foreach (int vertex in graph.GetVertices())
    {
        if (color[vertex] == 0)
        {
            if (DFSCycleDirected(graph, vertex, color))
                return true;
        }
    }
    return false;
}

bool DFSCycleDirected(Graph graph, int vertex, Dictionary<int, int> color)
{
    color[vertex] = 1; // Mark as in-progress
    
    foreach (int neighbor in graph.GetNeighbors(vertex))
    {
        if (color[neighbor] == 1) return true;  // Back edge → cycle!
        if (color[neighbor] == 0 && DFSCycleDirected(graph, neighbor, color))
            return true;
    }
    
    color[vertex] = 2; // Mark as done
    return false;
}
```

---

## Topological Sort (DAG only)

Order vertices so that for every directed edge u → v, u comes before v.

```
Example: Course prerequisites
Math → Physics → Engineering
Math → CS → AI
English → CS

Topological order: English, Math, Physics, CS, Engineering, AI
(or: Math, English, Physics, CS, AI, Engineering — multiple valid orders)
```

### Using DFS

```csharp
List<int> TopologicalSort(Graph graph)
{
    HashSet<int> visited = new();
    Stack<int> stack = new();
    
    foreach (int vertex in graph.GetVertices())
    {
        if (!visited.Contains(vertex))
            TopSortDFS(graph, vertex, visited, stack);
    }
    
    return stack.ToList();
}

void TopSortDFS(Graph graph, int vertex, HashSet<int> visited, Stack<int> result)
{
    visited.Add(vertex);
    foreach (int neighbor in graph.GetNeighbors(vertex))
    {
        if (!visited.Contains(neighbor))
            TopSortDFS(graph, neighbor, visited, result);
    }
    result.Push(vertex); // Add AFTER processing all dependencies
}
```

### Using Kahn's Algorithm (BFS-based)

```csharp
List<int> TopologicalSortKahn(Graph graph)
{
    // Calculate in-degrees
    Dictionary<int, int> inDegree = new();
    foreach (int v in graph.GetVertices()) inDegree[v] = 0;
    
    foreach (int v in graph.GetVertices())
        foreach (int neighbor in graph.GetNeighbors(v))
            inDegree[neighbor]++;
    
    // Start with vertices having in-degree 0
    Queue<int> queue = new();
    foreach (var kvp in inDegree)
        if (kvp.Value == 0) queue.Enqueue(kvp.Key);
    
    List<int> result = new();
    while (queue.Count > 0)
    {
        int vertex = queue.Dequeue();
        result.Add(vertex);
        
        foreach (int neighbor in graph.GetNeighbors(vertex))
        {
            inDegree[neighbor]--;
            if (inDegree[neighbor] == 0)
                queue.Enqueue(neighbor);
        }
    }
    
    // If result doesn't contain all vertices → cycle exists!
    return result.Count == graph.VertexCount ? result : new List<int>();
}
```

---

## Connected Components

```csharp
// Find all connected components in undirected graph
List<List<int>> FindComponents(Graph graph)
{
    HashSet<int> visited = new();
    List<List<int>> components = new();
    
    foreach (int vertex in graph.GetVertices())
    {
        if (!visited.Contains(vertex))
        {
            List<int> component = new();
            DFS(graph, vertex, visited, component);
            components.Add(component);
        }
    }
    return components;
}
// Graph: {0-1, 1-2, 3-4}
// Components: [[0,1,2], [3,4]]
```

---

## Graph Algorithm Complexities

| Algorithm | Time | Space | Use Case |
|---|---|---|---|
| BFS | O(V + E) | O(V) | Shortest path (unweighted) |
| DFS | O(V + E) | O(V) | Cycle detection, topological sort |
| Topological Sort | O(V + E) | O(V) | Task scheduling, dependencies |
| Cycle Detection | O(V + E) | O(V) | Validation |
| Connected Components | O(V + E) | O(V) | Clustering |

---

## Key Takeaways

| Concept | Summary |
|---|---|
| Graph | Vertices + Edges (can be directed, weighted, cyclic) |
| Adjacency List | Most common representation — O(V+E) space |
| Adjacency Matrix | O(V²) space — fast edge lookup |
| BFS | Queue-based, level-by-level — shortest path |
| DFS | Stack/recursion — go deep first |
| Cycle Detection | DFS with parent tracking (undirected) or coloring (directed) |
| Topological Sort | Order respecting dependencies — only for DAGs |
| Connected Components | DFS/BFS on each unvisited vertex |

---

*Next Topic: Sorting Algorithms →*
