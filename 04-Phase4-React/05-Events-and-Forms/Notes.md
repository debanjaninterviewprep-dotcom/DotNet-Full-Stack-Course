# Topic 5: Events & Forms

> Senior-engineer reference notes for handling DOM events and building robust forms in React 18+. Covers SyntheticEvents, controlled vs uncontrolled inputs, complex form state, validation, libraries (React Hook Form, Formik), accessibility, and performance.

---

## 1. Synthetic Events

React does **not** attach a native listener per element. Instead, since React 17 it attaches a single delegated listener at the **root container** (before 17 it was `document`) and dispatches a cross-browser wrapper called `SyntheticEvent`.

Why a wrapper?
- **Cross-browser normalization** — same shape on every browser.
- **Performance** — one root listener instead of thousands.
- **Integration with batching & concurrent rendering**.

### Event object shape

```tsx
function handler(e: React.MouseEvent<HTMLButtonElement>) {
  e.type;            // "click"
  e.target;          // EventTarget that fired (often inner element)
  e.currentTarget;   // element the handler was attached to (typed)
  e.nativeEvent;     // underlying browser event
  e.preventDefault();
  e.stopPropagation();
  e.isDefaultPrevented();
  e.isPropagationStopped();
}
```

> **Pooling note (legacy ≤ React 16):** SyntheticEvents were *pooled* and nulled out after the handler returned. You had to call `e.persist()` to use the event asynchronously. **React 17+ removed pooling** — modern code can safely reference `e` inside `setTimeout`, promises, etc.

---

## 2. Event Handler Patterns

```tsx
// 1. Inline arrow (creates new function every render — fine for most cases)
<button onClick={() => doSomething(id)}>Go</button>

// 2. Named handler reference (stable identity, preferred for memoized children)
const onClick = useCallback(() => doSomething(id), [id]);
<button onClick={onClick}>Go</button>

// 3. Passing arguments
<button onClick={(e) => remove(item.id, e)}>X</button>

// 4. Currying
const remove = (id: string) => (e: React.MouseEvent) => { /* ... */ };
<button onClick={remove(item.id)}>X</button>
```

### Class components — `this` binding

```jsx
class Counter extends React.Component {
  state = { n: 0 };
  // a) bind in constructor
  constructor(p) { super(p); this.inc = this.inc.bind(this); }
  inc() { this.setState({ n: this.state.n + 1 }); }
  // b) class field arrow (auto-bound, modern preferred)
  dec = () => this.setState({ n: this.state.n - 1 });
  render() { return <button onClick={this.inc}>{this.state.n}</button>; }
}
```

> Function components + Hooks remove the `this` problem entirely.

---

## 3. Common Events Cheatsheet

| Category | React props |
|---|---|
| Mouse | `onClick`, `onDoubleClick`, `onMouseDown/Up/Move`, `onMouseEnter/Leave`, `onMouseOver/Out`, `onContextMenu` |
| Pointer | `onPointerDown/Up/Move/Cancel/Enter/Leave/Over/Out` |
| Touch | `onTouchStart/End/Move/Cancel` |
| Keyboard | `onKeyDown`, `onKeyUp`, ~~`onKeyPress`~~ (deprecated) |
| Form | `onChange`, `onInput`, `onSubmit`, `onReset`, `onInvalid`, `onSelect` |
| Focus | `onFocus`, `onBlur` |
| Clipboard | `onCopy`, `onCut`, `onPaste` |
| Drag | `onDrag`, `onDragStart`, `onDragEnd`, `onDragEnter`, `onDragLeave`, `onDragOver`, `onDrop` |
| Wheel/Scroll | `onWheel`, `onScroll` |
| Media | `onPlay`, `onPause`, `onEnded`, `onTimeUpdate`, `onVolumeChange`, … |
| Image | `onLoad`, `onError` |
| Animation | `onAnimationStart`, `onAnimationEnd`, `onAnimationIteration` |
| Transition | `onTransitionEnd` |

### `onChange` vs `onInput` in React

DOM `change` only fires on commit (blur for text inputs). React **redefines `onChange` to behave like `oninput`** — it fires on every keystroke, which is what you want for controlled inputs. `onInput` also exists and behaves similarly; prefer `onChange`.

---

## 4. `preventDefault()` and `stopPropagation()`

