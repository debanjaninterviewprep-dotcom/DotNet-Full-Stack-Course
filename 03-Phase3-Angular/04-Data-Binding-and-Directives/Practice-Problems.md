# Topic 4: Data Binding & Directives — Practice Problems

## Problem 1: Data Binding Basics (Easy)
**Concept**: Interpolation, property binding, event binding

### 1a. Profile Display
Create a component with these properties:
```typescript
fullName = 'Debanjan Das';
jobTitle = 'Full Stack Developer';
avatarUrl = 'https://via.placeholder.com/150';
bio = 'Passionate about building scalable web applications.';
yearsOfExperience = 3;
isAvailableForHire = true;
```
Display them using:
- Interpolation for text
- Property binding for `[src]`, `[alt]`, `[class.available]`
- Conditional text based on `isAvailableForHire`

### 1b. Dynamic Button States
Create a form-like component with:
- An input field that tracks character count
- A submit button that is `[disabled]` when input is empty or over 100 chars
- A character counter that turns red when over 80 chars using `[style.color]`
- A clear button that resets the input using `(click)`

### 1c. Image Gallery
Create a simple gallery with:
- An array of image URLs
- "Previous" and "Next" buttons
- Display current image using `[src]` binding
- Show "Image X of Y" using interpolation
- Disable "Previous" on first and "Next" on last image

### 1d. Event Tracker
Create a component that tracks and displays:
- Click count (on a button)
- Mouse position (x, y) — track on a div using `(mousemove)`
- Key presses — track on an input using `(keyup)`
- Show the last 5 keys pressed

---

## Problem 2: Two-Way Binding & ngModel (Easy-Medium)
**Concept**: [(ngModel)], FormsModule, real-time sync

### 2a. Live Preview Editor
Build a component with:
- Text input for heading → displays as `<h1>` in a preview
- Textarea for body → displays as `<p>` in a preview
- Color picker → changes the preview background color
- Font size slider (range input) → changes preview font size
- All using `[(ngModel)]` for real-time updates

### 2b. Unit Converter
Build converters (all with live two-way binding):
- Celsius ↔ Fahrenheit
- Kilometers ↔ Miles
- Kilograms ↔ Pounds

When you type in either field, the other updates immediately.

### 2c. Search & Filter
Given an array of products:
```typescript
products = [
  { name: 'Angular T-Shirt', price: 29.99, category: 'clothing' },
  { name: 'TypeScript Mug', price: 14.99, category: 'accessories' },
  // ...10 more items
];
```
Create:
- A search input bound with `[(ngModel)]`
- A category dropdown bound with `[(ngModel)]`
- A price range slider bound with `[(ngModel)]`
- Filtered results display that updates in real-time

### 2d. Custom Two-Way Binding
Create a `ToggleSwitchComponent` with:
- `@Input() checked: boolean`
- `@Output() checkedChange = new EventEmitter<boolean>()`
- Styled as a toggle switch (on/off)
- Parent uses: `<app-toggle-switch [(checked)]="isDarkMode" />`

---

## Problem 3: ngClass & ngStyle (Medium)
**Concept**: Dynamic class and style binding

### 3a. Priority Badge Component
Create a `PriorityBadgeComponent` that:
- Accepts a `priority` input: 'critical' | 'high' | 'medium' | 'low'
- Uses `[ngClass]` to apply different color classes:
  - critical → red background, white text
  - high → orange background
  - medium → yellow background
  - low → green background

### 3b. Progress Bar
Create a `ProgressBarComponent`:
- `@Input() value: number` (0-100)
- `@Input() color: string` (optional)
- Use `[ngStyle]` for: width percentage, background color
- Use `[ngClass]` for: animation class when value > 0
- Change color automatically: green (0-33), yellow (34-66), red (67-100)

### 3c. Data Table with Styling
Build a sortable data table:
- Click column headers to sort
- Active sort column highlighted with `[ngClass]`
- Sort direction arrow (↑/↓)
- Alternating row colors
- Hover highlight on rows
- Selected row with different background

### 3d. Theme Switcher
Build a theme switcher component:
- Toggle between light/dark mode
- Use `[ngClass]` on the root container to apply theme classes
- Use `[ngStyle]` for custom color picker
- Allow primary, secondary, and accent color customization
- Preview all changes in real-time

