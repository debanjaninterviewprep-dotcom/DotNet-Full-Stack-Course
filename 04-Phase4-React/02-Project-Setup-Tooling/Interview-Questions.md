# Topic 02: Project Setup & Tooling — Interview Questions

---

## Q1. What is Vite and why is it preferred over Create React App?
**Answer:**
Vite is a modern build tool that uses **native ES modules** in development (no bundling), resulting in near-instant server start and hot module replacement:

| | Vite | Create React App |
|---|---|---|
| **Dev server start** | < 1 second | 5-30 seconds |
| **HMR** | Instant | Slow (re-bundles) |
| **Build tool** | Rollup (prod) | Webpack |
| **Config** | `vite.config.ts` — simple | `webpack.config.js` — ejected only |
| **Maintenance** | Active | Deprecated (not recommended) |
| **TypeScript** | Built-in | Supported |

```bash
# Create React + Vite project
npm create vite@latest my-app -- --template react-ts
cd my-app && npm install && npm run dev
```

---

## Q2. What is the purpose of `package.json`?
**Answer:**
`package.json` is the manifest for a Node.js project, defining:

```json
{
  "name": "my-react-app",
  "version": "1.0.0",
  "scripts": {
    "dev":   "vite",             // start dev server
    "build": "tsc && vite build", // production build
    "test":  "vitest",
    "lint":  "eslint src --ext ts,tsx"
  },
  "dependencies": {             // runtime deps (shipped to browser)
    "react": "^18.3.0",
    "react-dom": "^18.3.0"
  },
  "devDependencies": {          // build/dev only deps (not shipped)
    "@vitejs/plugin-react": "^4.0.0",
    "typescript": "^5.0.0",
    "vite": "^5.0.0"
  }
}
```

**`dependencies` vs `devDependencies`:**
- `dependencies` — needed at runtime (React, axios, date-fns).
- `devDependencies` — needed only for development/build (Vite, TypeScript, ESLint, Jest).

---

## Q3. What is the difference between `npm install`, `npm ci`, and `npm update`?
**Answer:**
| Command | Behaviour |
|---|---|
| `npm install` | Installs all deps; creates/updates `package-lock.json` |
| `npm install <pkg>` | Adds new package |
| `npm install <pkg> --save-dev` | Adds to devDependencies |
| `npm ci` | Clean install from `package-lock.json` exactly — for CI/CD pipelines |
| `npm update` | Updates packages to latest versions within semver range |
| `npm audit` | Check for security vulnerabilities |

**Semver ranges:**
```
"^18.2.0" — compatible: >=18.2.0 <19.0.0 (minor + patch)
"~18.2.0" — approximately: >=18.2.0 <18.3.0 (patch only)
"18.2.0"  — exact version only
```

---

## Q4. How do you set up TypeScript in a React project?
**Answer:**
```bash
# With Vite (recommended)
npm create vite@latest my-app -- --template react-ts
```

Key files:
```json
// tsconfig.json — TypeScript configuration
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",      // React 17+ JSX transform
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

```tsx
// TypeScript component
interface Props {
  name: string;
  age?: number;
  onClick: (id: number) => void;
}

const UserCard: React.FC<Props> = ({ name, age = 0, onClick }) => (
  <div onClick={() => onClick(1)}>{name} ({age})</div>
);

// Typing useState
const [user, setUser] = useState<User | null>(null);
const [count, setCount] = useState(0); // inferred as number
```

---

## Q5. What is ESLint and Prettier and how do they work together?
**Answer:**
- **ESLint** — static code analyzer that enforces coding rules (catches bugs and bad patterns).
- **Prettier** — opinionated code formatter (enforces consistent style).

```bash
npm install --save-dev eslint prettier eslint-config-prettier
```

```json
// .eslintrc.json
{
  "extends": [
    "eslint:recommended",
    "plugin:react/recommended",
    "plugin:@typescript-eslint/recommended",
    "prettier"               // disable ESLint formatting rules (let Prettier handle)
  ],
  "rules": {
    "react/react-in-jsx-scope": "off", // not needed in React 17+
    "no-console": "warn"
  }
}
```

```json
// .prettierrc
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100
}
```

---

## Q6. What are environment variables in React and how do you use them?
**Answer:**
```bash
# .env (committed to git — public values only)
VITE_API_URL=https://api.example.com
VITE_APP_NAME=MyApp

# .env.local (not committed — secret values)
VITE_API_KEY=secret-key-here

# .env.production — only used in production build
VITE_API_URL=https://prod-api.example.com
```

```tsx
// Access in code (Vite prefix: VITE_)
const apiUrl = import.meta.env.VITE_API_URL;
const isDev  = import.meta.env.DEV;    // boolean
const isProd = import.meta.env.PROD;   // boolean
const mode   = import.meta.env.MODE;   // 'development' | 'production'

