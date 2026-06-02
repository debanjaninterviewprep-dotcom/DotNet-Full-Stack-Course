import { test, expect } from '@playwright/test';

// P6: critical journey #1 — login.
test.describe('login', () => {
  test('rejects bad credentials', async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel(/email/i).fill('nope@example.com');
    await page.getByLabel(/password/i).fill('badpassword');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page.getByRole('alert')).toContainText(/invalid/i);
  });

  test('happy path', async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel(/email/i).fill('demo@taskflow.dev');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page).toHaveURL(/\/projects/);
  });
});
