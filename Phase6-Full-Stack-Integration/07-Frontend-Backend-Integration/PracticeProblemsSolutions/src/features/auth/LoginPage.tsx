import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useNavigate, useLocation } from 'react-router-dom';
import { useLogin } from './api';

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});
type FormValues = z.infer<typeof schema>;

export function LoginPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const from = (location.state as { from?: string } | null)?.from ?? '/projects';
  const login = useLogin();

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver: zodResolver(schema) });

  return (
    <form
      onSubmit={handleSubmit((vals) =>
        login.mutate(vals, { onSuccess: () => navigate(from, { replace: true }) }),
      )}
    >
      <label>
        Email
        <input type="email" autoComplete="email" {...register('email')} />
      </label>
      {errors.email ? <p role="alert">{errors.email.message}</p> : null}

      <label>
        Password
        <input type="password" autoComplete="current-password" {...register('password')} />
      </label>
      {errors.password ? <p role="alert">{errors.password.message}</p> : null}

      <button type="submit" disabled={isSubmitting || login.isPending}>
        {login.isPending ? 'Signing in…' : 'Sign in'}
      </button>

      {login.error ? <p role="alert">Invalid credentials</p> : null}
    </form>
  );
}
