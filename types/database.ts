// Database types for LoreFit
// These match the Supabase schema

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          username: string;
          display_name: string | null;
          avatar_url: string | null;
          bio: string | null;
          fitness_level: 'beginner' | 'intermediate' | 'advanced' | null;
          height_cm: number | null;
          weight_kg: number | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          username: string;
          display_name?: string | null;
          avatar_url?: string | null;
          bio?: string | null;
          fitness_level?: 'beginner' | 'intermediate' | 'advanced' | null;
          height_cm?: number | null;
          weight_kg?: number | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          username?: string;
          display_name?: string | null;
          avatar_url?: string | null;
          bio?: string | null;
          fitness_level?: 'beginner' | 'intermediate' | 'advanced' | null;
          height_cm?: number | null;
          weight_kg?: number | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      user_points: {
        Row: {
          user_id: string;
          current_balance: number;
          total_earned: number;
          total_spent: number;
          level: number;
          points_history: Json;
          weekly_goal: number;
          updated_at: string;
        };
        Insert: {
          user_id: string;
          current_balance?: number;
          total_earned?: number;
          total_spent?: number;
          level?: number;
          points_history?: Json;
          weekly_goal?: number;
          updated_at?: string;
        };
        Update: {
          user_id?: string;
          current_balance?: number;
          total_earned?: number;
          total_spent?: number;
          level?: number;
          points_history?: Json;
          weekly_goal?: number;
          updated_at?: string;
        };
      };
      workouts: {
        Row: {
          id: string;
          user_id: string;
          workout_date: string;
          workout_type: string;
          duration_minutes: number | null;
          distance_km: number | null;
          calories_burned: number | null;
          heart_rate_avg: number | null;
          source: 'manual' | 'strava' | 'fitbit';
          external_id: string | null;
          raw_data: Json | null;
          points_earned: number;
          created_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          workout_date: string;
          workout_type: string;
          duration_minutes?: number | null;
          distance_km?: number | null;
          calories_burned?: number | null;
          heart_rate_avg?: number | null;
          source: 'manual' | 'strava' | 'fitbit';
          external_id?: string | null;
          raw_data?: Json | null;
          points_earned?: number;
          created_at?: string;
        };
        Update: {
          id?: string;
          user_id?: string;
          workout_date?: string;
          workout_type?: string;
          duration_minutes?: number | null;
          distance_km?: number | null;
          calories_burned?: number | null;
          heart_rate_avg?: number | null;
          source?: 'manual' | 'strava' | 'fitbit';
          external_id?: string | null;
          raw_data?: Json | null;
          points_earned?: number;
          created_at?: string;
        };
      };
      activity_sync: {
        Row: {
          id: string;
          user_id: string;
          source: 'strava' | 'fitbit';
          last_sync: string | null;
          sync_status: 'active' | 'error' | 'revoked' | 'pending' | null;
          access_token_encrypted: string | null;
          refresh_token_encrypted: string | null;
          token_expires_at: string | null;
          webhook_id: string | null;
          error_message: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          source: 'strava' | 'fitbit';
          last_sync?: string | null;
          sync_status?: 'active' | 'error' | 'revoked' | 'pending' | null;
          access_token_encrypted?: string | null;
          refresh_token_encrypted?: string | null;
          token_expires_at?: string | null;
          webhook_id?: string | null;
          error_message?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          user_id?: string;
          source?: 'strava' | 'fitbit';
          last_sync?: string | null;
          sync_status?: 'active' | 'error' | 'revoked' | 'pending' | null;
          access_token_encrypted?: string | null;
          refresh_token_encrypted?: string | null;
          token_expires_at?: string | null;
          webhook_id?: string | null;
          error_message?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      user_baselines: {
        Row: {
          user_id: string;
          avg_weekly_workouts: number | null;
          avg_workout_duration: number | null;
          avg_weekly_distance: number | null;
          avg_daily_steps: number | null;
          baseline_calculated_at: string | null;
          data_points: number | null;
          updated_at: string;
        };
        Insert: {
          user_id: string;
          avg_weekly_workouts?: number | null;
          avg_workout_duration?: number | null;
          avg_weekly_distance?: number | null;
          avg_daily_steps?: number | null;
          baseline_calculated_at?: string | null;
          data_points?: number | null;
          updated_at?: string;
        };
        Update: {
          user_id?: string;
          avg_weekly_workouts?: number | null;
          avg_workout_duration?: number | null;
          avg_weekly_distance?: number | null;
          avg_daily_steps?: number | null;
          baseline_calculated_at?: string | null;
          data_points?: number | null;
          updated_at?: string;
        };
      };
      user_challenges: {
        Row: {
          id: string;
          user_id: string;
          challenge_type: 'weekly' | 'monthly' | 'special';
          title: string;
          description: string | null;
          target_value: number;
          current_value: number;
          metric: 'workouts' | 'minutes' | 'distance' | 'calories' | 'points';
          status: 'active' | 'completed' | 'failed' | 'expired';
          points_reward: number | null;
          starts_at: string;
          ends_at: string;
          completed_at: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          challenge_type: 'weekly' | 'monthly' | 'special';
          title: string;
          description?: string | null;
          target_value: number;
          current_value?: number;
          metric: 'workouts' | 'minutes' | 'distance' | 'calories' | 'points';
          status?: 'active' | 'completed' | 'failed' | 'expired';
          points_reward?: number | null;
          starts_at?: string;
          ends_at: string;
          completed_at?: string | null;
          created_at?: string;
        };
        Update: {
          id?: string;
          user_id?: string;
          challenge_type?: 'weekly' | 'monthly' | 'special';
          title?: string;
          description?: string | null;
          target_value?: number;
          current_value?: number;
          metric?: 'workouts' | 'minutes' | 'distance' | 'calories' | 'points';
          status?: 'active' | 'completed' | 'failed' | 'expired';
          points_reward?: number | null;
          starts_at?: string;
          ends_at?: string;
          completed_at?: string | null;
          created_at?: string;
        };
      };
    };
    Functions: {
      award_points: {
        Args: {
          p_user_id: string;
          p_amount: number;
          p_source?: string;
          p_description?: string;
        };
        Returns: {
          new_balance: number;
          new_total_earned: number;
        }[];
      };
      spend_points: {
        Args: {
          p_user_id: string;
          p_amount: number;
          p_purpose?: string;
          p_description?: string;
        };
        Returns: {
          new_balance: number;
          success: boolean;
        }[];
      };
      check_challenge_completion: {
        Args: {
          p_challenge_id: string;
        };
        Returns: boolean;
      };
      expire_old_challenges: {
        Args: Record<string, never>;
        Returns: number;
      };
    };
  };
}

// Helper types
export type Tables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Row'];
export type Inserts<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Insert'];
export type Updates<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Update'];

// Specific table types for convenience
export type Profile = Tables<'profiles'>;
export type UserPoints = Tables<'user_points'>;
export type Workout = Tables<'workouts'>;
export type ActivitySync = Tables<'activity_sync'>;
export type UserBaseline = Tables<'user_baselines'>;
export type UserChallenge = Tables<'user_challenges'>;
