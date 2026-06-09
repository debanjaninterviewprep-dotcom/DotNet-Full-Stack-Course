# Topic 9: Pipes & Custom Pipes — Practice Problems

## Problem 1: Built-in Pipes (Easy)
**Concept**: Using Angular's built-in pipes for data formatting

### 1a. Data Formatter Component
Create a component that displays the same data in multiple formats:
```typescript
data = {
  name: 'debanjan das',
  salary: 85000,
  joinDate: new Date(2023, 5, 15),
  score: 0.9245,
  bio: 'Full stack developer with expertise in Angular, .NET, and cloud technologies. Passionate about clean code and testing.'
};
```

Display:
```
Name:      Debanjan Das (titlecase)
Salary:    $85,000.00 (currency)
           ₹85,000.00 (INR)
           €85,000.00 (EUR)
Joined:    June 15, 2023 (longDate)
           06/15/2023 (custom)
           2 years ago (custom pipe)
Score:     92.45% (percent)
           0.92 (number:'1.0-2')
Bio:       Full stack developer with... (truncate:40)
```

### 1b. Product Table with Pipes
Display a product list using pipes:
```
| Product       | Price    | Added       | Rating |
|---------------|----------|-------------|--------|
| ANGULAR BOOK  | $49.99   | Apr 11, 2026| 93%    |
| TYPESCRIPT MUG| $14.99   | Mar 25, 2026| 87%    |
```
Use: uppercase, currency, date, percent pipes.

### 1c. JSON Debug Panel
Create a collapsible debug panel using `json` pipe:
- Show/hide button
- Displays component state as formatted JSON
- Useful for development debugging

### 1d. Async Pipe with Timer
Create a component with:
- `Observable<Date>` that emits current time every second
- Display using async pipe + date pipe: `{{ time$ | async | date:'mediumTime' }}`
- Observable counter that increments every second

---

## Problem 2: Custom Utility Pipes (Easy-Medium)
**Concept**: Creating custom pipes for common transformations

### 2a. Truncate Pipe
```typescript
// {{ text | truncate:50:'...' }}
// 'This is a very long text...' → 'This is a very long t...'
```
Parameters: limit (default 100), trail (default '...')

### 2b. Time Ago Pipe
```typescript
// {{ date | timeAgo }}
// → 'just now', '5 minutes ago', '2 hours ago', '3 days ago', '1 month ago'
```
Handle: seconds, minutes, hours, days, months, years.

### 2c. File Size Pipe
```typescript
// {{ bytes | fileSize }}
// 1024 → '1 KB', 1048576 → '1 MB', 1073741824 → '1 GB'
```

### 2d. Initials Pipe
```typescript
// {{ 'Debanjan Das' | initials }}      → 'DD'
// {{ 'John Michael Smith' | initials }} → 'JMS'
// {{ 'debanjan' | initials }}           → 'D'
```

### 2e. Ordinal Pipe
```typescript
// {{ 1 | ordinal }} → '1st'
// {{ 2 | ordinal }} → '2nd'
// {{ 3 | ordinal }} → '3rd'
// {{ 11 | ordinal }} → '11th'
// {{ 21 | ordinal }} → '21st'
```

---

## Problem 3: Data Transformation Pipes (Medium)
**Concept**: Pipes for filtering, sorting, and transforming collections

### 3a. Filter Pipe
```typescript
// {{ users | filter:'role':'admin' }}
// Filters array where item.role === 'admin'
```
Make it generic — works with any field name and value.

### 3b. Sort Pipe
```typescript
// {{ users | sort:'name':'asc' }}
// {{ products | sort:'price':'desc' }}
```
Support strings, numbers, and dates.

### 3c. Search/Highlight Pipe
Create two pipes:
```typescript
// searchFilter — filter items matching search text
// {{ items | searchFilter:searchText:'name' }}

// highlight — highlight matching text in results
// {{ item.name | highlight:searchText }}
// 'Angular Framework' with search 'ang' → '<mark>Ang</mark>ular Framework'
```

### 3d. Group By Pipe
```typescript
// {{ items | groupBy:'category' }}
// Input: [{ name: 'A', category: 'tech' }, { name: 'B', category: 'science' }, ...]
// Output: { tech: [...], science: [...] }
```
Use with `keyvalue` pipe to iterate groups.

---

## Problem 4: Advanced Pipes (Medium-Hard)
**Concept**: Impure pipes, parameterized pipes, pipes in services

