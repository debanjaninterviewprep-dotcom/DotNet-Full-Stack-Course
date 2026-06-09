# Topic 7: Graphs (BFS, DFS) — Practice Problems

## Problem 1: Graph Basics (Easy)
**Concept**: Graph representation and basic traversal

### 1a. Build a Graph Class
Implement `Graph` using adjacency list with:
- `AddVertex(int v)`
- `AddEdge(int from, int to, bool directed = false)`
- `GetNeighbors(int v)`
- `HasEdge(int from, int to)`
- `RemoveEdge(int from, int to)`
- `Print()`

### 1b. Build This Graph and Print Adjacency List
```
    0 --- 1
    |     |
    2 --- 3 --- 4
```

### 1c. Implement BFS and DFS
Print traversal order for both starting from vertex 0.

**Expected Output:**
```
Adjacency List:
0 → [1, 2]
1 → [0, 3]
2 → [0, 3]
3 → [1, 2, 4]
4 → [3]

BFS from 0: 0, 1, 2, 3, 4
DFS from 0: 0, 1, 3, 2, 4 (may vary)
```

---

## Problem 2: BFS Applications (Easy-Medium)
**Concept**: Using BFS for shortest paths and level-order processing

### 2a. Shortest Path in Unweighted Graph
Find shortest distance from source to all vertices.
```
Graph: 0-1, 0-2, 1-3, 2-3, 3-4, 4-5
Source: 0
Output: {0:0, 1:1, 2:1, 3:2, 4:3, 5:4}
```

### 2b. Print Path Between Two Vertices
```
Source: 0, Target: 5
Output: 0 → 1 → 3 → 4 → 5 (shortest path)
```

### 2c. Check if Graph is Bipartite
A graph is bipartite if vertices can be colored with 2 colors such that no adjacent vertices share a color.
```
0 -- 1            0 -- 1
|    |     ✓      |    |    ✗
3 -- 2            3 -- 2
                  |  /
                  4
```
Use BFS with 2-coloring.

### 2d. Number of Islands
Given a 2D grid, count the number of islands ('1' = land, '0' = water).
```
Grid:
1 1 0 0 0
1 1 0 0 0
0 0 1 0 0
0 0 0 1 1
Output: 3 islands
```
Use BFS/DFS from each unvisited '1'.

---

## Problem 3: DFS Applications (Medium)
**Concept**: Using DFS for cycle detection and path finding

### 3a. Detect Cycle in Undirected Graph
```
Graph 1: 0-1, 1-2, 2-0     → Has cycle ✓
Graph 2: 0-1, 1-2, 2-3     → No cycle ✗
```

### 3b. Detect Cycle in Directed Graph
```
Graph 1: 0→1, 1→2, 2→0     → Has cycle ✓
Graph 2: 0→1, 1→2, 0→2     → No cycle ✗
```

### 3c. Find All Paths Between Two Vertices
```
Graph: 0→1, 0→2, 1→3, 2→3, 1→2
Source: 0, Target: 3
Output: [[0,1,3], [0,1,2,3], [0,2,3]]
```

### 3d. Connected Components
Find all connected components in an undirected graph.
```
Edges: 0-1, 1-2, 3-4, 5-6, 6-7
Components: [[0,1,2], [3,4], [5,6,7]]
```

### 3e. Count Connected Components
```
n = 5, edges = [[0,1], [1,2], [3,4]]
Output: 2 components ({0,1,2} and {3,4})
```

---

## Problem 4: Topological Sort & DAG Problems (Medium-Hard)
**Concept**: Processing directed acyclic graphs

### 4a. Course Schedule (Can Finish?)
There are `n` courses with prerequisites. Determine if you can finish all courses.
```
n = 4, prerequisites = [[1,0], [2,0], [3,1], [3,2]]
(Course 1 requires 0, Course 2 requires 0, Course 3 requires 1 and 2)
Output: true
Order: [0, 1, 2, 3] or [0, 2, 1, 3]
```

### 4b. Course Schedule II (Find Order)
Return the order to take all courses. Return empty if impossible.
```
n = 4, prerequisites = [[1,0], [2,0], [3,1], [3,2]]
Output: [0, 1, 2, 3] (or [0, 2, 1, 3])

n = 2, prerequisites = [[1,0], [0,1]]
Output: [] (impossible — circular dependency!)
```

### 4c. Task Scheduler with Dependencies
Given tasks and dependencies, find minimum time to complete all tasks (each takes 1 unit, independent tasks run in parallel).
```
Tasks: A, B, C, D, E
Dependencies: A→C, B→C, C→D, C→E
Time: 3 (Level 0: A,B | Level 1: C | Level 2: D,E)
```

### 4d. Alien Dictionary (Bonus — Hard)
Given a sorted list of words in an alien language, derive the character ordering.
```
Input: ["wrt", "wrf", "er", "ett", "rftt"]
Output: "wertf"

Reasoning: w < e (from "wrt" vs "er"), r < t (from "wrf" vs "wrt"? No...)
Actually: t < f (wrt vs wrf), w < e (wrt vs er), r < t (er vs ett), e < r (ett vs rftt)
Order: w → e → r → t → f
```

---

## Problem 5: Graph Challenge (Hard)
**Concept**: Combine BFS, DFS, and graph theory

### Maze Solver

Build a maze solver that:
1. Reads a maze from a 2D grid ('#' = wall, '.' = path, 'S' = start, 'E' = end)
2. Finds **shortest path** using BFS
3. Finds **all paths** using DFS
4. Visualizes the solution path

**Input Maze:**
```
# # # # # # # # # #
# S . . # . . . . #
# . # . # . # # . #
# . # . . . . . . #
# . # # # # . # . #
# . . . . . . # E #
# # # # # # # # # #
```

**Expected Output:**
```
=== Maze Solver ===

Shortest Path Length: 14
Shortest Path:
# # # # # # # # # #
# * * . # . . . . #
# . # * # . # # . #
# . # * * * . . . #
# . # # # # * # . #
# . . . . . * # * #
# # # # # # # # # #

Total Paths Found: 4
BFS visited 28 cells
DFS visited 35 cells
```

**Requirements:**
- Read maze, identify start (S) and end (E)
- BFS implementation that tracks the path
- DFS that counts all possible paths
- Print the maze with the shortest path marked as `*`
- Handle edge cases: no path exists, start = end

---

### Submission
- Create a new console project: `dotnet new console -n GraphsPractice`
- Solve all problems
- Comment each solution with **Time: O(?), Space: O(?)**
- Test with different graph structures: sparse, dense, disconnected
- Tell me "check" when you're ready for review!
