import Link from 'next/link';

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24 bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="z-10 w-full max-w-5xl items-center justify-center text-sm lg:flex lg:flex-col">
        <h1 className="text-5xl font-bold text-center text-gray-900 mb-4">
          Welcome to LoreFit
        </h1>
        <p className="text-xl text-center text-gray-600 mb-12">
          Earn story contributions through fitness achievements
        </p>

        <div className="flex gap-4 justify-center">
          <Link
            href="/auth/signup"
            className="px-8 py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 transition-colors shadow-lg"
          >
            Get Started
          </Link>
          <Link
            href="/auth/login"
            className="px-8 py-3 bg-white text-blue-600 font-semibold rounded-lg hover:bg-gray-50 transition-colors shadow-lg border-2 border-blue-600"
          >
            Sign In
          </Link>
        </div>

        <div className="mt-16 grid grid-cols-1 md:grid-cols-3 gap-8 max-w-4xl">
          <div className="bg-white p-6 rounded-lg shadow-lg">
            <div className="text-4xl mb-4">💪</div>
            <h3 className="text-lg font-semibold mb-2">Track Workouts</h3>
            <p className="text-gray-600 text-sm">
              Log your fitness activities and sync with Strava or Fitbit
            </p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow-lg">
            <div className="text-4xl mb-4">🏆</div>
            <h3 className="text-lg font-semibold mb-2">Earn Points</h3>
            <p className="text-gray-600 text-sm">
              Complete challenges and level up through gamification
            </p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow-lg">
            <div className="text-4xl mb-4">📖</div>
            <h3 className="text-lg font-semibold mb-2">Create Stories</h3>
            <p className="text-gray-600 text-sm">
              Use points to contribute to collaborative fitness stories
            </p>
          </div>
        </div>
      </div>
    </main>
  );
}
