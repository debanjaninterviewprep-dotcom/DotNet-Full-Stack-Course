# Topic 2: Angular Setup & Architecture — Practice Problems

## Problem 1: Project Setup & Exploration (Easy)
**Concept**: Angular CLI, project structure

### 1a. Create an Angular Project
```bash
ng new task-manager --style=css --ssr=false
cd task-manager
ng serve
```
Open `http://localhost:4200` and verify the default page loads.

### 1b. Explore the Project Structure
Open each file and write a brief comment explaining its purpose:
- `main.ts`
- `app.config.ts`
- `app.routes.ts`
- `app.component.ts`
- `angular.json`
- `tsconfig.json`
- `package.json`

### 1c. Generate Components
Use the CLI to generate:
```bash
ng g c components/header
ng g c components/footer
ng g c components/sidebar
ng g c pages/home
ng g c pages/about
```
Verify the files are created. Note what files are generated for each component.

### 1d. Modify the Root Component
Update `app.component.html` to use your new components:
```html
<app-header />
<main>
  <app-sidebar />
  <section>
    <h1>Welcome to Task Manager</h1>
  </section>
</main>
<app-footer />
```
Make sure to import the components in `app.component.ts`.

**Expected Output:** A page showing Header, Sidebar, main content, and Footer.

---

## Problem 2: Component Basics (Easy-Medium)
**Concept**: Creating and composing components

### 2a. Header Component
Create a header with:
- App logo/title on the left
- Navigation links on the right (Home, Tasks, About)
- Current date displayed

### 2b. Footer Component
Create a footer with:
- Copyright text with current year (calculated dynamically)
- Version number from a component property

### 2c. Profile Card Component
Create `ProfileCardComponent` that displays:
- Name, email, role, avatar placeholder
- All data from component properties (hardcoded for now)

### 2d. Counter Component
Create a simple counter with:
- A displayed number (starts at 0)
- Increment (+) and Decrement (-) buttons
- A Reset button

```
Expected: [−] 5 [+] [Reset]
```

---

## Problem 3: Lifecycle Hooks (Medium)
**Concept**: Understanding when lifecycle hooks fire

### 3a. Lifecycle Logger Component
Create a component that logs every lifecycle hook to the console:
```typescript
// Log: "Constructor called", "ngOnInit called", "ngOnDestroy called", etc.
```
Add a button in the parent to show/hide this component. Observe:
- Which hooks fire when component is created?
- Which hooks fire when component is destroyed?

### 3b. Timer Component with Cleanup
Create a component that:
- Starts a counter that increments every second (using `setInterval`)
- Displays the elapsed seconds
- Properly cleans up the interval in `ngOnDestroy`

Toggle the component on/off and verify no memory leaks (no extra intervals running).

### 3c. Data Loading Pattern
Create a component that simulates data loading:
```typescript
export class DataLoaderComponent implements OnInit {
  data: string[] = [];
  isLoading = true;
  
  ngOnInit(): void {
    // Simulate API call with setTimeout
    setTimeout(() => {
      this.data = ['Item 1', 'Item 2', 'Item 3'];
      this.isLoading = false;
    }, 2000);
  }
}
```
Show a loading spinner while `isLoading` is true, then show the data.

---

## Problem 4: Standalone Architecture (Medium-Hard)
**Concept**: Standalone components, configuration, project organization

### 4a. Feature-Based Structure
Reorganize your project into features:
```
src/app/
├── core/              ← Singleton services, guards
│   └── services/
├── shared/            ← Reusable components, pipes, directives
│   └── components/
│       ├── header/
│       └── footer/
├── features/          ← Feature areas
│   ├── home/
│   ├── tasks/
│   └── about/
├── models/            ← Interfaces and types
├── app.component.ts
├── app.config.ts
└── app.routes.ts
```

### 4b. Create Models
Define TypeScript interfaces:
```typescript
// models/task.model.ts
export interface Task {
  id: number;
  title: string;
  description: string;
  status: 'todo' | 'in-progress' | 'done';
  priority: 'low' | 'medium' | 'high';
  createdAt: Date;
  dueDate?: Date;
}
```

### 4c. Environment Configuration
Set up `environment.ts` with:
```typescript
export const environment = {
  production: false,
  apiUrl: 'http://localhost:3000/api',
  appName: 'Task Manager',
  version: '1.0.0'
};
```
Use the environment values in your header (app name) and footer (version).

### 4d. Build and Inspect
- Run `ng build` and inspect the `dist/` folder
- Note the file sizes
- Run `ng build --configuration=production` and compare sizes
- Document the differences

---

## Problem 5: Architecture Challenge (Hard)
**Concept**: Design a well-architected Angular application from scratch

### Plan a Task Management Application

Design the complete architecture for a Task Manager app. Don't implement everything yet — just create the structure, interfaces, and placeholder components.

**Requirements:**
1. User can view, create, edit, delete tasks
2. Tasks have: title, description, status, priority, due date, assignee
3. Filter tasks by status and priority
4. Dashboard with task statistics
5. User profile page

**Deliverables:**

### 5a. Component Tree Diagram
Draw (as comments in a file) the component hierarchy:
```
AppComponent
├── HeaderComponent (app title, navigation, user avatar)
├── RouterOutlet
│   ├── DashboardPage
│   │   ├── TaskStatsComponent
│   │   └── RecentTasksComponent
│   ├── TaskListPage
│   │   ├── TaskFilterComponent
│   │   └── TaskCardComponent (repeated)
│   ├── TaskDetailPage
│   ├── TaskCreatePage
│   │   └── TaskFormComponent
│   └── ProfilePage
└── FooterComponent
```

### 5b. Generate All Components
Use `ng generate` to create every component, service, and model listed above.

### 5c. Define All Interfaces
Create complete TypeScript interfaces for:
- `Task`, `User`, `TaskFilter`, `TaskStats`, `CreateTaskDto`, `UpdateTaskDto`

### 5d. Create a Mock Service
Build `TaskService` with hardcoded data:
```typescript
@Injectable({ providedIn: 'root' })
export class TaskService {
  private tasks: Task[] = [/* 5-10 mock tasks */];
  
  getAllTasks(): Task[] { ... }
  getTaskById(id: number): Task | undefined { ... }
  getTasksByStatus(status: string): Task[] { ... }
  getTaskStats(): TaskStats { ... }
}
```
Inject it into components and display mock data.

**Expected Output:**
```
=== Task Manager ===
[Header: Task Manager | Dashboard | Tasks | Profile]

Dashboard:
  Total Tasks: 8
  Todo: 3 | In Progress: 3 | Done: 2
  High Priority: 2

Recent Tasks:
  ✅ Setup Angular project (Done)
  🔄 Create components (In Progress)
  📋 Add routing (Todo)

[Footer: Task Manager v1.0.0 | © 2026]
```

---

### Submission
- Create the Angular project: `ng new task-manager`
- Complete all 5 problems
- Make sure `ng serve` runs without errors
- Take screenshots of the running app
- Tell me "check" when you're ready for review!
