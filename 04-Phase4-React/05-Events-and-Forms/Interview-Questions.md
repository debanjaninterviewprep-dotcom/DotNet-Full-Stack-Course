# Topic 05: Events and Forms — Interview Questions

---

## Q1. What are synthetic events in React?
**Answer:**
React wraps native DOM events in a **SyntheticEvent** — a cross-browser wrapper that normalizes event behaviour:

```jsx
function handleClick(event) {
  event.preventDefault();    // works the same across all browsers
  event.stopPropagation();   // stop event bubbling
  console.log(event.target); // the element that was clicked
  console.log(event.nativeEvent); // access the underlying native event
  console.log(event.type);   // "click"
}

<button onClick={handleClick}>Click</button>
```

**React 17 change:** Events are now attached to the root DOM container (not `document`). This improves interoperability with non-React code.

**React's event delegation:** React attaches a single event listener to the root and uses event bubbling to handle all events — more efficient than per-element listeners.

---

## Q2. What is the difference between controlled and uncontrolled forms?
**Answer:**
```jsx
// Controlled — React owns the value
function ControlledForm() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    console.log({ name, email });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input value={name}  onChange={e => setName(e.target.value)} />
      <input value={email} onChange={e => setEmail(e.target.value)} />
      <button type="submit">Submit</button>
    </form>
  );
}

// Uncontrolled — DOM owns the value, accessed via ref
function UncontrolledForm() {
  const nameRef  = useRef(null);
  const emailRef = useRef(null);

  const handleSubmit = (e) => {
    e.preventDefault();
    console.log({ name: nameRef.current.value, email: emailRef.current.value });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input ref={nameRef}  defaultValue="Debanjan" />
      <input ref={emailRef} />
      <button type="submit">Submit</button>
    </form>
  );
}
```

---

## Q3. How do you handle multiple form inputs with a single handler?
**Answer:**
Use the `name` attribute to identify which field changed:

```jsx
function RegistrationForm() {
  const [form, setForm] = useState({ name: '', email: '', password: '' });

  // Single handler for all text fields
  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setForm(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  return (
    <form>
      <input name="name"     value={form.name}     onChange={handleChange} />
      <input name="email"    value={form.email}    onChange={handleChange} />
      <input name="password" value={form.password} onChange={handleChange} type="password" />
    </form>
  );
}
```

---

## Q4. How do you implement form validation?
**Answer:**
```jsx
function LoginForm() {
  const [form, setForm]     = useState({ email: '', password: '' });
  const [errors, setErrors] = useState({});
  const [touched, setTouched] = useState({});

  const validate = (values) => {
    const errs = {};
    if (!values.email)                    errs.email    = 'Email is required';
    else if (!/\S+@\S+\.\S+/.test(values.email)) errs.email = 'Invalid email';
    if (!values.password)                 errs.password = 'Password is required';
    else if (values.password.length < 8)  errs.password = 'Min 8 characters';
    return errs;
  };

  const handleChange = (e) => {
    const updated = { ...form, [e.target.name]: e.target.value };
    setForm(updated);
    if (touched[e.target.name]) setErrors(validate(updated)); // live validate if touched
  };

  const handleBlur = (e) => {
    setTouched(prev => ({ ...prev, [e.target.name]: true }));
    setErrors(validate(form));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    const errs = validate(form);
    if (Object.keys(errs).length > 0) { setErrors(errs); setTouched({ email: true, password: true }); return; }
    submitLogin(form);
  };

  return (
    <form onSubmit={handleSubmit}>
      <input name="email" value={form.email} onChange={handleChange} onBlur={handleBlur} />
      {touched.email && errors.email && <span>{errors.email}</span>}
      <button type="submit">Login</button>
    </form>
  );
}
```

---

## Q5. What is React Hook Form and why is it popular?
**Answer:**
React Hook Form is a performant form library that uses **uncontrolled inputs with refs** — avoiding re-renders on every keystroke:

```jsx
import { useForm } from 'react-hook-form';

function LoginForm() {
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm({
    defaultValues: { email: '', password: '' }
  });

  const onSubmit = async (data) => {
    await loginUser(data); // called only when valid
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input
        {...register('email', {
          required: 'Email is required',
          pattern: { value: /\S+@\S+\.\S+/, message: 'Invalid email' }
        })}
      />
      {errors.email && <span>{errors.email.message}</span>}

      <input
        type="password"
        {...register('password', { required: true, minLength: { value: 8, message: 'Min 8 chars' } })}
      />

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Logging in...' : 'Login'}
      </button>
    </form>
  );
}
```