```tsx
function Form() {
  return (
    <form onSubmit={(e) => {
      e.preventDefault();          // stop full page reload
      submit();
    }}>
      <a href="/x" onClick={(e) => e.preventDefault()}>Custom link</a>
      <div onClick={() => console.log('outer')}>
        <button onClick={(e) => {
          e.stopPropagation();     // outer div won't log
          console.log('inner');
        }}>Click</button>
      </div>
    </form>
  );
}
```

- `preventDefault()` cancels the browser's default action (form submit, link nav, context menu, drop, …).
- `stopPropagation()` halts bubbling to ancestor handlers.
- Call **early** — once a default fires (page reload), it can't be undone.

---

## 5. Event Delegation: React vs DOM

| | DOM | React 17+ |
|---|---|---|
| Where listener attaches | wherever you `addEventListener` | one delegated listener at the **root container** |
| Synthetic vs Native | Native | SyntheticEvent wrapper |
| Mixing native APIs | direct | use `e.nativeEvent` to bridge |
| Stopping React→DOM bubbling | n/a | `e.stopPropagation()` stops React; `e.nativeEvent.stopImmediatePropagation()` to also stop native listeners |

> If you mount React inside another framework, prefer multiple roots over manual `document.addEventListener` to avoid double-handling.

---

## 6. Capture Phase

Every React event prop has a `*Capture` variant that fires during the capture phase (top-down) **before** the bubbling phase:

```tsx
<div onClickCapture={() => console.log('capture')}
     onClick={() => console.log('bubble')}>
  <button onClick={() => console.log('button')}>X</button>
</div>
// Order: capture → button → bubble
```

Useful for global shortcut managers, focus traps, analytics that must run before child handlers.

---

## 7. TypeScript Event Types

```ts
import * as React from 'react';

// Generic shape: React.<EventName>Event<TElement>
type ClickHandler  = React.MouseEventHandler<HTMLButtonElement>;
type ChangeHandler = React.ChangeEventHandler<HTMLInputElement>;
type SubmitHandler = React.FormEventHandler<HTMLFormElement>;
type KeyHandler    = React.KeyboardEventHandler<HTMLInputElement>;
type FocusHandler  = React.FocusEventHandler<HTMLInputElement>;
type DragHandler   = React.DragEventHandler<HTMLDivElement>;

// Inline
function onChange(e: React.ChangeEvent<HTMLInputElement>) {
  const v = e.target.value;          // string
  const checked = e.target.checked;  // boolean (for checkboxes)
}

// Generic component prop
interface InputProps<T extends HTMLElement = HTMLInputElement> {
  onChange?: (e: React.ChangeEvent<T>) => void;
}
```

> **`SyntheticEvent` vs `Event`:** React typings extend `BaseSyntheticEvent`. Always use the React types; the DOM-level `Event` won't include `currentTarget` typing.

---

## 8. Forms — Controlled vs Uncontrolled

| Aspect | Controlled | Uncontrolled |
|---|---|---|
| Source of truth | React state | DOM |
| Read value via | state variable | `ref.current.value` / FormData |
| Initial value | `value={state}` | `defaultValue` / `defaultChecked` |
| Re-renders | every keystroke | none |
| Validation timing | live, easy | on submit / blur, manual |
| Best for | dynamic UI, conditional fields, derived values | simple forms, file inputs, perf-critical, library-managed (RHF) |
| Mixing | warning if `value` is set without `onChange` | n/a |

```tsx
// Controlled
<input value={name} onChange={(e) => setName(e.target.value)} />

// Uncontrolled
const ref = useRef<HTMLInputElement>(null);
<input defaultValue="hi" ref={ref} />
<button onClick={() => console.log(ref.current?.value)}>Read</button>
```

---

## 9. Controlled Inputs — Every Input Type

