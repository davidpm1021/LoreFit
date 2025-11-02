import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import Home from '@/app/page';

describe('Home Page', () => {
  it('renders the welcome message', () => {
    render(<Home />);
    expect(screen.getByText('Welcome to LoreFit')).toBeInTheDocument();
  });

  it('renders the tagline', () => {
    render(<Home />);
    expect(
      screen.getByText('Earn story contributions through fitness achievements')
    ).toBeInTheDocument();
  });
});