### 4a. Safe HTML Pipe
Create a pipe that bypasses Angular's sanitization for trusted HTML:
```typescript
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';

@Pipe({ name: 'safeHtml', standalone: true })
export class SafeHtmlPipe implements PipeTransform {
  constructor(private sanitizer: DomSanitizer) {}
  
  transform(value: string): SafeHtml {
    return this.sanitizer.bypassSecurityTrustHtml(value);
  }
}
```
Use it to render rich text content: `<div [innerHTML]="content | safeHtml"></div>`

### 4b. Pluralize Pipe
```typescript
// {{ count | pluralize:'item' }}
// 0 → 'no items', 1 → '1 item', 5 → '5 items'

// {{ count | pluralize:'person':'people' }}
// 0 → 'no people', 1 → '1 person', 5 → '5 people'
```

### 4c. Mask Pipe
```typescript
// {{ '4111111111111111' | mask:4 }}  → '************1111'
// {{ 'debanjan@test.com' | mask:3:'email' }} → 'deb*****@test.com'
// {{ '9876543210' | mask:4:'phone' }} → '******3210'
```

### 4d. Relative URL Pipe
```typescript
// {{ '/api/users/42/avatar' | absoluteUrl }}
// → 'https://api.example.com/api/users/42/avatar'
// Prepends the environment's API URL
```

---

## Problem 5: Comprehensive Pipe Challenge (Hard)
**Concept**: Combine multiple custom pipes in a real application

### Build a Social Media Feed

Create a social media-like feed that uses numerous pipes:

**Custom Pipes to Create:**
1. `timeAgo` — relative timestamps
2. `truncate` — shorten long posts
3. `highlight` — highlight search terms
4. `linkify` — convert URLs to clickable links
5. `mention` — convert @username to styled mentions
6. `hashtag` — convert #tags to styled hashtags
7. `fileSize` — for attachment sizes
8. `pluralize` — "X likes", "X comments"
9. `readingTime` — estimate reading time from word count

**Components:**

### 5a. Post Card Component
```html
<div class="post">
  <div class="header">
    <span class="avatar">{{ post.author | initials }}</span>
    <span class="name">{{ post.author | titlecase }}</span>
    <span class="time">{{ post.createdAt | timeAgo }}</span>
  </div>
  
  <div class="content">
    <p [innerHTML]="post.content | linkify | mention | hashtag | highlight:searchTerm"></p>
    <span class="reading-time">{{ post.content | readingTime }}</span>
  </div>

  @if (post.attachment) {
    <div class="attachment">
      📎 {{ post.attachment.name }} ({{ post.attachment.size | fileSize }})
    </div>
  }
  
  <div class="stats">
    {{ post.likes | pluralize:'like' }} · {{ post.comments.length | pluralize:'comment' }}
  </div>
</div>
```

### 5b. Search with Highlighting
- Search input filters posts
- Matching text highlighted in results using `highlight` pipe
- Post count: "Showing X of Y posts"

### 5c. Feed Filters
- Sort by: newest, oldest, most liked
- Filter by: all, with attachments, with mentions
- Use `filter` and `sort` pipes with pipe chaining

### 5d. Stats Dashboard
Display feed statistics using pipes:
```
── Feed Stats ──
Total Posts: 42
Total Likes: 1,234 (number pipe)
Most Active Author: Debanjan Das (titlecase)
Last Post: 3 hours ago (timeAgo)
Total Attachments: 15.7 MB (fileSize)
Avg Reading Time: 3 min (readingTime)
```

**Expected Output:**
```
┌─────────────────────────────────────────────┐
│ DD  Debanjan Das · 3 hours ago              │
│                                              │
│ Just finished the Angular pipes topic! 🎉    │
│ Check out the docs at https://angular.dev    │
│ @alice what do you think?                    │
│ #angular #typescript #learning               │
│                                              │
│ 📎 notes.pdf (2.4 MB)                       │
│ 📖 2 min read                                │
│                                              │
│ 12 likes · 3 comments                        │
│ [❤️ Like] [💬 Comment] [🔗 Share]            │
├─────────────────────────────────────────────┤
│ AS  Alice Smith · 2 days ago                 │
│                                              │
│ Building a new project with <mark>Angular</mark>│
│ signals. The API is much cleaner...          │
│ [Read more]                                  │
│                                              │
│ 8 likes · 1 comment                          │
└─────────────────────────────────────────────┘

Search: [angular____] → Showing 2 of 10 posts
```

---

### Submission
- Create all custom pipes in your Angular project
- Use both built-in and custom pipes together
- Test pure vs impure behavior
- Chain multiple pipes
- Tell me "check" when you're ready for review!
