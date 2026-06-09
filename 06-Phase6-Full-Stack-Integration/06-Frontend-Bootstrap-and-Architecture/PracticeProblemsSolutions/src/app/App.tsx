import { RouterProvider } from 'react-router-dom';
import { router } from './router';
import { ThemeProvider } from './providers';

export function App() {
  return (
    <ThemeProvider>
      <RouterProvider router={router} />
    </ThemeProvider>
  );
}
