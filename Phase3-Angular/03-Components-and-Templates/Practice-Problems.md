# Topic 3: Components & Templates — Practice Problems

## Problem 1: Component Creation & Composition (Easy)
**Concept**: Creating components, using selectors, basic templates

### 1a. Greeting Card Component
Create `GreetingCardComponent` with properties:
- `recipientName: string`
- `message: string`
- `sender: string`

Template displays a styled card:
```
┌─────────────────────────┐
│  Dear Debanjan,          │
│                          │
│  Happy Birthday! 🎉     │
│                          │
│  From: Mentor            │
└─────────────────────────┘
```

### 1b. Product Card Component
Create `ProductCardComponent`:
- Properties: `name`, `price`, `imageUrl`, `rating` (1-5), `inStock` (boolean)
- Display stars based on rating (★★★☆☆)
- Show "In Stock" (green) or "Out of Stock" (red)
- Add to Cart button (disabled when out of stock)

### 1c. Navigation Bar
Create `NavBarComponent` with:
- App title on the left
- A list of navigation items: `{ label: string, link: string, active: boolean }[]`
- Highlight the active item
- Display the count of items

### 1d. Stats Dashboard
Create a `StatCardComponent` that shows a single stat:
- Properties: `label`, `value`, `icon` (emoji), `trend` ("up" | "down" | "flat")
- Green for up, red for down, gray for flat

Use 4 instances in a parent to build a dashboard:
```
[📦 Products: 142 ↑] [👥 Users: 2,841 ↑] [💰 Revenue: $48K ↓] [🛒 Orders: 89 →]
```

---

## Problem 2: Input/Output Communication (Easy-Medium)
**Concept**: @Input, @Output, EventEmitter, parent-child data flow

### 2a. Counter with Events
Create `CounterComponent`:
- `@Input() initialValue: number = 0`
- `@Input() step: number = 1`
- `@Input() min: number = 0`
- `@Input() max: number = 100`
- `@Output() valueChanged = new EventEmitter<number>()`

Parent uses it:
```html
<app-counter
  [initialValue]="5"
  [step]="2"
  [min]="0"
  [max]="20"
  (valueChanged)="onCounterChange($event)"
/>
<p>Parent received: {{ counterValue }}</p>
```

### 2b. Todo List with Parent-Child
Create two components:

**TodoItemComponent** (child):
- `@Input() task: { id: number; text: string; done: boolean }`
- `@Output() toggled = new EventEmitter<number>()`
- `@Output() removed = new EventEmitter<number>()`

**TodoListComponent** (parent):
- Manages the array of tasks
- Has an input field + Add button to add tasks
- Passes tasks to child components
- Listens for toggle/remove events

### 2c. Rating Component
Create a reusable `StarRatingComponent`:
- `@Input() rating: number = 0`
- `@Input() maxStars: number = 5`
- `@Input() readonly: boolean = false`
- `@Output() ratingChanged = new EventEmitter<number>()`

Display clickable stars (★/☆). When clicked, emit the new rating.

### 2d. Accordion Component
Create `AccordionComponent` and `AccordionItemComponent`:
- Accordion manages which item is open (only one at a time)
- AccordionItem has `title` input and projects content via `<ng-content>`
- Clicking a title toggles that section open/closed

```html
<app-accordion>
  <app-accordion-item title="Section 1">
    <p>Content for section 1...</p>
  </app-accordion-item>
  <app-accordion-item title="Section 2">
    <p>Content for section 2...</p>
  </app-accordion-item>
</app-accordion>
```

---

## Problem 3: Control Flow & Templates (Medium)
**Concept**: @if, @for, @switch, ng-template, ng-container

### 3a. User Table with Control Flow
Given an array of users:
```typescript
users = [
  { id: 1, name: 'Alice', role: 'admin', active: true },
  { id: 2, name: 'Bob', role: 'user', active: false },
  { id: 3, name: 'Charlie', role: 'editor', active: true },
  // ...more users
];
```

Build a table that:
- Uses `@for` to loop through users
- Uses `@if` to show "No users" when array is empty
- Uses `@switch` to display different badges per role
- Highlights even/odd rows differently
- Shows row numbers

### 3b. Conditional Templates
Create a component with three display modes: "grid", "list", "table"
- A toggle button group to switch modes
- Same data rendered differently based on mode
- Use `@switch` for mode selection

### 3c. Nested Loops
Display a school schedule:
```typescript
schedule = [
  { day: 'Monday', classes: ['Math', 'English', 'Science'] },
  { day: 'Tuesday', classes: ['History', 'Art', 'PE'] },
  // ...
];
```
Use nested `@for` loops to display the schedule as a formatted table.

