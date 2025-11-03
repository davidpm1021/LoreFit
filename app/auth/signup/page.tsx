'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { FormInput } from '@/components/auth/FormInput';
import { FormButton } from '@/components/auth/FormButton';
import { signUp } from '@/lib/auth/utils';
import { validatePassword, validateUsername, isValidEmail } from '@/lib/auth/utils';
import { useRedirectIfAuthenticated } from '@/lib/auth/hooks';

export default function SignUpPage() {
  // Redirect if already authenticated
  useRedirectIfAuthenticated('/dashboard');

  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    username: '',
    displayName: '',
  });

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    // Email validation
    if (!formData.email) {
      newErrors.email = 'Email is required';
    } else if (!isValidEmail(formData.email)) {
      newErrors.email = 'Please enter a valid email';
    }

    // Password validation
    if (!formData.password) {
      newErrors.password = 'Password is required';
    } else {
      const passwordCheck = validatePassword(formData.password);
      if (!passwordCheck.valid) {
        newErrors.password = passwordCheck.message!;
      }
    }

    // Confirm password
    if (!formData.confirmPassword) {
      newErrors.confirmPassword = 'Please confirm your password';
    } else if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }

    // Username validation
    if (!formData.username) {
      newErrors.username = 'Username is required';
    } else {
      const usernameCheck = validateUsername(formData.username);
      if (!usernameCheck.valid) {
        newErrors.username = usernameCheck.message!;
      }
    }

    // Display name validation
    if (!formData.displayName) {
      newErrors.displayName = 'Display name is required';
    } else if (formData.displayName.length < 2) {
      newErrors.displayName = 'Display name must be at least 2 characters';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) return;

    setLoading(true);
    setErrors({});

    const { user, error } = await signUp({
      email: formData.email,
      password: formData.password,
      username: formData.username,
      displayName: formData.displayName,
    });

    if (error) {
      setErrors({ [error.field || 'general']: error.message });
      setLoading(false);
      return;
    }

    if (user) {
      // Redirect to dashboard or welcome page
      router.push('/dashboard');
    }
  };

  const handleChange = (field: string) => (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({ ...formData, [field]: e.target.value });
    // Clear error for this field when user starts typing
    if (errors[field]) {
      setErrors({ ...errors, [field]: '' });
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full bg-white rounded-xl shadow-lg p-8">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Create Account</h1>
          <p className="mt-2 text-gray-600">Join LoreFit and start your fitness journey</p>
        </div>

        {errors.general && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-600 text-sm">
            {errors.general}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <FormInput
            label="Email"
            type="email"
            value={formData.email}
            onChange={handleChange('email')}
            error={errors.email}
            placeholder="you@example.com"
            autoComplete="email"
          />

          <FormInput
            label="Username"
            type="text"
            value={formData.username}
            onChange={handleChange('username')}
            error={errors.username}
            placeholder="fitness_warrior"
            autoComplete="username"
          />

          <FormInput
            label="Display Name"
            type="text"
            value={formData.displayName}
            onChange={handleChange('displayName')}
            error={errors.displayName}
            placeholder="John Doe"
            autoComplete="name"
          />

          <FormInput
            label="Password"
            type="password"
            value={formData.password}
            onChange={handleChange('password')}
            error={errors.password}
            placeholder="••••••••"
            autoComplete="new-password"
          />

          <FormInput
            label="Confirm Password"
            type="password"
            value={formData.confirmPassword}
            onChange={handleChange('confirmPassword')}
            error={errors.confirmPassword}
            placeholder="••••••••"
            autoComplete="new-password"
          />

          <div className="mt-6">
            <FormButton type="submit" loading={loading}>
              Create Account
            </FormButton>
          </div>
        </form>

        <div className="mt-6 text-center">
          <p className="text-sm text-gray-600">
            Already have an account?{' '}
            <Link href="/auth/login" className="font-medium text-blue-600 hover:text-blue-500">
              Sign in
            </Link>
          </p>
        </div>

        <div className="mt-4 text-xs text-gray-500 text-center">
          <p>Password must contain:</p>
          <ul className="list-disc list-inside mt-1">
            <li>At least 8 characters</li>
            <li>One uppercase letter</li>
            <li>One lowercase letter</li>
            <li>One number</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
