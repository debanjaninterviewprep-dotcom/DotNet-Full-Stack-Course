# Topic 7: Reactive Forms & Template-Driven Forms

## Two Approaches to Forms

Angular provides two ways to build forms:

| Feature | Template-Driven | Reactive |
|---|---|---|
| Logic location | Template (HTML) | Component (TypeScript) |
| Directive | `ngModel` | `formControl`, `formGroup` |
| Import | `FormsModule` | `ReactiveFormsModule` |
| Data model | Implicit (via directives) | Explicit (FormGroup/FormControl) |
| Validation | HTML attributes + directives | TypeScript functions |
| Testing | Harder (need DOM) | Easier (pure TypeScript) |
| Complexity | Simple forms | Complex/dynamic forms |
| Best for | Login, search, simple input | Registration, multi-step, dynamic |

---

## Template-Driven Forms

Built using directives in the template. Angular creates the form model under the hood.

### Basic Template Form

```typescript
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';

@Component({
  standalone: true,
  imports: [FormsModule],
  template: `
    <form #loginForm="ngForm" (ngSubmit)="onSubmit(loginForm)">
      
      <div>
        <label for="email">Email:</label>
        <input
          id="email"
          type="email"
          name="email"
          [(ngModel)]="user.email"
          required
          email
          #emailField="ngModel"
        />
        @if (emailField.invalid && emailField.touched) {
          <div class="error">
            @if (emailField.errors?.['required']) { <span>Email is required</span> }
            @if (emailField.errors?.['email']) { <span>Invalid email format</span> }
          </div>
        }
      </div>
      
      <div>
        <label for="password">Password:</label>
        <input
          id="password"
          type="password"
          name="password"
          [(ngModel)]="user.password"
          required
          minlength="6"
          #passwordField="ngModel"
        />
        @if (passwordField.invalid && passwordField.touched) {
          <div class="error">
            @if (passwordField.errors?.['required']) { <span>Password is required</span> }
            @if (passwordField.errors?.['minlength']) {
              <span>Min {{ passwordField.errors?.['minlength'].requiredLength }} characters</span>
            }
          </div>
        }
      </div>
      
      <button type="submit" [disabled]="loginForm.invalid">Login</button>
      
      <!-- Debug -->
      <pre>Form valid: {{ loginForm.valid }}</pre>
      <pre>Form value: {{ loginForm.value | json }}</pre>
    </form>
  `
})
export class LoginComponent {
  user = { email: '', password: '' };
  
  onSubmit(form: any): void {
    if (form.valid) {
      console.log('Submitted:', this.user);
    }
  }
}
```

### Template Form Validation Attributes

```html
required                  <!-- Field must not be empty -->
minlength="3"            <!-- Min character count -->
maxlength="50"           <!-- Max character count -->
pattern="[a-zA-Z]*"     <!-- Regex pattern -->
email                    <!-- Valid email format -->
min="0"                  <!-- Min number value -->
max="100"                <!-- Max number value -->
```

### CSS Classes (Auto-added by Angular)

```css
/* Angular auto-adds these classes based on form state */
.ng-valid     { }   /* Field is valid */
.ng-invalid   { }   /* Field is invalid */
.ng-pristine  { }   /* Field hasn't been changed */
.ng-dirty     { }   /* Field has been changed */
.ng-untouched { }   /* Field hasn't been focused */
.ng-touched   { }   /* Field has been focused and blurred */

/* Common: Show error styling only after user interacts */
input.ng-invalid.ng-touched {
  border-color: red;
}

input.ng-valid.ng-touched {
  border-color: green;
}
```

---

## Reactive Forms

Built programmatically in the component class. More powerful, testable, and scalable.

### Import ReactiveFormsModule

```typescript
import { ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';

@Component({
  standalone: true,
  imports: [ReactiveFormsModule]
})
```

### FormControl — Single Input

```typescript
import { FormControl } from '@angular/forms';

// Create a control
const name = new FormControl('Debanjan');           // Initial value
const email = new FormControl('', Validators.required);  // With validator
const age = new FormControl<number | null>(null);        // Typed

// Read/Write value
console.log(name.value);     // 'Debanjan'
name.setValue('New Name');    // Set new value
name.patchValue('Updated');  // Same for single control

// Status
console.log(name.valid);     // true/false
console.log(name.errors);    // { required: true } or null
console.log(name.dirty);     // Has been modified?
console.log(name.touched);   // Has been focused/blurred?

// Reset
name.reset();                // Clear value and reset state
name.reset('Default');       // Reset with default value
```

```html
<input [formControl]="name" />
<p>Value: {{ name.value }}</p>
<p>Valid: {{ name.valid }}</p>
```

### FormGroup — Group of Controls