---

## Problem 4: Custom Directives (Medium-Hard)
**Concept**: Building reusable attribute and structural directives

### 4a. Tooltip Directive
Create `appTooltip`:
```html
<button [appTooltip]="'Click to save your changes'" tooltipPosition="top">
  Save
</button>
```
- Shows tooltip on hover
- Supports positions: top, bottom, left, right
- Disappears on mouse leave
- Styled with CSS

### 4b. Debounce Click Directive
Create `appDebounceClick`:
```html
<button (appDebounceClick)="onSave()" [debounceTime]="500">
  Save (prevents double-click)
</button>
```
- Prevents multiple rapid clicks
- Only fires the event after the specified debounce time
- Useful for preventing double form submissions

### 4c. Permission Directive (Structural)
Create `*appHasPermission`:
```html
<button *appHasPermission="'admin'">Delete All Users</button>
<div *appHasPermission="'editor'">Edit Content</div>
<span *appHasPermission="'user'">View Profile</span>
```
- Takes a role string
- Shows/hides element based on current user's role
- Works like `*ngIf` but checks permissions

### 4d. Lazy Load Image Directive
Create `appLazyLoad`:
```html
<img [appLazyLoad]="actualImageUrl" placeholder="assets/placeholder.jpg" />
```
- Shows placeholder image initially
- Uses IntersectionObserver to detect when image is in viewport
- Loads actual image when visible
- Shows loading animation during load

---

## Problem 5: Comprehensive Binding Challenge (Hard)
**Concept**: Combine all data binding and directive concepts

### Build a Dashboard Analytics Page

Create a complete analytics dashboard with:

**Components:**
1. `MetricCardComponent` — shows a metric with trend
2. `ChartComponent` — shows a bar chart (CSS-only, no library)
3. `DataTableComponent` — sortable, filterable table
4. `FilterPanelComponent` — date range, category, search

**Features:**

### 5a. Metric Cards Row
Display 4 metric cards using dynamic binding:
```
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ Revenue  │ │ Users    │ │ Orders   │ │ Rating   │
│ $48,500  │ │ 2,841    │ │ 432      │ │ 4.7 ★    │
│ ↑ +12.5% │ │ ↑ +8.3%  │ │ ↓ -2.1%  │ │ → +0.0%  │
└──────────┘ └──────────┘ └──────────┘ └──────────┘
```
- Use `[ngClass]` for trend colors (green/red/gray)
- Use `[ngStyle]` for dynamic bar widths

### 5b. CSS Bar Chart
Build a bar chart using only CSS and Angular bindings:
- `[style.height.%]` for bar heights
- `[ngClass]` for bar colors based on value
- `[appTooltip]` (your custom directive!) for showing exact values on hover
- Animate bars on appearance

### 5c. Interactive Data Table
Sortable table with:
- Column headers that toggle sort via `(click)`
- Sort indicator via `[ngClass]`
- Row selection via `(click)` and `[class.selected]`
- Inline editing via `[(ngModel)]` on double-click
- Custom `appHighlight` directive on hover

### 5d. Filter Panel with Two-Way Binding
- Search input with `[(ngModel)]` that filters the table
- Category dropdown with `[(ngModel)]`
- Date range inputs
-  "Active only" toggle using your custom `ToggleSwitchComponent` with `[(checked)]`
- All filters update the table in real-time

**Expected Output:**
```
═══ Analytics Dashboard ═══

[Revenue: $48,500 ↑12.5%] [Users: 2,841 ↑8.3%] [Orders: 432 ↓2.1%]

── Bar Chart ──
  ████████████████████  Jan ($8,200)
  ██████████████████    Feb ($7,100)
  ████████████████████████  Mar ($9,800)
  
── Filters ──
Search: [________]  Category: [All ▼]  Active Only: [ON]

── Table ──
| ID ↑ | Name      | Sales  | Status   |
|------|-----------|--------|----------|
| 1    | Product A | $1,200 | ● Active |
| 2    | Product B | $890   | ● Active |
| 3    | Product C | $2,100 | ○ Paused |
```

---

### Submission
- Implement all problems in your Angular project
- Ensure all data bindings work correctly
- Test custom directives in various scenarios
- Verify two-way binding updates in real-time
- Tell me "check" when you're ready for review!
