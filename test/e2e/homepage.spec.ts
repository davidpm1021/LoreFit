import { test, expect } from '@playwright/test';

test.describe('Homepage', () => {
  test('loads successfully with correct content', async ({ page }) => {
    await page.goto('/');

    // Check page title
    await expect(page).toHaveTitle(/LoreFit/);

    // Check main heading is visible
    const heading = page.getByRole('heading', { name: 'Welcome to LoreFit' });
    await expect(heading).toBeVisible();

    // Check tagline is present
    const tagline = page.getByText('Earn story contributions through fitness achievements');
    await expect(tagline).toBeVisible();
  });

  test('is responsive on mobile', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');

    // Content should still be visible on mobile
    await expect(page.getByText('Welcome to LoreFit')).toBeVisible();
    await expect(page.getByText('Earn story contributions')).toBeVisible();
  });

  test('is responsive on tablet', async ({ page }) => {
    // Set tablet viewport
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.goto('/');

    // Content should be visible on tablet
    await expect(page.getByText('Welcome to LoreFit')).toBeVisible();
  });

  test('has no console errors', async ({ page }) => {
    const consoleErrors: string[] = [];

    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      }
    });

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Should have no console errors
    expect(consoleErrors).toHaveLength(0);
  });

  test('has proper meta tags', async ({ page }) => {
    await page.goto('/');

    // Check for description meta tag
    const description = await page.locator('meta[name="description"]').getAttribute('content');
    expect(description).toContain('Earn story contributions through fitness achievements');
  });
});
