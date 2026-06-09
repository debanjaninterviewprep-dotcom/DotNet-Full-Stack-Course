# Topic 5: Events & Forms — Practice Problems

> Five progressive problems. Build them in order — each layers a new concept on top of the previous. Use TypeScript wherever possible.

---

## Problem 1 — Controlled Login Form *(Easy)*

**Concepts:** controlled inputs, `onChange`, `onSubmit`, `preventDefault`, basic validation, `aria-invalid`.

### Requirements
- Two inputs: `email` (type `email`) and `password` (type `password`).
- Both fully **controlled** via `useState`.
- A submit button labelled "Log in".
- Validate on submit:
  - `email` must match a basic regex (`/^\S+@\S+\.\S+$/`).
  - `password` must be ≥ 8 characters.
- On invalid: render an inline error under the field and set `aria-invalid="true"`.
- On valid: log the credentials and `reset` both fields.
- Disable the submit button while a fake `await sleep(1000)` "request" runs.

### Sub-problems
1. Add a **Show password** checkbox that toggles `type` between `password` and `text`.
2. Add an **on-blur** validation pass so errors also appear after leaving a field (not only on submit).
3. Add a `Caps Lock is on` warning above the password field using `onKeyDown` and `e.getModifierState('CapsLock')`.
4. Add a "Remember me" checkbox stored in `localStorage` and pre-fill `email` on next mount.

### Starter
```tsx
export function Login() {
  const [form, setForm] = useState({ email: '', password: '' });
  const [errors, setErrors] = useState<{ email?: string; password?: string }>({});
  // ...
  return (<form onSubmit={(e) => { e.preventDefault(); /* TODO */ }}>{/* ... */}</form>);
}
```

---

## Problem 2 — Profile Form, One State Object *(Easy–Medium)*

**Concepts:** shared handler with computed property names, every input type, on-blur validation, `touched` map, accessible errors.

### Requirements
- Single `useState` object with: `firstName`, `lastName`, `email`, `bio` (textarea), `country` (select), `interests` (multi-select), `newsletter` (checkbox), `gender` (radio), `birthday` (date), `themeColor` (color), `volume` (range 0–100).
- One `handleChange(e)` handler shared by **all** inputs — use `e.target.name`, branch on `type`.
- Maintain a `touched` map; show an error for a field only after it has been blurred.
- Validation rules:
  - All names + email required; email regex.
  - `bio` ≤ 280 chars (show live `n/280`).
  - Must select ≥ 1 `interest`.
  - `birthday` must put the user at ≥ 13 years old.
- Display a sticky "Save" button; on success show a `role="status"` toast.
- Each error message wired with `aria-describedby` to the corresponding input.

### Sub-problems
1. Add a "Reset to defaults" button that restores the original state object.
2. Track `isDirty` (any field differs from initial) and only enable Save when dirty **and** valid.
3. Replace `useState` with `useReducer` and define actions `{type:'change'}`, `{type:'blur'}`, `{type:'reset'}`.
4. Persist the in-progress draft in `sessionStorage` and restore on mount.

---

## Problem 3 — Dynamic Field Array with `useReducer` *(Medium)*

**Concepts:** `useReducer`, dynamic lists, keying, focus management, immutable updates.

### Requirements
- Build a "Contact list" editor. Each row has `name`, `email`, `phone` and a remove (×) button.
- Use `useReducer`. Actions:
  - `add` — appends an empty row.
  - `update` — `{ id, field, value }`.
  - `remove` — `{ id }`.
  - `move` — `{ id, dir: 'up' | 'down' }` to reorder.
  - `reset`.
- Each row gets a stable `id` (e.g., `crypto.randomUUID()`); **never** use array index as `key`.
- Validate per-row; submit is disabled until **all** rows are valid and there is ≥ 1 row.
- After clicking "Add", auto-focus the new row's `name` input.
- After "Remove", move focus to the previous row's `name` input (or the Add button if list is empty).

### Sub-problems
1. Add drag-and-drop reordering using `onDragStart`/`onDragOver`/`onDrop` (no library) — dispatch `move`.
2. Show duplicate-email errors that span multiple rows (cross-field validation in the reducer).
3. Add an "Import CSV" button: parse pasted CSV into rows in one dispatch.
4. Memoize each row component with `React.memo` and a custom `arePropsEqual` to prove only changed rows re-render (verify with React DevTools profiler).

### Starter
```tsx
type Row = { id: string; name: string; email: string; phone: string };
type Action =
  | { type: 'add' }
  | { type: 'update'; id: string; field: keyof Row; value: string }
  | { type: 'remove'; id: string }
  | { type: 'move'; id: string; dir: 'up' | 'down' }
  | { type: 'reset' };

function reducer(state: Row[], a: Action): Row[] { /* TODO */ return state; }
```

---

## Problem 4 — File Uploader with Previews & Progress *(Medium–Hard)*

**Concepts:** uncontrolled file input, `FileReader`, drag-and-drop, `XMLHttpRequest` progress, `FormData`, accessibility.

### Requirements
- Accept multiple images via:
  - A standard `<input type="file" multiple accept="image/*">` (uncontrolled).
  - A drag-and-drop dropzone (`onDragOver` + `onDrop`); show a "Drop files here" highlight while dragging.
- For each selected file:
  - Validate `type.startsWith('image/')` and `size ≤ 5 MB` — reject with an inline error.
  - Generate a thumbnail preview using `FileReader.readAsDataURL`.
  - Show file name, size (KB), and a **progress bar** during upload.
