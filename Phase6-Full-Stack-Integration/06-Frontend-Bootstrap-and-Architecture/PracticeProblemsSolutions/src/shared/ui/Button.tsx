import { forwardRef, type ButtonHTMLAttributes } from 'react';
import clsx from 'clsx';

type Props = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'ghost' | 'danger';
  size?: 'sm' | 'md';
  loading?: boolean;
};

export const Button = forwardRef<HTMLButtonElement, Props>(function Button(
  { variant = 'primary', size = 'md', loading, className, disabled, children, ...rest },
  ref,
) {
  return (
    <button
      ref={ref}
      className={clsx('tf-btn', `tf-btn--${variant}`, `tf-btn--${size}`, className)}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      {...rest}
    >
      {loading ? <span className="tf-btn__spinner" aria-hidden /> : null}
      {children}
    </button>
  );
});