**Benefits:** Fewer re-renders, built-in validation, easy integration with Zod/Yup schemas.

---

## Q6. How do you handle file uploads in React?
**Answer:**
```jsx
function FileUpload() {
  const [file, setFile]         = useState(null);
  const [progress, setProgress] = useState(0);
  const [preview, setPreview]   = useState('');

  const handleFileChange = (e) => {
    const selected = e.target.files[0];
    if (!selected) return;
    setFile(selected);
    if (selected.type.startsWith('image/')) {
      const reader = new FileReader();
      reader.onloadend = () => setPreview(reader.result);
      reader.readAsDataURL(selected);
    }
  };

  const handleUpload = async () => {
    const formData = new FormData();
    formData.append('file', file);
    await axios.post('/api/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
      onUploadProgress: (e) => setProgress(Math.round(100 * e.loaded / e.total))
    });
  };

  return (
    <>
      <input type="file" accept="image/*" onChange={handleFileChange} />
      {preview && <img src={preview} alt="Preview" />}
      <progress value={progress} max="100" />
      <button onClick={handleUpload} disabled={!file}>Upload</button>
    </>
  );
}
```

---

## Q7. What are common event types in React and their TypeScript types?
**Answer:**
```tsx
// Mouse events
onClick:      React.MouseEvent<HTMLButtonElement>
onMouseEnter: React.MouseEvent<HTMLDivElement>
onMouseMove:  React.MouseEvent<HTMLElement>

// Keyboard events
onKeyDown:  React.KeyboardEvent<HTMLInputElement>
onKeyUp:    React.KeyboardEvent<HTMLInputElement>
onKeyPress: React.KeyboardEvent<HTMLInputElement> // deprecated

// Input/Form events
onChange:   React.ChangeEvent<HTMLInputElement>
onChange:   React.ChangeEvent<HTMLSelectElement>
onChange:   React.ChangeEvent<HTMLTextAreaElement>
onSubmit:   React.FormEvent<HTMLFormElement>
onInput:    React.FormEvent<HTMLInputElement>

// Focus events
onFocus:    React.FocusEvent<HTMLInputElement>
onBlur:     React.FocusEvent<HTMLInputElement>

// Drag events
onDragStart: React.DragEvent<HTMLElement>
onDrop:      React.DragEvent<HTMLElement>

// Usage example
const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
  setValue(e.target.value);
};
```

---

## Q8. What is event delegation in React?
**Answer:**
React uses **event delegation** — instead of attaching event handlers to individual DOM elements, React attaches a single listener to the **root container**:

```jsx
// You write: individual handlers
<button onClick={() => handleAction(1)}>Item 1</button>
<button onClick={() => handleAction(2)}>Item 2</button>
<button onClick={() => handleAction(3)}>Item 3</button>

// React does internally: one listener on root
document.getElementById('root').addEventListener('click', reactEventHandler);
// reactEventHandler routes to the correct component via the event target
```

Benefits:
- Less memory (1 listener vs n listeners).
- Works for dynamically added elements.
- Consistent across all browsers.

---

## Q9. How do you prevent default behavior and stop propagation?
**Answer:**
```jsx
// Prevent default — stop browser's default action
<a href="/somewhere" onClick={(e) => {
  e.preventDefault();   // don't navigate — handle in React
  handleNavigation();
}}>Link</a>

<form onSubmit={(e) => {
  e.preventDefault();   // don't reload page
  handleSubmit(formData);
}}>

// Stop propagation — stop event from bubbling up
<div onClick={() => console.log('outer')}>
  <button onClick={(e) => {
    e.stopPropagation(); // don't fire outer div's handler
    console.log('inner');
  }}>Click</button>
</div>

// Capture phase (fires during capture, before target)
<div onClickCapture={() => console.log('capture')}>
  <button onClick={() => console.log('bubble')}>
```

---

