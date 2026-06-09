# Topic 7: Reactive Forms & Template-Driven Forms — Practice Problems

## Problem 1: Template-Driven Forms (Easy)
**Concept**: ngModel, template validation, form submission

### 1a. Login Form
Create a login form using template-driven approach:
- Email field (required, email format)
- Password field (required, min 6 characters)
- "Remember me" checkbox
- Submit button (disabled when invalid)
- Show validation errors only after field is touched
- Display submitted data below the form

### 1b. Contact Form
Build a contact form:
- Name (required, min 2 chars)
- Email (required, valid email)
- Subject dropdown (required): "General", "Support", "Billing", "Feedback"
- Message textarea (required, min 10 chars, max 500 chars)
- Character counter for message
- Reset button
- Show success message after submission

### 1c. Profile Editor
Create a profile form with two-way binding:
- Display a "live preview" card that updates as user types
- Fields: name, bio, website, avatar URL
- Avatar URL updates an `<img>` preview in real-time
- Bio shows character count (max 200)

### 1d. Simple Survey
Build a survey with:
- Rating (radio buttons 1-5)
- "Would you recommend?" (Yes/No radio)
- Feedback textarea (required if rating < 3)
- Form submission shows a summary

---

## Problem 2: Reactive Forms Basics (Easy-Medium)
**Concept**: FormGroup, FormControl, FormBuilder, Validators

### 2a. Registration Form
Build using reactive approach:
```typescript
registrationForm = this.fb.group({
  firstName: ['', [Validators.required, Validators.minLength(2)]],
  lastName: ['', Validators.required],
  email: ['', [Validators.required, Validators.email]],
  phone: ['', Validators.pattern(/^\d{10}$/)],
  password: ['', [Validators.required, Validators.minLength(8)]],
  confirmPassword: ['', Validators.required],
  dateOfBirth: ['', Validators.required],
  gender: ['', Validators.required],
  agreeToTerms: [false, Validators.requiredTrue]
});
```
- Show inline errors for each field
- Password strength indicator (weak/medium/strong based on complexity)
- Disable submit until valid
- Show form summary on submit

### 2b. Nested Address Form
Create a form with nested FormGroup for addresses:
```typescript
orderForm = this.fb.group({
  name: ['', Validators.required],
  email: ['', [Validators.required, Validators.email]],
  shippingAddress: this.fb.group({
    street: ['', Validators.required],
    city: ['', Validators.required],
    state: ['', Validators.required],
    zip: ['', [Validators.required, Validators.pattern(/^\d{5}$/)]]
  }),
  billingAddress: this.fb.group({
    street: [''], city: [''], state: [''], zip: ['']
  }),
  sameAsShipping: [true]
});
```
When "Same as shipping" is checked, copy shipping address to billing and disable billing fields.

### 2c. setValue vs patchValue
Create a form and demonstrate:
- `setValue()` — must provide ALL fields
- `patchValue()` — can provide partial fields
- `reset()` — with and without default values
- Buttons: "Fill Sample Data", "Clear Form", "Partial Update"

### 2d. Value & Status Changes
Create a form that reacts to changes:
```typescript
this.form.get('email')!.valueChanges.subscribe(value => {
  console.log('Email changed:', value);
});

this.form.statusChanges.subscribe(status => {
  console.log('Form status:', status);  // VALID, INVALID, PENDING
});
```
Display a live log of all form changes.

---

## Problem 3: Custom Validation (Medium)
**Concept**: Custom validators, cross-field validation, async validators

### 3a. Custom Validators
Create and apply these validators:
```typescript
// 1. noWhitespace — no leading/trailing spaces
// 2. strongPassword — min 1 uppercase, 1 lowercase, 1 number, 1 special char
// 3. validAge — must be 18-120
// 4. noRepeatingChars — no more than 3 consecutive same chars
// 5. validUrl — must start with http:// or https://
```

### 3b. Cross-Field Validation
Implement:
```typescript
// 1. passwordMatch — password === confirmPassword
// 2. dateRange — startDate < endDate
// 3. conditionalRequired — if "Other" selected, "specify" field required
```
Create a form that tests all three.

### 3c. Async Validator — Username Availability
Simulate checking if a username is taken:
```typescript
function usernameAvailable(userService: UserService): AsyncValidatorFn {
  return (control: AbstractControl) => {
    return timer(500).pipe(  // Debounce
      switchMap(() => userService.checkUsername(control.value)),
      map(taken => taken ? { usernameTaken: true } : null)
    );
  };
}
```
- Show spinner while checking
- Show ✓ when available, ✗ when taken

