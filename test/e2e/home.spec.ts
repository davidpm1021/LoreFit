import { test, expect } from '@playwright/test';

test('homepage loads successfully', async ({ page }) => {
  await page.goto('/');

  // Check that the main heading is visible
  await expect(page.getByRole('heading', { name: 'Welcome to LoreFit' })).toBeVisible();

  // Check that the tagline is present
  await expect(
    page.getByText('Earn story contributions through fitness achievements')
  ).toBeVisible();
});

test('page has correct title', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle(/LoreFit/);
});
