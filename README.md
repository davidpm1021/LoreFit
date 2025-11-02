# LoreFit

**Fitness-Powered Collaborative Storytelling**

LoreFit is a web application where users earn the right to contribute to collaborative stories through fitness achievements. Users connect fitness trackers (Strava, Fitbit) or manually log workouts to earn points, which they spend to add sentences to shared narratives.

## 🎯 Project Status

**Current Phase:** Sprint 0 - Foundation & Infrastructure
**Version:** 0.1.0 (MVP Development)

## 🚀 Getting Started

### Prerequisites

- Node.js 20.x or later
- npm or yarn
- Supabase account (for database and authentication)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/davidpm1021/LoreFit.git
cd LoreFit
```

2. Install dependencies:
```bash
npm install
```

3. Copy environment variables:
```bash
cp .env.example .env.local
```

4. Fill in your Supabase credentials in `.env.local`:
```env
NEXT_PUBLIC_SUPABASE_URL=your-project-url.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

5. Run the development server:
```bash
npm run dev
```

6. Open [http://localhost:3000](http://localhost:3000) in your browser.

## 📋 Available Scripts

### Development
- `npm run dev` - Start development server with Turbopack
- `npm run build` - Build for production
- `npm run start` - Start production server

### Code Quality
- `npm run lint` - Run ESLint
- `npm run type-check` - Run TypeScript type checking
- `npm run format` - Format code with Prettier
- `npm run format:check` - Check code formatting

### Testing
- `npm run test` - Run all unit tests
- `npm run test:unit` - Run unit tests
- `npm run test:integration` - Run integration tests
- `npm run test:e2e` - Run end-to-end tests with Playwright
- `npm run test:watch` - Run tests in watch mode

## 🏗️ Project Structure

```
lorefit/
├── app/                    # Next.js 15 App Router
│   ├── globals.css        # Global styles with Tailwind
│   ├── layout.tsx         # Root layout
│   └── page.tsx           # Home page
├── components/            # React components
├── lib/                   # Core utilities and logic
│   └── supabase/         # Supabase client configuration
├── hooks/                 # Custom React hooks
├── types/                 # TypeScript type definitions
├── public/               # Static assets
├── test/                 # Test files
│   ├── unit/            # Unit tests
│   ├── integration/     # Integration tests
│   └── e2e/             # End-to-end tests
└── migrations/          # Database migrations (future)
```

## 🛠️ Tech Stack

- **Framework:** Next.js 15 with App Router
- **Language:** TypeScript
- **Styling:** Tailwind CSS
- **Database & Auth:** Supabase
- **State Management:** Zustand + React Query
- **Real-time Collaboration:** Yjs CRDT
- **Testing:** Vitest + React Testing Library + Playwright
- **Deployment:** Vercel

## 📚 Documentation

- [Project Plan](./projectplan.md) - Complete technical specification
- [Sprint Plan](./SPRINTS.md) - 13-week development roadmap
- [CLAUDE.md](./CLAUDE.md) - AI assistant guidance

## 🔑 Environment Variables

See [.env.example](./.env.example) for all required environment variables.

### Required for Development
- `NEXT_PUBLIC_SUPABASE_URL` - Your Supabase project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` - Supabase anonymous key
- `SUPABASE_SERVICE_ROLE_KEY` - Supabase service role key (server-side only)

### Optional (MVP)
- Strava API credentials
- Fitbit API credentials
- Monitoring tools (Sentry)
- Rate limiting (Upstash Redis)

## 🧪 Testing

### Unit Tests
```bash
npm run test:unit
```

### End-to-End Tests
```bash
# Install Playwright browsers (first time only)
npx playwright install

# Run E2E tests
npm run test:e2e
```

## 🚢 Deployment

The project is configured for deployment on Vercel:

1. Push to GitHub
2. Connect repository to Vercel
3. Configure environment variables in Vercel dashboard
4. Deploy automatically on push to `main`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Quality Standards
- All tests must pass
- ESLint and TypeScript checks must pass
- Code must be formatted with Prettier
- Test coverage should not decrease

## 📝 License

This project is licensed under the MIT License.

## 🎮 Core Features (Planned)

- ✅ User authentication with Supabase
- ⏳ Fitness tracking (Strava, Fitbit, manual entry)
- ⏳ Gamification system with points and challenges
- ⏳ Real-time collaborative storytelling
- ⏳ Personalized fitness baselines
- ⏳ Story voting and quality control
- ⏳ Progressive Web App (offline support)

## 📞 Support

- Create an [Issue](https://github.com/davidpm1021/LoreFit/issues)
- Email: [Your email]

---

Built with ❤️ using Next.js 15 and Supabase
