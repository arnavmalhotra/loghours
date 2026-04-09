-- Run this in your Supabase SQL editor to set up the database

-- Time logs table
create table time_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null default auth.uid(),
  start_time timestamptz not null,
  end_time timestamptz not null,
  duration integer not null, -- seconds
  notes text,
  latitude double precision,
  longitude double precision,
  location_name text,
  created_at timestamptz default now()
);

-- Enable RLS
alter table time_logs enable row level security;

-- Users can only access their own logs
create policy "Users can view own logs"
  on time_logs for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own logs"
  on time_logs for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own logs"
  on time_logs for update
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can delete own logs"
  on time_logs for delete
  to authenticated
  using (auth.uid() = user_id);

-- Payouts table
create table payouts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null default auth.uid(),
  total_duration integer not null, -- seconds
  total_amount numeric(10,2) not null, -- dollar amount
  hourly_rate numeric(10,2) not null default 20.00,
  created_at timestamptz default now()
);

-- Add payout reference to time_logs
alter table time_logs add column payout_id uuid references payouts(id);

-- Enable RLS on payouts
alter table payouts enable row level security;

create policy "Users can view own payouts"
  on payouts for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own payouts"
  on payouts for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can delete own payouts"
  on payouts for delete
  to authenticated
  using (auth.uid() = user_id);