### 3d. Error Message Component
Build a reusable `ValidationErrorComponent`:
```html
<app-validation-error [control]="form.get('email')" label="Email" />
```
It automatically displays the appropriate error message based on the error type:
- required → "Email is required"
- email → "Email format is invalid"
- minlength → "Email must be at least X characters"
- custom errors → configurable messages

---

## Problem 4: FormArray & Dynamic Forms (Medium-Hard)
**Concept**: Dynamic fields, add/remove, complex forms

### 4a. Skills Manager
Build a form with a dynamic skills list:
- Input + "Add Skill" button
- Each skill shows with a "Remove" button
- Minimum 1 skill required
- Maximum 10 skills
- No duplicate skills allowed
- Drag-to-reorder (move up/down buttons)

### 4b. Invoice Builder
Create a dynamic invoice form:
```typescript
invoiceForm = this.fb.group({
  clientName: ['', Validators.required],
  invoiceDate: ['', Validators.required],
  items: this.fb.array([])  // Dynamic line items
});

// Each item:
// { description: string, quantity: number, unitPrice: number }
```

Features:
- "Add Line Item" button
- Each row: description, quantity, unit price, calculated total
- Remove button per row
- Running subtotal, tax (configurable %), and grand total
- At least 1 item required

### 4c. Multi-Step Form (Wizard)
Build a 3-step registration wizard:
```
Step 1: Personal Info   Step 2: Address    Step 3: Review & Submit
[First Name]            [Street]           Summary of all data
[Last Name]             [City]             [Edit] buttons per section
[Email]                 [State]            [Submit] button
[Phone]                 [Zip]
[Next →]                [← Back] [Next →]  [← Back] [Submit]
```
- Each step validates before proceeding
- "Back" preserves entered data
- Review step shows all data
- Progress indicator (Step 1 of 3)

### 4d. Dynamic Form from Config
Build a form generator that creates forms from JSON config:
```typescript
const formConfig: FieldConfig[] = [
  { key: 'name', label: 'Full Name', type: 'text', required: true },
  { key: 'email', label: 'Email', type: 'email', required: true, validators: ['email'] },
  { key: 'age', label: 'Age', type: 'number', validators: ['min:18', 'max:120'] },
  { key: 'role', label: 'Role', type: 'select', options: ['Developer', 'Designer', 'Manager'] },
  { key: 'skills', label: 'Skills', type: 'checkbox-group', options: ['Angular', 'React', 'Vue', 'Node'] },
  { key: 'bio', label: 'About You', type: 'textarea', maxLength: 500 }
];
```
The component should render the correct input type and validators for each field.

---

## Problem 5: Complete Form Application (Hard)
**Concept**: Combine all form techniques in a real application

### Build a Job Application Portal

**Pages:**

### 5a. Job Application Form
Multi-step form with:

**Step 1 — Personal Information:**
- Name, email, phone (with validation)
- Date of birth (must be 18+), gender
- Profile photo URL (optional)

**Step 2 — Education (FormArray):**
- Dynamic list of education entries
- Each: degree, institution, year, GPA
- At least 1 entry required
- Add/remove education entries

**Step 3 — Work Experience (FormArray):**
- Dynamic list of work history
- Each: company, role, startDate, endDate, current (checkbox)
- If "current" checked → endDate disabled
- Date range validation (start < end)
- Optional section

**Step 4 — Skills & Preferences:**
- Skills (FormArray — dynamic tags)
- Preferred locations (checkbox group)
- Salary expectation (range slider)
- Availability dropdown
- Cover letter (textarea, 100-1000 chars)

**Step 5 — Review & Submit:**
- Display complete summary
- Edit buttons for each section
- Terms checkbox (requiredTrue)
- Submit button

**Validation:**
- Each step validates independently
- Cross-field: confirm email matches email
- Async: check if email is already registered
- Custom: strong password, valid phone format

**Expected Output:**
```
═══ Job Application ═══

[Step 1: Personal ✓] → [Step 2: Education ✓] → [Step 3: Experience] → [Step 4: Skills] → [Step 5: Review]

── Step 3: Work Experience ──

┌─ Experience 1 ──────────────────┐
│ Company:   [Microsoft       ]    │
│ Role:      [Software Engineer]   │
│ Start:     [2022-01-15      ]   │
│ End:       [                ] ☑ Current│
│                     [Remove]    │
└──────────────────────────────────┘

[+ Add Experience]

[← Back]                    [Next →]

Progress: ███████░░░░ 60%
```

---

### Submission
- Build all forms in your Angular project
- Use template-driven for simple forms (Problem 1)
- Use reactive for everything else
- Test all validations (valid + invalid states)
- Verify FormArrays (add/remove) work correctly
- Tell me "check" when you're ready for review!
