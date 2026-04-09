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
  created_at: string
}