### 3d. Deferred Loading
Create a `HeavyChartComponent` (simulated with setTimeout):
- Use `@defer (on viewport)` to lazy load it
- Show a placeholder until it enters the viewport
- Show a loading spinner during load
- Handle errors gracefully

---

## Problem 4: Content Projection & ViewChild (Medium-Hard)
**Concept**: ng-content, multi-slot projection, ViewChild, template refs

### 4a. Reusable Card with Slots
Create `CardComponent` with three projection slots:
```html
<app-card>
  <span card-title>My Card Title</span>
  <div card-body>
    <p>Card body content here...</p>
  </div>
  <div card-footer>
    <button>Save</button>
    <button>Cancel</button>
  </div>
</app-card>
```

The card should have styled header, body, and footer sections.

### 4b. Modal Component
Create `ModalComponent`:
- `@Input() isOpen: boolean`
- `@Output() closed = new EventEmitter<void>()`
- Multi-slot projection: title, body, actions
- Click backdrop or X button to close
- Prevent body scroll when open

### 4c. Form with ViewChild
Create a form with:
- Multiple input fields (name, email, age)
- A "Reset" button that clears all fields using `@ViewChild`
- A "Focus Name" button that focuses the name input
- Display character count for each field using template reference variables

### 4d. Tabs Component
Build a tabs system:
```html
<app-tabs>
  <app-tab title="Profile" [active]="true">
    <p>Profile content...</p>
  </app-tab>
  <app-tab title="Settings">
    <p>Settings content...</p>
  </app-tab>
  <app-tab title="Notifications" [badge]="3">
    <p>Notifications content...</p>
  </app-tab>
</app-tabs>
```
Use `@ContentChildren` to collect tab instances and manage active state.

---

## Problem 5: Complete Component Architecture (Hard)
**Concept**: Combine all component concepts in a real application

### Build a Kanban Board

Create a complete Kanban board with drag-and-drop-style task management.

**Components needed:**
```
KanbanBoardComponent (parent)
├── KanbanColumnComponent (3 columns: Todo, In Progress, Done)
│   ├── column header with task count
│   └── KanbanCardComponent (multiple per column)
│       ├── task title, description, priority badge
│       ├── assignee avatar
│       └── action buttons (move left/right, edit, delete)
└── TaskFormComponent (modal for creating/editing tasks)
```

**Features:**
1. Three columns: Todo, In Progress, Done
2. Cards can be moved between columns (left/right buttons)
3. Add new tasks via a modal form
4. Edit existing tasks
5. Delete tasks with confirmation
6. Task count per column
7. Priority badges (High=red, Medium=yellow, Low=green)
8. Empty state for columns with no tasks

**Data Model:**
```typescript
interface Task {
  id: number;
  title: string;
  description: string;
  priority: 'low' | 'medium' | 'high';
  status: 'todo' | 'in-progress' | 'done';
  assignee: string;
  createdAt: Date;
}
```

**Communication Pattern:**
- Board manages all tasks (single source of truth)
- Board passes filtered tasks to each Column via `@Input()`
- Cards emit events via `@Output()` for move/edit/delete
- Columns relay events up to Board
- Board updates the task array

**Expected Output:**
```
┌── Kanban Board ──────────────────────────────┐
│ [+ New Task]                                  │
│                                               │
│ ┌─ Todo (2) ──┐ ┌─ Doing (1) ─┐ ┌─ Done (1)─┐│
│ │┌───────────┐│ │┌───────────┐│ │┌──────────┐││
│ ││🔴 Setup   ││ ││🟡 Build   ││ ││🟢 Design │││
│ ││project    ││ ││components ││ ││mockups   │││
│ ││@Alice  [→]││ ││@Bob  [←][→]│ ││@Charlie[←]│││
│ │└───────────┘│ │└───────────┘│ │└──────────┘││
│ │┌───────────┐│ │             │ │            ││
│ ││🔴 Add     ││ │             │ │            ││
│ ││routing    ││ │             │ │            ││
│ ││@Alice  [→]││ │             │ │            ││
│ │└───────────┘│ │             │ │            ││
│ └─────────────┘ └─────────────┘ └────────────┘│
└───────────────────────────────────────────────┘
```

---

### Submission
- Create all components inside your Angular project
- Ensure `ng serve` compiles without errors
- Test all @Input/@Output communication
- Verify control flow (@if, @for, @switch) works correctly
- Tell me "check" when you're ready for review!