```typescript
@Component({
  standalone: true,
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="loginForm" (ngSubmit)="onSubmit()">
      <input formControlName="email" placeholder="Email" />
      <input formControlName="password" type="password" placeholder="Password" />
      <button type="submit" [disabled]="loginForm.invalid">Login</button>
    </form>
  `
})
export class LoginComponent {
  loginForm = new FormGroup({
    email: new FormControl('', [Validators.required, Validators.email]),
    password: new FormControl('', [Validators.required, Validators.minLength(6)])
  });
  
  onSubmit(): void {
    if (this.loginForm.valid) {
      console.log(this.loginForm.value);
      // { email: 'user@test.com', password: '123456' }
    }
  }
}
```

### FormBuilder — Shorthand Syntax

```typescript
import { FormBuilder, Validators } from '@angular/forms';

@Component({ ... })
export class RegistrationComponent {
  private fb = inject(FormBuilder);
  
  registrationForm = this.fb.group({
    // [initialValue, validators]
    firstName: ['', [Validators.required, Validators.minLength(2)]],
    lastName: ['', Validators.required],
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(8)]],
    confirmPassword: ['', Validators.required],
    
    // Nested FormGroup
    address: this.fb.group({
      street: [''],
      city: ['', Validators.required],
      state: ['', Validators.required],
      zip: ['', [Validators.required, Validators.pattern(/^\d{5}$/)]]
    }),
    
    // Boolean
    agreeToTerms: [false, Validators.requiredTrue]
  });
  
  onSubmit(): void {
    if (this.registrationForm.valid) {
      console.log(this.registrationForm.value);
    } else {
      this.registrationForm.markAllAsTouched();  // Show all errors
    }
  }
}
```

### Accessing Nested Controls

```typescript
// Access nested control
get emailControl() { return this.registrationForm.get('email'); }
get cityControl() { return this.registrationForm.get('address.city'); }

// In template
@if (emailControl?.invalid && emailControl?.touched) {
  <div class="error">Email is invalid</div>
}
```

---

## Validation

### Built-in Validators

```typescript
import { Validators } from '@angular/forms';

new FormControl('', [
  Validators.required,          // Must not be empty
  Validators.minLength(3),      // Min characters
  Validators.maxLength(50),     // Max characters
  Validators.min(0),            // Min number
  Validators.max(100),          // Max number
  Validators.email,             // Valid email
  Validators.pattern(/^[a-z]+$/),  // Regex pattern
  Validators.requiredTrue       // Checkbox must be checked
]);
```

### Custom Validators

```typescript
import { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

// Validator function
function noSpaces(control: AbstractControl): ValidationErrors | null {
  if (control.value && control.value.includes(' ')) {
    return { noSpaces: true };  // Error object
  }
  return null;                   // Valid
}

// Parameterized validator (factory)
function minAge(min: number): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const age = control.value;
    if (age !== null && age < min) {
      return { minAge: { required: min, actual: age } };
    }
    return null;
  };
}

// Usage
username: new FormControl('', [Validators.required, noSpaces]),
age: new FormControl(null, [Validators.required, minAge(18)])
```

### Cross-Field Validator (FormGroup Level)

```typescript
// Password match validator
function passwordMatch(group: AbstractControl): ValidationErrors | null {
  const password = group.get('password')?.value;
  const confirm = group.get('confirmPassword')?.value;
  
  if (password !== confirm) {
    return { passwordMismatch: true };
  }
  return null;
}

// Apply to FormGroup
this.form = this.fb.group({
  password: ['', [Validators.required, Validators.minLength(8)]],
  confirmPassword: ['', Validators.required]
}, {
  validators: passwordMatch  // Group-level validator
});
```

```html
@if (form.errors?.['passwordMismatch']) {
  <div class="error">Passwords don't match</div>
}
```

### Async Validators

```typescript
import { AsyncValidatorFn } from '@angular/forms';

function uniqueEmail(userService: UserService): AsyncValidatorFn {
  return (control: AbstractControl): Observable<ValidationErrors | null> => {
    return userService.checkEmail(control.value).pipe(
      map(exists => exists ? { emailTaken: true } : null),
      catchError(() => of(null))
    );
  };
}

