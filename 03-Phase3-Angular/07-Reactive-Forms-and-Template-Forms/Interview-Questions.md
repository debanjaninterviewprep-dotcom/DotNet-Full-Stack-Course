# Topic 07: Reactive Forms and Template Forms — Interview Questions

---

## Q1. What is the difference between template-driven and reactive forms?
**Answer:**
| | Template-Driven | Reactive |
|---|---|---|
| **Setup** | Minimal — uses `ngModel` | Explicit — build form model in component |
| **Module** | `FormsModule` | `ReactiveFormsModule` |
| **Form model** | In template (implicit) | In component class (explicit) |
| **Validation** | HTML attributes | Validator functions |
| **Testing** | Harder (template interaction) | Easier (pure TypeScript) |
| **Dynamic forms** | Difficult | Easy |
| **Async operations** | Manual | First-class (Observables) |
| **Use case** | Simple forms | Complex, dynamic, heavily validated |

**Angular recommendation:** Reactive forms for most cases; template-driven for very simple forms.

---

## Q2. What are `FormControl`, `FormGroup`, and `FormArray`?
**Answer:**
```typescript
// FormControl — single field
const nameControl = new FormControl('', [Validators.required, Validators.minLength(3)]);
nameControl.value;   // current value
nameControl.valid;   // true/false
nameControl.errors;  // { required: true } or null
nameControl.setValue('Alice');
nameControl.patchValue('Bob'); // same for single control

// FormGroup — collection of controls (object)
const loginForm = new FormGroup({
  email:    new FormControl('', [Validators.required, Validators.email]),
  password: new FormControl('', [Validators.required, Validators.minLength(8)])
});
loginForm.value;    // { email: '', password: '' }
loginForm.valid;    // all controls valid?
loginForm.controls['email'].setValue('a@b.com');

// FormArray — collection of controls (array)
const tags = new FormArray([
  new FormControl('angular'),
  new FormControl('typescript')
]);
tags.push(new FormControl('rxjs'));
tags.removeAt(0);
tags.at(0).value; // 'typescript'
```

---

## Q3. What is `FormBuilder` and why is it used?
**Answer:**
`FormBuilder` is a service that provides concise shorthand for creating form models:

```typescript
// Without FormBuilder — verbose
const form = new FormGroup({
  name:  new FormControl('', [Validators.required]),
  email: new FormControl('', [Validators.required, Validators.email])
});

// With FormBuilder — concise
@Component({})
export class LoginComponent {
  form = this.fb.group({
    name:  ['', [Validators.required, Validators.minLength(2)]],
    email: ['', [Validators.required, Validators.email]],
    address: this.fb.group({
      city:  ['', Validators.required],
      zip:   ['']
    }),
    phones: this.fb.array([this.fb.control('')])
  });

  constructor(private fb: FormBuilder) {}
}

// With NonNullableFormBuilder (Angular 14+) — no null in types
form = inject(NonNullableFormBuilder).group({ name: '' });
// form.value.name is string, not string | null
```

---

## Q4. What are built-in validators in Angular reactive forms?
**Answer:**
```typescript
import { Validators } from '@angular/forms';

const ctrl = new FormControl('', [
  Validators.required,            // not empty
  Validators.minLength(3),        // string min length
  Validators.maxLength(50),       // string max length
  Validators.min(0),              // number minimum
  Validators.max(100),            // number maximum
  Validators.email,               // valid email format
  Validators.pattern(/^\d{5}$/),  // regex match
  Validators.nullValidator,       // no-op (useful as placeholder)
]);

// Checking errors
ctrl.errors; // null if valid, otherwise:
// { required: true }
// { minlength: { requiredLength: 3, actualLength: 1 } }
// { email: true }
// { pattern: { requiredPattern: '/^\d{5}$/', actualValue: 'abc' } }
```

---