- Upload via `XMLHttpRequest` to `/api/upload` using `FormData`; subscribe to `xhr.upload.onprogress`.
- Per-file states: `pending → uploading → success | error`. Allow **Retry** on errors and **Remove** before/after upload.
- A "Clear all" button resets the input (use a ref + `ref.current.value = ''`).

### Sub-problems
1. Add **paste-from-clipboard** support: `onPaste` on the dropzone reads `e.clipboardData.files`.
2. Generate a downscaled thumbnail (max 200×200) on a `<canvas>` instead of using the raw data URL, for memory.
3. Cap concurrent uploads at 3 using a small queue.
4. Make the dropzone keyboard-accessible (`role="button"`, `tabIndex={0}`, Enter/Space opens the file picker).

### Starter
```tsx
type Item = { id: string; file: File; preview: string;
              status: 'pending'|'uploading'|'success'|'error';
              progress: number; error?: string };

function uploadOne(item: Item, onProgress: (p:number)=>void) {
  return new Promise<void>((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    const fd = new FormData(); fd.append('file', item.file);
    xhr.upload.onprogress = (e) => e.lengthComputable && onProgress(e.loaded / e.total);
    xhr.onload  = () => xhr.status < 400 ? resolve() : reject(new Error(xhr.statusText));
    xhr.onerror = () => reject(new Error('Network error'));
    xhr.open('POST', '/api/upload'); xhr.send(fd);
  });
}
```

---

## Problem 5 — Multi-Step Wizard with React Hook Form + Zod *(Hard)*

**Concepts:** RHF, Zod, `zodResolver`, per-step validation, `trigger`, conditional fields, `useFieldArray`, focus on error, accessibility.

### Requirements
Build a 4-step "Create Account" wizard. State must persist across steps; the **back** button never validates; the **next** button validates only that step's fields.

### Steps & schemas
1. **Account** — `email` (email), `password` (≥ 8, mixed case + digit), `confirmPassword` (matches `password` via `refine`).
2. **Profile** — `firstName`, `lastName`, `dob` (date, age ≥ 18), `phone` (E.164-ish), `avatar` (optional File, ≤ 2 MB, image/*).
3. **Addresses** — `useFieldArray` of `{ label, line1, city, country, postalCode }`. ≥ 1 address; max 5.
4. **Preferences** — `theme` (`'light'|'dark'|'system'`), `newsletter` (boolean), `topics` (≥ 1 if `newsletter` is true — conditional).

### Requirements (in detail)
- Single root `useForm<Wizard>({ resolver: zodResolver(WizardSchema), mode: 'onBlur', defaultValues })`.
- Compose schemas: `const WizardSchema = AccountSchema.merge(ProfileSchema).merge(AddressesSchema).merge(PrefsSchema);` and call `trigger(fieldsForStep)` on Next.
- Render a step indicator with `aria-current="step"`; show a global "Step 2 of 4" `aria-live` announcement on change.
- On final submit: simulate `await api.create(data)`. On server error, jump back to the offending step and **focus** the first invalid field (`setFocus`).
- Show a "Review" panel on step 4 summarizing all values; "Edit" links jump to the step.
- Persist values to `sessionStorage` on every change (`watch` + `useEffect`); restore on mount.
- All inputs must be labelled and described by their error messages; pair `aria-invalid` with `aria-describedby`.
- Provide a `<DevTool />` from `@hookform/devtools` (commented out in production).

### Sub-problems
1. Make the password strength meter a small reusable component fed by `watch('password')`, but ensure it does **not** re-render the whole form (use `useWatch({ name: 'password' })`).
2. Add an async uniqueness check on `email` via Zod `.refine(async ...)` and an `isValidating` indicator.
3. Add file preview + size validation for `avatar` integrated with RHF (`Controller` or `register('avatar')` + manual `setValue`).
4. Write **one** Vitest + RTL test per step asserting the validation message, then one end-to-end happy path.
5. Replace `useFieldArray` actions with keyboard shortcuts: `Alt+↑/↓` to reorder the focused address, `Alt+Del` to remove.

### Starter
```tsx
import { useForm, FormProvider, useFieldArray, useFormContext } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const AccountSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).regex(/[A-Z]/).regex(/[a-z]/).regex(/\d/),
  confirmPassword: z.string(),
}).refine(d => d.password === d.confirmPassword, {
  path: ['confirmPassword'], message: 'Passwords do not match',
});

// ...other schemas...
export type Wizard = z.infer<typeof WizardSchema>;

const STEP_FIELDS: Record<number, (keyof Wizard)[]> = {
  0: ['email','password','confirmPassword'],
  1: ['firstName','lastName','dob','phone','avatar'],
  2: ['addresses'],
  3: ['theme','newsletter','topics'],
};

export function Wizard() {
  const methods = useForm<Wizard>({ resolver: zodResolver(WizardSchema), mode: 'onBlur' });
  const [step, setStep] = useState(0);

  const next = async () => {
    const ok = await methods.trigger(STEP_FIELDS[step] as any);
    if (ok) setStep(s => s + 1);
    else methods.setFocus(STEP_FIELDS[step][0] as any);
  };
  // ...
}
```

---

### Submission checklist (apply to every problem)
- [ ] All inputs have a programmatic label.
- [ ] Errors use `aria-invalid` + `aria-describedby`.
- [ ] Submit is disabled while in-flight; double-submit is impossible.
- [ ] No `console.error` warnings (controlled↔uncontrolled, missing `key`, missing `name`).
- [ ] Works with **only** the keyboard (Tab, Shift+Tab, Enter, Space).
- [ ] State updates are immutable; no direct mutation.
- [ ] TypeScript types are explicit on event handlers and form values.

