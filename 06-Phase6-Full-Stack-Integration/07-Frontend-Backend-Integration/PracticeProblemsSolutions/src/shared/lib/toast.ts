// Centralized error toast — reads RFC 7807 ProblemDetails fields.
export function toastError(err: unknown): void {
  const response = (err as { response?: { data?: unknown } }).response;
  const pd = response?.data as
    | { title?: string; detail?: string; traceId?: string }
    | undefined;
  const title = pd?.title ?? 'Something went wrong';
  const detail = pd?.detail ?? (err as Error).message;
  const traceId = pd?.traceId;
  // TODO P1: replace console with a real toast component (Sonner / your own)
  console.error('[toast]', { title, detail, traceId });
}
