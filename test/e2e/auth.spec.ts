import { test, expect } from '@playwright/test';

test.describe('Authentication Flow', () => {
  // Generate unique test credentials for each run
  const testEmail = `test-${Date.now()}@example.com`;
  const testUsername = `testuser${Date.now()}`;
  const testDisplayName = 'Test User';
  const testPassword = 'TestPass123';

  test('complete signup and login flow', async ({ page }) => {
    // Step 1: Navigate to signup page
    await page.goto('/auth/signup');
    await expect(page).toHaveURL(/\/auth\/signup/);
    await expect(page.getByRole('heading', { name: 'Create Account' })).toBeVisible();

    // Step 2: Fill out signup form
    await page.getByLabel('Email').fill(testEmail);
    await page.getByLabel('Username').fill(testUsername);
    await page.getByLabel('Display Name').fill(testDisplayName);
    await page.getByLabel('Password', { exact: true }).fill(testPassword);
    await page.getByLabel('Confirm Password').fill(testPassword);

    // Step 3: Submit signup form
    await page.getByRole('button', { name: 'Create Account' }).click();

    // Step 4: Should redirect to dashboard
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 10000 });
    await expect(page.getByText(`Welcome, ${testDisplayName}!`)).toBeVisible({ timeout: 5000 });
    await expect(page.getByText(`@${testUsername}`)).toBeVisible();

    // Step 5: Sign out
    await page.getByRole('button', { name: 'Sign Out' }).click();
    await expect(page).toHaveURL('/', { timeout: 5000 });

    // Step 6: Navigate to login page
    await page.goto('/auth/login');
    await expect(page).toHaveURL(/\/auth\/login/);
    await expect(page.getByRole('heading', { name: 'Welcome Back' })).toBeVisible();

    // Step 7: Fill out login form
    await page.getByLabel('Email').fill(testEmail);
    await page.getByLabel('Password').fill(testPassword);

    // Step 8: Submit login form
    await page.getByRole('button', { name: 'Sign In' }).click();

    // Step 9: Should redirect to dashboard again
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 10000 });
    await expect(page.getByText(`Welcome, ${testDisplayName}!`)).toBeVisible({ timeout: 5000 });
  });

  test('signup form validation', async ({ page }) => {
    await page.goto('/auth/signup');

    // Try to submit empty form
    await page.getByRole('button', { name: 'Create Account' }).click();

    // Should show validation errors
    await expect(page.getByText('Email is required')).toBeVisible();
    await expect(page.getByText('Username is required')).toBeVisible();
    await expect(page.getByText('Display name is required')).toBeVisible();
    await expect(page.getByText('Password is required')).toBeVisible();

    // Test invalid email
    await page.getByLabel('Email').fill('invalid-email');
    await page.getByRole('button', { name: 'Create Account' }).click();
    await expect(page.getByText('Please enter a valid email')).toBeVisible();

    // Test weak password
    await page.getByLabel('Email').fill('test@example.com');
    await page.getByLabel('Password', { exact: true }).fill('weak');
    await page.getByRole('button', { name: 'Create Account' }).click();
    await expect(page.getByText(/Password must/)).toBeVisible();

    // Test password mismatch
    await page.getByLabel('Password', { exact: true }).fill('StrongPass123');
    await page.getByLabel('Confirm Password').fill('DifferentPass123');
    await page.getByRole('button', { name: 'Create Account' }).click();
    await expect(page.getByText('Passwords do not match')).toBeVisible();
  });

  test('login form validation', async ({ page }) => {
    await page.goto('/auth/login');

    // Try to submit empty form
    await page.getByRole('button', { name: 'Sign In' }).click();

    // Should show validation errors
    await expect(page.getByText('Email is required')).toBeVisible();
    await expect(page.getByText('Password is required')).toBeVisible();

    // Test invalid email
    await page.getByLabel('Email').fill('invalid-email');
    await page.getByRole('button', { name: 'Sign In' }).click();
    await expect(page.getByText('Please enter a valid email')).toBeVisible();
  });

  test('login with invalid credentials shows error', async ({ page }) => {
    await page.goto('/auth/login');

    // Fill with non-existent credentials
    await page.getByLabel('Email').fill('nonexistent@example.com');
    await page.getByLabel('Password').fill('WrongPassword123');

    // Submit
    await page.getByRole('button', { name: 'Sign In' }).click();

    // Should show error message
    await expect(page.getByText(/Invalid/i)).toBeVisible({ timeout: 5000 });
  });

  test('homepage has auth links', async ({ page }) => {
    await page.goto('/');

    // Should have signup and login buttons
    const signupButton = page.getByRole('link', { name: 'Get Started' });
    const loginButton = page.getByRole('link', { name: 'Sign In' });

    await expect(signupButton).toBeVisible();
    await expect(loginButton).toBeVisible();

    // Click signup button
    await signupButton.click();
    await expect(page).toHaveURL(/\/auth\/signup/);

    // Go back and click login button
    await page.goto('/');
    await loginButton.click();
    await expect(page).toHaveURL(/\/auth\/login/);
  });

  test('authenticated users redirected from auth pages', async ({ page }) => {
    // First, create and login a user
    await page.goto('/auth/signup');

    const email = `redirect-test-${Date.now()}@example.com`;
    const username = `redirecttest${Date.now()}`;

    await page.getByLabel('Email').fill(email);
    await page.getByLabel('Username').fill(username);
    await page.getByLabel('Display Name').fill('Redirect Test');
    await page.getByLabel('Password', { exact: true }).fill('TestPass123');
    await page.getByLabel('Confirm Password').fill('TestPass123');
    await page.getByRole('button', { name: 'Create Account' }).click();

    // Should be on dashboard
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 10000 });

    // Try to visit signup page - should redirect to dashboard
    await page.goto('/auth/signup');
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 5000 });

    // Try to visit login page - should redirect to dashboard
    await page.goto('/auth/login');
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 5000 });
  });
});