// Usage (third parameter = async validators)
email: new FormControl('', 
  [Validators.required, Validators.email],  // Sync validators
  [uniqueEmail(this.userService)]            // Async validators
)
```

```html
@if (emailControl?.pending) {
  <span>Checking availability...</span>
}
@if (emailControl?.errors?.['emailTaken']) {
  <span>Email already registered</span>
}
```

---

## FormArray — Dynamic Form Fields

```typescript
@Component({
  standalone: true,
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="profileForm">
      <input formControlName="name" placeholder="Name" />
      
      <div formArrayName="skills">
        <h3>Skills</h3>
        @for (skill of skills.controls; track $index; let i = $index) {
          <div>
            <input [formControlName]="i" [placeholder]="'Skill ' + (i + 1)" />
            <button (click)="removeSkill(i)">✕</button>
          </div>
        }
        <button type="button" (click)="addSkill()">+ Add Skill</button>
      </div>
    </form>
  `
})
export class ProfileComponent {
  private fb = inject(FormBuilder);
  
  profileForm = this.fb.group({
    name: ['', Validators.required],
    skills: this.fb.array([
      new FormControl('Angular'),
      new FormControl('TypeScript')
    ])
  });
  
  get skills(): FormArray {
    return this.profileForm.get('skills') as FormArray;
  }
  
  addSkill(): void {
    this.skills.push(new FormControl('', Validators.required));
  }
  
  removeSkill(index: number): void {
    this.skills.removeAt(index);
  }
}
```

---

## Dynamic Forms

Generate form fields from configuration.

```typescript
interface FieldConfig {
  key: string;
  label: string;
  type: 'text' | 'email' | 'number' | 'select' | 'textarea' | 'checkbox';
  required?: boolean;
  options?: { value: string; label: string }[];  // For select
  validators?: ValidatorFn[];
}

@Component({
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      @for (field of fields; track field.key) {
        <div>
          <label>{{ field.label }}</label>
          
          @switch (field.type) {
            @case ('select') {
              <select [formControlName]="field.key">
                @for (opt of field.options; track opt.value) {
                  <option [value]="opt.value">{{ opt.label }}</option>
                }
              </select>
            }
            @case ('textarea') {
              <textarea [formControlName]="field.key"></textarea>
            }
            @case ('checkbox') {
              <input type="checkbox" [formControlName]="field.key" />
            }
            @default {
              <input [type]="field.type" [formControlName]="field.key" />
            }
          }
        </div>
      }
      <button type="submit">Submit</button>
    </form>
  `
})
export class DynamicFormComponent implements OnInit {
  fields: FieldConfig[] = [
    { key: 'name', label: 'Full Name', type: 'text', required: true },
    { key: 'email', label: 'Email', type: 'email', required: true },
    { key: 'role', label: 'Role', type: 'select', options: [
      { value: 'dev', label: 'Developer' },
      { value: 'design', label: 'Designer' }
    ]},
    { key: 'bio', label: 'Bio', type: 'textarea' }
  ];
  
  form!: FormGroup;
  
  ngOnInit(): void {
    const group: Record<string, FormControl> = {};
    for (const field of this.fields) {
      const validators = field.required ? [Validators.required] : [];
      group[field.key] = new FormControl('', validators);
    }
    this.form = new FormGroup(group);
  }
  
  onSubmit(): void {
    console.log(this.form.value);
  }
}
```

---

## Form State & Methods

```typescript
const form = this.myForm;

// Read state
form.value;          // { email: '...', password: '...' }
form.valid;          // true/false
form.invalid;        // true/false
form.pending;        // true when async validators running
form.dirty;          // Any field changed?
form.touched;        // Any field focused+blurred?
form.pristine;       // No fields changed?
form.untouched;      // No fields touched?
form.errors;         // Group-level errors
form.status;         // 'VALID' | 'INVALID' | 'PENDING' | 'DISABLED'

// Modify
form.setValue({ email: 'a@b.com', password: '123' });  // ALL fields
form.patchValue({ email: 'a@b.com' });                 // Some fields
form.reset();                                           // Clear everything
form.reset({ email: 'default@test.com' });              // Reset with defaults

// Control state
form.markAllAsTouched();    // Show all validation errors
form.markAsPristine();      // Mark as unchanged
form.disable();             // Disable all controls
form.enable();              // Enable all controls

// Listen for changes
form.valueChanges.subscribe(value => console.log(value));
form.statusChanges.subscribe(status => console.log(status));
form.get('email')!.valueChanges.subscribe(email => console.log(email));
```

---

## Key Takeaways

| Concept | Summary |
|---|---|
| Template-Driven | `ngModel` directives, simple forms |
| Reactive | `FormGroup`/`FormControl` in TypeScript, complex forms |
| FormBuilder | `fb.group({...})` shorthand for reactive forms |
| Validators | `Validators.required`, `.email`, `.minLength()` |
| Custom validators | Return `ValidationErrors` or `null` |
| Cross-field | Group-level validator for password match etc. |
| Async validators | Return `Observable<ValidationErrors \| null>` |
| FormArray | Dynamic list of controls (add/remove fields) |
| `valueChanges` | Observable of form value changes |
| `markAllAsTouched()` | Show all errors on submit |

---

*Next Topic: HTTP Client & API Integration →*
