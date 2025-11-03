import { createClient } from '@/lib/supabase/client';
import type { User } from '@supabase/supabase-js';

export interface SignUpData {
  email: string;
  password: string;
  username: string;
  displayName: string;
}

export interface LoginData {
  email: string;
  password: string;
}

export interface AuthError {
  message: string;
  field?: string;
}

/**
 * Sign up a new user
 */
export async function signUp(data: SignUpData): Promise<{ user: User | null; error: AuthError | null }> {
  const supabase = createClient();

  try {
    // First, check if username is available
    const { data: existingUser, error: checkError } = await supabase
      .from('profiles')
      .select('username')
      .eq('username', data.username)
      .maybeSingle();

    // If we got data back, username is taken
    if (existingUser) {
      return {
        user: null,
        error: { message: 'Username already taken', field: 'username' },
      };
    }

    // Ignore "not found" errors - that's what we want
    // But if there's a real error (not PGRST116), return it
    if (checkError && checkError.code !== 'PGRST116') {
      return {
        user: null,
        error: { message: checkError.message },
      };
    }

    // Create auth user
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: data.email,
      password: data.password,
      options: {
        data: {
          username: data.username,
          display_name: data.displayName,
        },
      },
    });

    if (authError) {
      return {
        user: null,
        error: { message: authError.message },
      };
    }

    // Note: Profile will be created automatically via trigger
    return { user: authData.user, error: null };
  } catch (err) {
    return {
      user: null,
      error: { message: err instanceof Error ? err.message : 'An unknown error occurred' },
    };
  }
}

/**
 * Log in an existing user
 */
export async function login(data: LoginData): Promise<{ user: User | null; error: AuthError | null }> {
  const supabase = createClient();

  try {
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: data.email,
      password: data.password,
    });

    if (authError) {
      return {
        user: null,
        error: { message: authError.message },
      };
    }

    return { user: authData.user, error: null };
  } catch (err) {
    return {
      user: null,
      error: { message: err instanceof Error ? err.message : 'An unknown error occurred' },
    };
  }
}

/**
 * Log out the current user
 */
export async function logout(): Promise<{ error: AuthError | null }> {
  const supabase = createClient();

  try {
    const { error } = await supabase.auth.signOut();

    if (error) {
      return { error: { message: error.message } };
    }

    return { error: null };
  } catch (err) {
    return {
      error: { message: err instanceof Error ? err.message : 'An unknown error occurred' },
    };
  }
}

/**
 * Get the current user
 */
export async function getCurrentUser(): Promise<User | null> {
  const supabase = createClient();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    return user;
  } catch {
    return null;
  }
}

/**
 * Send password reset email
 */
export async function resetPassword(email: string): Promise<{ error: AuthError | null }> {
  const supabase = createClient();

  try {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${process.env.NEXT_PUBLIC_APP_URL}/auth/reset-password`,
    });

    if (error) {
      return { error: { message: error.message } };
    }

    return { error: null };
  } catch (err) {
    return {
      error: { message: err instanceof Error ? err.message : 'An unknown error occurred' },
    };
  }
}

/**
 * Update password (must be called after reset)
 */
export async function updatePassword(newPassword: string): Promise<{ error: AuthError | null }> {
  const supabase = createClient();

  try {
    const { error } = await supabase.auth.updateUser({
      password: newPassword,
    });

    if (error) {
      return { error: { message: error.message } };
    }

    return { error: null };
  } catch (err) {
    return {
      error: { message: err instanceof Error ? err.message : 'An unknown error occurred' },
    };
  }
}

/**
 * Validate email format
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Validate password strength
 */
export function validatePassword(password: string): { valid: boolean; message?: string } {
  if (password.length < 8) {
    return { valid: false, message: 'Password must be at least 8 characters' };
  }

  if (!/[A-Z]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one uppercase letter' };
  }

  if (!/[a-z]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one lowercase letter' };
  }

  if (!/[0-9]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one number' };
  }

  return { valid: true };
}

/**
 * Validate username format
 */
export function validateUsername(username: string): { valid: boolean; message?: string } {
  if (username.length < 3) {
    return { valid: false, message: 'Username must be at least 3 characters' };
  }

  if (username.length > 20) {
    return { valid: false, message: 'Username must be no more than 20 characters' };
  }

  if (!/^[a-zA-Z0-9_]+$/.test(username)) {
    return { valid: false, message: 'Username can only contain letters, numbers, and underscores' };
  }

  return { valid: true };
}
