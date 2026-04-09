export interface TimeLog {
  id: string
  user_id: string
  start_time: string
  end_time: string
  duration: number
  notes: string | null
  latitude: number | null
  longitude: number | null
  location_name: string | null
  payout_id: string | null
  created_at: string
}

export interface Payout {
  id: string
  user_id: string
  total_duration: number
  total_amount: number
  hourly_rate: number
  created_at: string
}
