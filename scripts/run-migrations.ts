import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ Missing Supabase credentials in .env.local');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function runMigrations() {
  console.log('🚀 Starting database migrations...\n');

  const migrationsDir = path.join(process.cwd(), 'supabase', 'migrations');
  const migrationFiles = fs
    .readdirSync(migrationsDir)
    .filter((file) => file.endsWith('.sql'))
    .sort();

  for (const file of migrationFiles) {
    console.log(`📄 Running migration: ${file}`);
    const sqlPath = path.join(migrationsDir, file);
    const sql = fs.readFileSync(sqlPath, 'utf-8');

    try {
      const { error } = await supabase.rpc('exec_sql', { sql_string: sql });

      if (error) {
        // Try direct execution if RPC doesn't exist
        const { error: directError } = await (supabase as any).from('_').select(sql);

        if (directError) {
          console.error(`❌ Error in ${file}:`, directError.message);
          console.log('\n⚠️  Please run this migration manually in Supabase SQL Editor\n');
        } else {
          console.log(`✅ ${file} completed\n`);
        }
      } else {
        console.log(`✅ ${file} completed\n`);
      }
    } catch (err) {
      console.error(`❌ Error running ${file}:`, err);
      console.log('\n⚠️  Please run migrations manually in Supabase SQL Editor');
      console.log('   Go to: https://supabase.com/dashboard/project/ohgbmxgvxrzvljuhhchy/sql\n');
      process.exit(1);
    }
  }

  console.log('✅ All migrations completed!');
}

runMigrations();