## Q10. How do you debounce or throttle event handlers?
**Answer:**
```jsx
import { useCallback, useRef } from 'react';

// Custom debounce hook
function useDebounce(callback, delay) {
  const timeoutRef = useRef(null);
  return useCallback((...args) => {
    clearTimeout(timeoutRef.current);
    timeoutRef.current = setTimeout(() => callback(...args), delay);
  }, [callback, delay]);
}

function SearchInput() {
  const [query, setQuery] = useState('');

  const debouncedSearch = useDebounce((value) => {
    searchAPI(value); // only called 300ms after last keystroke
  }, 300);

  const handleChange = (e) => {
    setQuery(e.target.value);    // update UI immediately
    debouncedSearch(e.target.value); // debounce the API call
  };

  return <input value={query} onChange={handleChange} />;
}

// Or use lodash
import { debounce } from 'lodash';
const debouncedFn = useCallback(debounce(searchAPI, 300), []);
```

---

## Q11. What is the difference between `onChange` and `onInput` in React?
**Answer:**
In React, `onChange` fires on **every character input** (like the native `input` event) — not only when the field loses focus (like the native `change` event):

```jsx
// React onChange — fires on every keystroke
<input onChange={(e) => setValue(e.target.value)} />

// Equivalent to native input event, NOT native change event
// (React normalizes this for consistency)

// onInput — also fires on every keystroke, mostly redundant with onChange in React
<input onInput={(e) => handleInput(e)} />
```

In practice, use `onChange` for React forms. `onInput` is rarely needed.

---

## Q12. How do you handle keyboard shortcuts in React?
**Answer:**
```jsx
// Component-level keyboard shortcut
function Editor() {
  useEffect(() => {
    const handleKeyDown = (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 's') {
        e.preventDefault();
        save();
      }
      if (e.key === 'Escape') closeModal();
    };
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, []);
}

// Input-specific key handling
<input
  onKeyDown={(e) => {
    if (e.key === 'Enter') submitForm();
    if (e.key === 'Escape') clearInput();
  }}
/>

// Custom hook for keyboard shortcuts
function useKeyPress(targetKey, callback) {
  useEffect(() => {
    const handler = (e) => { if (e.key === targetKey) callback(e); };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [targetKey, callback]);
}
```

---

## Q13. What is `useFormStatus` (React 19)?
**Answer:**
`useFormStatus` is a new hook (React 19 / `react-dom`) for reading the submit status of a parent `<form>`:

```jsx
import { useFormStatus } from 'react-dom';

// Submit button that reads form state
function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Submitting...' : 'Submit'}
    </button>
  );
}

// Works without React Hook Form — uses native form action
function ContactForm() {
  return (
    <form action={submitAction}>
      <input name="email" type="email" required />
      <SubmitButton />
    </form>
  );
}
```

---

## Q14. How do you handle form submission with async operations?
**Answer:**
```jsx
function ContactForm() {
  const [status, setStatus] = useState('idle'); // idle | loading | success | error
  const [error, setError]   = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    const data = Object.fromEntries(new FormData(e.target));

    setStatus('loading');
    try {
      await submitContact(data);
      setStatus('success');
      e.target.reset(); // clear form
    } catch (err) {
      setStatus('error');
      setError(err.message);
    }
  };

  if (status === 'success') return <p>Message sent!</p>;

  return (
    <form onSubmit={handleSubmit}>
      <input name="email" required />
      <textarea name="message" required />
      {status === 'error' && <p className="error">{error}</p>}
      <button type="submit" disabled={status === 'loading'}>
        {status === 'loading' ? 'Sending...' : 'Send'}
      </button>
    </form>
  );
}
```

---

## Q15. What is `FormData` and how is it used with React?
**Answer:**
`FormData` is a native Web API that collects all named form inputs into key-value pairs:

```jsx
// Read all form values without controlled state
const handleSubmit = (e) => {
  e.preventDefault();
  const formData = new FormData(e.target);

  // Get individual values
  const email = formData.get('email');
  const password = formData.get('password');

  // Convert to plain object
  const data = Object.fromEntries(formData.entries());
  // { email: 'a@b.com', password: '...' }

  // For multiple values (checkboxes, multi-select)
  const tags = formData.getAll('tags'); // array

  submitData(data);
};

<form onSubmit={handleSubmit}>
  <input name="email" type="email" required />
  <input name="password" type="password" required />
  <button type="submit">Submit</button>
</form>
```

Useful for uncontrolled forms or when you want to avoid all the `useState` boilerplate for simple forms.
