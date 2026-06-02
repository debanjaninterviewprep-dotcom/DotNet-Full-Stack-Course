import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';

type Theme = 'light' | 'dark' | 'system';

const ThemeCtx = createContext<{ theme: Theme; setTheme: (t: Theme) => void } | null>(null);

// P6: full implementation — read localStorage, subscribe to matchMedia for 'system',
// reflect resolved theme on document.documentElement.dataset.theme.
export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>(
    () => (localStorage.getItem('theme') as Theme) ?? 'system',
  );

  useEffect(() => {
    const resolved =
      theme === 'system'
        ? matchMedia('(prefers-color-scheme: dark)').matches
          ? 'dark'
          : 'light'
        : theme;
    document.documentElement.dataset.theme = resolved;
    localStorage.setItem('theme', theme);
    // TODO P6: subscribe to matchMedia change events when theme === 'system'
  }, [theme]);

  return <ThemeCtx.Provider value={{ theme, setTheme }}>{children}</ThemeCtx.Provider>;
}

export function useTheme() {
  const ctx = useContext(ThemeCtx);
  if (!ctx) throw new Error('useTheme must be used inside ThemeProvider');
  return ctx;
}