```tsx
function AllInputs() {
  const [text, setText]       = useState('');
  const [bio, setBio]         = useState('');
  const [country, setCountry] = useState('IN');
  const [tags, setTags]       = useState<string[]>([]);   // multi-select
  const [agree, setAgree]     = useState(false);
  const [size, setSize]       = useState<'S'|'M'|'L'>('M');
  const [vol, setVol]         = useState(50);
  const [dob, setDob]         = useState('2000-01-01');
  const [color, setColor]     = useState('#3366ff');

  return (
    <>
      {/* text */}
      <input type="text" value={text} onChange={e => setText(e.target.value)} />

      {/* textarea */}
      <textarea value={bio} onChange={e => setBio(e.target.value)} />

      {/* select (single) */}
      <select value={country} onChange={e => setCountry(e.target.value)}>
        <option value="IN">India</option><option value="US">USA</option>
      </select>

      {/* select (multiple) */}
      <select multiple value={tags}
        onChange={e => setTags(Array.from(e.target.selectedOptions, o => o.value))}>
        <option value="js">JS</option><option value="ts">TS</option><option value="rs">Rust</option>
      </select>

      {/* checkbox (boolean) */}
      <input type="checkbox" checked={agree} onChange={e => setAgree(e.target.checked)} />

      {/* radio group */}
      {(['S','M','L'] as const).map(s => (
        <label key={s}><input type="radio" name="size" value={s}
          checked={size === s} onChange={() => setSize(s)} />{s}</label>
      ))}

      {/* range / date / color */}
      <input type="range" min={0} max={100} value={vol}
        onChange={e => setVol(Number(e.target.value))} />
      <input type="date"  value={dob}   onChange={e => setDob(e.target.value)} />
      <input type="color" value={color} onChange={e => setColor(e.target.value)} />
    </>
  );
}
```

> Cast numerics yourself — `e.target.value` is always `string`.

### File inputs are *always* uncontrolled

```tsx
const fileRef = useRef<HTMLInputElement>(null);
<input type="file" ref={fileRef} accept="image/*" multiple
       onChange={(e) => {
         const files = e.target.files;     // FileList | null
         if (!files) return;
         Array.from(files).forEach(f => console.log(f.name, f.size, f.type));
       }} />
```

You **cannot** set `value` on a file input (security). Read via `e.target.files` or a ref.

---

## 10. File Upload — FileReader & FormData

```tsx
function Avatar() {
  const [preview, setPreview] = useState<string>();

  const onPick = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Preview via FileReader
    const reader = new FileReader();
    reader.onload = () => setPreview(reader.result as string);
    reader.readAsDataURL(file);

    // Upload as multipart/form-data
    const fd = new FormData();
    fd.append('avatar', file, file.name);
    fd.append('userId', '42');
    fetch('/api/avatar', { method: 'POST', body: fd }); // do NOT set Content-Type
  };

  return (<>
    <input type="file" accept="image/*" onChange={onPick} />
    {preview && <img src={preview} alt="" width={120} />}
  </>);
}
```

Track progress with `XMLHttpRequest` (`xhr.upload.onprogress`) — `fetch` cannot report upload progress.

---

## 11. Form Submission Pattern

```tsx
function Login() {
  const [form, setForm] = useState({ email: '', password: '' });
  const [busy, setBusy] = useState(false);
  const [err, setErr]   = useState<string>();

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setBusy(true); setErr(undefined);
    try {
      await api.login(form);
    } catch (ex: any) {
      setErr(ex.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} noValidate>{/* ... */}</form>
  );
}
```

- Always `preventDefault()` first.
- Disable the submit button while `busy` to prevent double-submits.
- `noValidate` disables native HTML5 popups when you provide custom validation.

---

## 12. Multi-Input Forms with One State Object

Use **computed property names** with the `name` attribute:

```tsx
const [form, setForm] = useState({ first: '', last: '', email: '' });

const onChange = (e: React.ChangeEvent<HTMLInputElement>) => {
  const { name, value, type, checked } = e.target;
  setForm(prev => ({ ...prev, [name]: type === 'checkbox' ? checked : value }));
};

<input name="first" value={form.first} onChange={onChange} />
<input name="last"  value={form.last}  onChange={onChange} />
<input name="email" value={form.email} onChange={onChange} />
```

> Forgetting `name` is the single most common bug — `[undefined]: value` silently corrupts state.

---

## 13. `useReducer` for Complex Form State

```tsx
type State = { values: Record<string,string>; errors: Record<string,string>; touched: Record<string,boolean> };
type Action =
  | { type: 'change'; field: string; value: string }
  | { type: 'blur'; field: string }
  | { type: 'errors'; errors: Record<string,string> }
  | { type: 'reset' };

const initial: State = { values: { name: '', email: '' }, errors: {}, touched: {} };

function reducer(s: State, a: Action): State {
  switch (a.type) {
    case 'change': return { ...s, values: { ...s.values, [a.field]: a.value } };
    case 'blur':   return { ...s, touched: { ...s.touched, [a.field]: true } };
    case 'errors': return { ...s, errors: a.errors };
    case 'reset':  return initial;
  }
}

const [state, dispatch] = useReducer(reducer, initial);
```

Reach for `useReducer` when actions become non-trivial (field arrays, conditional sections, async validation steps).

---