## Q5. How do you create a custom validator?
**Answer:**
```typescript
// Synchronous validator — returns ValidationErrors or null
function noSpacesValidator(control: AbstractControl): ValidationErrors | null {
  return control.value?.includes(' ')
    ? { noSpaces: { value: control.value } }
    : null;
}

// Async validator — returns Observable<ValidationErrors | null>
function uniqueEmailValidator(userSvc: UserService): AsyncValidatorFn {
  return (ctrl: AbstractControl): Observable<ValidationErrors | null> => {
    return timer(300).pipe( // debounce 300ms
      switchMap(() => userSvc.checkEmail(ctrl.value)),
      map(isTaken => isTaken ? { emailTaken: true } : null),
      catchError(() => of(null)) // on error — treat as valid
    );
  };
}

// Cross-field validator (on FormGroup)
function passwordMatchValidator(group: AbstractControl): ValidationErrors | null {
  const pass = group.get('password')?.value;
  const confirm = group.get('confirmPassword')?.value;
  return pass === confirm ? null : { passwordMismatch: true };
}

// Usage
const form = this.fb.group({
  username:        ['', [Validators.required, noSpacesValidator]],
  email:           ['', Validators.required, uniqueEmailValidator(userSvc)],
  password:        ['', Validators.required],
  confirmPassword: ['']
}, { validators: passwordMatchValidator });
```

---

## Q6. How do you display validation errors in the template?
**Answer:**
```html
<form [formGroup]="form" (ngSubmit)="onSubmit()">
  <div>
    <input formControlName="email" />
    <!-- Show errors only when touched (user interacted) or submitted -->
    @if (form.get('email')?.invalid && form.get('email')?.touched) {
      @if (form.get('email')?.errors?.['required']) {
        <span class="error">Email is required</span>
      }
      @if (form.get('email')?.errors?.['email']) {
        <span class="error">Invalid email format</span>
      }
      @if (form.get('email')?.errors?.['emailTaken']) {
        <span class="error">Email already in use</span>
      }
    }
  </div>

  <!-- Async validator loading state -->
  @if (form.get('email')?.pending) {
    <span>Checking availability...</span>
  }

  <button type="submit" [disabled]="form.invalid || form.pending">Submit</button>
</form>
```

---

## Q7. What are the form control states?
**Answer:**
Each `FormControl` has state that reflects user interaction:

| State | Opposite | Meaning |
|---|---|---|
| `pristine` | `dirty` | Value hasn't changed since initialization |
| `untouched` | `touched` | Control hasn't been focused and blurred |
| `valid` | `invalid` | All validators pass |
| `pending` | — | Async validator running |
| `enabled` | `disabled` | Control is active |

```typescript
form.get('email')?.pristine;   // true — user hasn't changed
form.get('email')?.touched;    // true — user focused then blurred
form.get('email')?.dirty;      // true — value was changed
form.get('email')?.valid;      // true — no validation errors

// Manually mark fields as touched (useful on submit to show all errors)
form.markAllAsTouched();

// Reset form
form.reset();              // clears values and resets dirty/touched
form.reset({ email: '' }); // reset to specific values
```

---

## Q8. How do you react to value changes in reactive forms?
**Answer:**
```typescript
ngOnInit() {
  // Listen to specific control changes
  this.form.get('country')!.valueChanges.subscribe(country => {
    this.loadStates(country);
  });

  // Listen to all form changes
  this.form.valueChanges.subscribe(value => {
    console.log('Form changed:', value);
  });

  // Debounce for search-as-you-type
  this.form.get('search')!.valueChanges.pipe(
    debounceTime(300),
    distinctUntilChanged(),
    switchMap(term => this.searchService.search(term))
  ).subscribe(results => this.results = results);

  // Status changes
  this.form.statusChanges.subscribe(status => {
    // 'VALID' | 'INVALID' | 'PENDING' | 'DISABLED'
  });
}
```

---

## Q9. How do you handle dynamic form fields with `FormArray`?
**Answer:**
```typescript
@Component({
  template: `
    <form [formGroup]="form">
      <div formArrayName="emails">
        @for (ctrl of emails.controls; track $index; let i = $index) {
          <input [formControlName]="i" />
          <button type="button" (click)="removeEmail(i)">Remove</button>
        }
      </div>
      <button type="button" (click)="addEmail()">Add Email</button>
    </form>
  `
})
export class DynamicFormComponent {
  form = this.fb.group({
    emails: this.fb.array([''])
  });

  get emails(): FormArray { return this.form.get('emails') as FormArray; }

  addEmail() { this.emails.push(this.fb.control('', Validators.email)); }
  removeEmail(i: number) { this.emails.removeAt(i); }
}
```

---

## Q10. What is template-driven form validation?
**Answer:**
```html
<form #loginForm="ngForm" (ngSubmit)="onSubmit(loginForm)">
  <input
    name="email"
    [(ngModel)]="model.email"
    #emailCtrl="ngModel"
    required
    email
  />
  <!-- Error display -->
  @if (emailCtrl.invalid && emailCtrl.touched) {
    @if (emailCtrl.errors?.['required']) { <span>Required</span> }
    @if (emailCtrl.errors?.['email'])    { <span>Invalid email</span> }
  }

  <input
    name="password"
    type="password"
    [(ngModel)]="model.password"
    #passCtrl="ngModel"
    required
    minlength="8"
  />

  <button [disabled]="loginForm.invalid">Login</button>
</form>
```