// Create React App prefix: REACT_APP_
const url = process.env.REACT_APP_API_URL;
```

**Security:** Never put secrets (API keys, passwords) in frontend environment variables — they are embedded in the bundle and visible to anyone who inspects the source code.

---

## Q7. What is the folder structure of a typical React project?
**Answer:**
```
my-react-app/
├── public/                  # Static assets (favicon, manifest.json)
├── src/
│   ├── assets/              # Images, SVGs, fonts
│   ├── components/          # Reusable UI components
│   │   ├── Button/
│   │   │   ├── Button.tsx
│   │   │   ├── Button.module.css
│   │   │   └── Button.test.tsx
│   ├── pages/               # Route-level components
│   ├── hooks/               # Custom hooks (use*.ts)
│   ├── services/            # API calls
│   ├── store/               # Redux / Zustand
│   ├── types/               # TypeScript interfaces
│   ├── utils/               # Pure utility functions
│   ├── App.tsx
│   └── main.tsx             # Entry point
├── .env
├── .eslintrc.json
├── .prettierrc
├── tsconfig.json
├── vite.config.ts
└── package.json
```

---

## Q8. What is Webpack and how does it differ from Vite?
**Answer:**
| | Webpack | Vite |
|---|---|---|
| **Approach** | Bundles everything upfront | Native ESM in dev — no bundling |
| **Dev startup** | Slow (build entire dependency graph) | Instant (only what's imported) |
| **HMR** | Slow (re-bundle affected modules) | Fast (single file update) |
| **Config** | Complex (`webpack.config.js`) | Simple (`vite.config.ts`) |
| **Production** | Webpack | Rollup (better tree-shaking) |
| **Ecosystem** | Mature, huge plugin ecosystem | Growing rapidly |

Vite uses Webpack-style bundling (via Rollup) only for **production builds** to optimize chunk splitting and tree-shaking.

---

## Q9. What is `React.StrictMode` and what does it catch?
**Answer:**
```jsx
// main.tsx — wrap app in StrictMode for development warnings
createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

StrictMode catches:
- **Impure render functions** — double-invokes renders to expose accidental side effects.
- **Deprecated APIs** — warns about legacy `componentWillMount`, string refs.
- **Missing cleanup** in `useEffect` — runs effects twice (mount → cleanup → mount) to expose missing cleanups.
- **Reusable state issues** — React 18 simulates unmount/remount to prepare for future features (Offscreen API).

---

## Q10. What is the `vite.config.ts` file used for?
**Answer:**
```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],

  // Path aliases — import from '@/components' instead of '../../../components'
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') }
  },

  // Dev server config
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:5000',
        changeOrigin: true,       // handle CORS in development
        rewrite: p => p.replace(/^\/api/, '')
      }
    }
  },

  // Build options
  build: {
    outDir: 'dist',
    sourcemap: true
  }
});
```

---

## Q11. What is the difference between `npm`, `yarn`, and `pnpm`?
**Answer:**
| | npm | yarn | pnpm |
|---|---|---|---|
| **Speed** | Moderate | Fast | Fastest |
| **Disk space** | Copies packages | Copies packages | Symlinks (shared store) |
| **Lock file** | `package-lock.json` | `yarn.lock` | `pnpm-lock.yaml` |
| **Workspaces** | ✓ | ✓ | ✓ (best) |
| **Strictness** | Lenient | Medium | Strict (no phantom deps) |

```bash
npm install react     →  yarn add react     →  pnpm add react
npm run dev           →  yarn dev           →  pnpm dev
npm install           →  yarn               →  pnpm install
```

**pnpm** is increasingly preferred for monorepos (significantly faster, disk-efficient).

---

## Q12. What is tree-shaking?
**Answer:**
Tree-shaking is the process of eliminating **dead code** (unused exports) from the final bundle:

```javascript
// math.js — exports three functions
export const add      = (a, b) => a + b;
export const subtract = (a, b) => a - b;
export const multiply = (a, b) => a * b;

// app.js — only imports add
import { add } from './math';

// After tree-shaking — subtract and multiply are NOT included in bundle
```

Requirements for tree-shaking:
- ES modules (`import`/`export`) — not CommonJS (`require`).
- Bundler support (Webpack, Rollup, Vite all support it).
- No side effects in the module (declared in `package.json: "sideEffects": false`).

---

## Q13. What is hot module replacement (HMR)?
**Answer:**
HMR updates modules in the running browser **without a full page reload**, preserving application state:

```
Developer saves a file
    ↓
Dev server detects change
    ↓
Only the changed module is updated in the browser
    ↓
Component re-renders with new code
    ↓
Application state preserved (form values, scroll position)
```

Without HMR: every file save causes a full page refresh → loses all state.

React HMR (via React Fast Refresh in Vite) also preserves component state between updates when the hook signatures don't change.

---

## Q14. What is code splitting and how is it done in React?
**Answer:**
Code splitting divides the bundle into smaller chunks loaded on demand:

```jsx
import { lazy, Suspense } from 'react';

// Dynamic import — creates a separate chunk
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Reports   = lazy(() => import('./pages/Reports'));

function App() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/reports"   element={<Reports />} />
      </Routes>
    </Suspense>
  );
}
```

Chunk loading happens when the route is first visited. The rest of the app loads first, and the chunk is fetched in the background (with preloading strategies).

---

## Q15. What are the differences between development and production builds?
**Answer:**
| | Development | Production |
|---|---|---|
| **Minification** | None | Terser — removes whitespace, shortens names |
| **Source maps** | Full (easy debugging) | None or hidden |
| **Dead code** | Included | Tree-shaken |
| **React errors** | Verbose, descriptive | Cryptic (smaller) |
| **StrictMode** | Active (double renders) | No effect |
| **`NODE_ENV`** | `'development'` | `'production'` |
| **Performance** | Slower (extra checks) | Optimized |

```bash
npm run dev     # development server
npm run build   # production build → dist/
npm run preview # preview production build locally
```

React itself checks `process.env.NODE_ENV` to include helpful dev-only warnings.