## 14. Validation

| Strategy | When errors appear | UX |
|---|---|---|
| `onSubmit` only | after submit click | least noisy, slower feedback |
| `onChange` | every keystroke | aggressive, can be annoying |
| `onBlur` then `onChange` | after first blur, then live | **recommended default** |

```tsx
const errors: Record<string,string> = {};
if (!form.email) errors.email = 'Required';
else if (!/^[^@]+@[^@]+\.[^@]+$/.test(form.email)) errors.email = 'Invalid email';
if (form.password.length < 8) errors.password = 'Min 8 characters';
```

Display rules:
- Show error only if `touched[field]` (avoid yelling on first paint).
- Mark inputs with `aria-invalid` and `aria-describedby={errId}`.
- Use a single `aria-live="polite"` region for summary announcements.
- On submit failure, **focus the first invalid field**.

---

## 15. Custom Hooks — `useInput` and `useForm`

```tsx
// useInput — single field
export function useInput<T = string>(initial: T) {
  const [value, setValue] = useState<T>(initial);
  const onChange = (e: React.ChangeEvent<HTMLInputElement>) =>
    setValue(e.target.value as unknown as T);
  return { value, onChange, reset: () => setValue(initial), set: setValue };
}

// usage
const email = useInput('');
<input type="email" {...email} />
```

```tsx
// useForm — generic, validation-aware
type Validator<T> = (values: T) => Partial<Record<keyof T, string>>;

export function useForm<T extends Record<string, any>>(initial: T, validate?: Validator<T>) {
  const [values, setValues]   = useState<T>(initial);
  const [errors, setErrors]   = useState<Partial<Record<keyof T, string>>>({});
  const [touched, setTouched] = useState<Partial<Record<keyof T, boolean>>>({});
  const [submitting, setSub]  = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, type, checked } = e.target;
    setValues(v => ({ ...v, [name]: type === 'checkbox' ? checked : value }));
  };
  const handleBlur = (e: React.FocusEvent<HTMLInputElement>) => {
    setTouched(t => ({ ...t, [e.target.name]: true }));
    if (validate) setErrors(validate({ ...values, [e.target.name]: e.target.value }));
  };
  const handleSubmit = (onValid: (v: T) => void | Promise<void>) =>
    async (e: React.FormEvent<HTMLFormElement>) => {
      e.preventDefault();
      const errs = validate ? validate(values) : {};
      setErrors(errs);
      setTouched(Object.keys(values).reduce((a, k) => ({ ...a, [k]: true }), {}));
      if (Object.keys(errs).length) return;
      setSub(true);
      try { await onValid(values); } finally { setSub(false); }
    };

  return { values, errors, touched, submitting, handleChange, handleBlur, handleSubmit,
           reset: () => { setValues(initial); setErrors({}); setTouched({}); } };
}
```

---

## 16. Form Libraries

| Library | Approach | Bundle | Re-renders | DX |
|---|---|---|---|---|
| **React Hook Form** | uncontrolled + refs | ~9 KB | minimal | excellent, TS-first |
| **Formik** | controlled, render-props/Hooks | ~13 KB | per-keystroke | mature, verbose |
| **Final Form / react-final-form** | subscription model | ~6 KB | targeted | functional, niche |

### React Hook Form — full example

```tsx
import { useForm, SubmitHandler } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const Schema = z.object({
  email: z.string().email(),
  password: z.string().min(8, 'Min 8 chars'),
  age: z.coerce.number().int().min(18, 'Must be 18+'),
});
type FormData = z.infer<typeof Schema>;

export function Signup() {
  const { register, handleSubmit, formState: { errors, isSubmitting }, reset }
    = useForm<FormData>({ resolver: zodResolver(Schema), mode: 'onBlur' });

  const onSubmit: SubmitHandler<FormData> = async (data) => {
    await api.signup(data);
    reset();
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate>
      <label>Email
        <input {...register('email')} aria-invalid={!!errors.email}
               aria-describedby="email-err" />
      </label>
      {errors.email && <span id="email-err" role="alert">{errors.email.message}</span>}

      <input type="password" {...register('password')} />
      {errors.password && <span role="alert">{errors.password.message}</span>}

      <input type="number" {...register('age')} />
      {errors.age && <span role="alert">{errors.age.message}</span>}

      <button disabled={isSubmitting}>Sign up</button>
    </form>
  );
}
```

### Formik (sketch)