Template-driven form state is managed by Angular's `NgModel` and `NgForm` directives.

---

## Q11. What is `ControlValueAccessor` and when do you implement it?
**Answer:**
`ControlValueAccessor` bridges a custom UI component with Angular's form system:

```typescript
@Component({
  selector: 'app-rating',
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => RatingComponent),
    multi: true
  }],
  template: `
    @for (star of stars; track star) {
      <span (click)="setValue(star)" [class.filled]="star <= value">★</span>
    }
  `
})
export class RatingComponent implements ControlValueAccessor {
  value = 0;
  stars = [1, 2, 3, 4, 5];
  onChange = (_: any) => {};
  onTouched = () => {};

  setValue(v: number) { this.value = v; this.onChange(v); this.onTouched(); }

  writeValue(val: number) { this.value = val; }           // called when form sets value
  registerOnChange(fn: any) { this.onChange = fn; }       // register form's change handler
  registerOnTouched(fn: any) { this.onTouched = fn; }     // register touched handler
  setDisabledState(disabled: boolean) { /* handle disabled state */ }
}

// Usage: <app-rating formControlName="starRating"></app-rating>
```

---

## Q12. What is the `updateOn` option in reactive forms?
**Answer:**
Controls when the value and validity are updated:

```typescript
// Default: 'change' — updates on every keystroke
const ctrl = new FormControl('');

// 'blur' — update only when control loses focus (reduces validator calls)
const ctrl = new FormControl('', { updateOn: 'blur' });

// 'submit' — update only when form is submitted
const form = this.fb.group({
  email: ['', Validators.email]
}, { updateOn: 'submit' }); // applies to whole form
```

---

## Q13. How do you disable and enable form controls?
**Answer:**
```typescript
// Disable a control (value excluded from form.value, validation skipped)
this.form.get('email')?.disable();
this.form.get('email')?.enable();

// Disable entire form
this.form.disable();
this.form.enable();

// Important: disabled controls are NOT included in form.value
// Use form.getRawValue() to include disabled controls
const allValues = this.form.getRawValue(); // includes disabled

// Conditional enable/disable
this.form.get('country')!.valueChanges.subscribe(c => {
  if (c === 'US') this.form.get('state')!.enable();
  else { this.form.get('state')!.disable(); this.form.get('state')!.reset(''); }
});
```

---

## Q14. What are typed forms in Angular 14+?
**Answer:**
Typed forms provide **full type inference** for form controls — form values are typed instead of `any`:

```typescript
// Before Angular 14 — all values typed as any
const form = this.fb.group({ name: [''], age: [0] });
form.value.name; // any

// Angular 14+ — fully typed
interface LoginForm { email: string; password: string; }

const form = this.fb.group<LoginForm>({
  email:    ['', Validators.required],
  password: ['', Validators.required]
});
form.value.email; // string | undefined (undefined if disabled)

// NonNullableFormBuilder — removes null from types
const form = inject(NonNullableFormBuilder).group({
  name: 'Alice',    // inferred as FormControl<string>
  age:  0           // inferred as FormControl<number>
});
form.value.name; // string (never null)
```

---

## Q15. How do you perform form submission and handle API errors?
**Answer:**
```typescript
@Component({})
export class UserFormComponent {
  form = this.fb.group({ email: ['', [Validators.required, Validators.email]] });
  isSubmitting = false;
  serverError = '';

  onSubmit() {
    if (this.form.invalid) {
      this.form.markAllAsTouched(); // show all errors
      return;
    }
    this.isSubmitting = true;
    this.serverError = '';

    this.userService.create(this.form.getRawValue()).pipe(
      finalize(() => this.isSubmitting = false)
    ).subscribe({
      next: (user) => this.router.navigate(['/users', user.id]),
      error: (err) => {
        if (err.status === 422) {
          // Server-side validation errors
          const errors = err.error.errors;
          Object.keys(errors).forEach(field => {
            this.form.get(field)?.setErrors({ serverError: errors[field] });
          });
        } else {
          this.serverError = 'Unexpected error. Please try again.';
        }
      }
    });
  }
}
```