```tsx
<Formik initialValues={{ email: '' }}
  validationSchema={Yup.object({ email: Yup.string().email().required() })}
  onSubmit={async (values, helpers) => { await api.save(values); helpers.resetForm(); }}>
  {({ isSubmitting }) => (
    <Form><Field name="email" /><ErrorMessage name="email" /><button disabled={isSubmitting}>Go</button></Form>
  )}
</Formik>
```

### Schema validation: Zod vs Yup

```ts
// Zod (TS-first, infers types)
const User = z.object({ name: z.string().min(1), age: z.number().min(18) });
type User = z.infer<typeof User>;
User.parse(input);       // throws
User.safeParse(input);   // { success, data | error }

// Yup (mature, async support)
const schema = yup.object({ name: yup.string().required(), age: yup.number().min(18) });
await schema.validate(input, { abortEarly: false });
```

---

## 17. Common Pitfalls

| Pitfall | Symptom | Fix |
|---|---|---|
| Stale state in handler | reads old value inside async/setTimeout | use functional `setX(prev => ...)` or refs |
| Mutating state | `form.email = 'x'; setForm(form)` — no re-render | always create a new object: `setForm({...form, email:'x'})` |
| Controlled → uncontrolled warning | `value={undefined}` then a string | initialize to `''`, never `undefined` |
| Missing `name` attribute | shared handler writes to `[undefined]` | always set `name` |
| Late `preventDefault` | page reload on submit | call it as the **first** statement |
| Debouncing controlled input | jumpy cursor / lost keystrokes | keep `value` synced; debounce only the side-effect |
| Number/date as string | math/comparison fails | `Number(e.target.value)`; use `valueAsNumber`/`valueAsDate` for refs |
| New object as `defaultValue` every render on RHF | resets field | memoize or pass to `useForm({ defaultValues })` |

---

## 18. Accessibility

- Every input needs a programmatic label: `<label htmlFor>` or wrap, or `aria-label`.
- Group related inputs with `<fieldset><legend>`.
- Errors:
  - `aria-invalid={hasError}` on the input.
  - `aria-describedby="field-error"` linking to the message node.
  - Wrap the live error region with `role="alert"` or place a single `aria-live="polite"` summary.
- On submit failure, **move focus** to the first invalid field (`ref.current?.focus()`).
- Use the right `inputMode` / `autoComplete` / `type` for mobile keyboards (`email`, `tel`, `numeric`).
- Don't disable the submit button to indicate invalidity — it traps screen-reader users; use `aria-disabled` and let them try.

---

## 19. Performance

- **Uncontrolled** inputs avoid per-keystroke re-render — best for very large forms.
- **React Hook Form** keeps state outside React and subscribes only the fields that need to render.
- Wrap leaf fields in `React.memo`; pass stable handlers via `useCallback`.
- Split a giant form into sub-components so re-render scope is local.
- Debounce only **derived work** (search, validation API calls), never the controlled `value`.
- Avoid recreating `defaultValues` / Zod schemas every render — define module-scope or `useMemo`.

---

## 20. Testing Forms (preview)

Covered in detail in **Topic 11 — Testing**. Quick reference:

```tsx
// React Testing Library + user-event
await userEvent.type(screen.getByLabelText(/email/i), 'a@b.co');
await userEvent.click(screen.getByRole('button', { name: /sign up/i }));
expect(await screen.findByRole('alert')).toHaveTextContent(/min 8/i);
```

Test behavior, not implementation: query by role/label, simulate real user events, assert visible output and a11y attributes.

---

## Key Takeaways

- React events are **SyntheticEvents** — cross-browser wrappers dispatched from a single root listener; no pooling since React 17.
- Prefer **controlled** inputs for dynamic UIs, **uncontrolled** (or RHF) for performance and file inputs.
- Always set the input's `name` and use `[name]: value` for shared handlers.
- Call `e.preventDefault()` first inside `onSubmit`; never trust HTML5 popups for real validation.
- Reach for `useReducer` (or RHF) when the form has dynamic field arrays or async/conditional logic.
- Validation UX: `onBlur` then `onChange`; show errors only after `touched`; focus the first invalid field on submit.
- Pair every error with `aria-invalid` + `aria-describedby`; provide a live region.
- Use **Zod** with `zodResolver` for type-safe end-to-end validation in TS projects.
- Watch for stale state, mutation, controlled↔uncontrolled flips, and missing `name` — they cause 90% of form bugs.
- Optimize at scale with RHF, `React.memo`, sub-component splitting, and uncontrolled inputs.

