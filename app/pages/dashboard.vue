<template>
  <div class="space-y-6">
    <!-- Summary cards -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <div class="bg-white rounded-lg shadow-md p-4">
        <p class="text-sm text-gray-500">Total Hours (All Time)</p>
        <p class="text-2xl font-bold text-gray-800">{{ fmtDur(stats.totalSeconds) }}</p>
      </div>
      <div class="bg-white rounded-lg shadow-md p-4">
        <p class="text-sm text-gray-500">Total Earned</p>
        <p class="text-2xl font-bold text-green-600">${{ fmtMoney(stats.totalSeconds) }}</p>
      </div>
      <div class="bg-white rounded-lg shadow-md p-4">
        <p class="text-sm text-gray-500">Unpaid Hours</p>
        <p class="text-2xl font-bold text-orange-600">{{ fmtDur(stats.unpaidSeconds) }}</p>
      </div>
      <div class="bg-white rounded-lg shadow-md p-4">
        <p class="text-sm text-gray-500">Unpaid Amount</p>
        <p class="text-2xl font-bold text-orange-600">${{ fmtMoney(stats.unpaidSeconds) }}</p>
      </div>
    </div>

    <!-- This week / this month -->
    <div class="grid grid-cols-2 gap-4">
      <div class="bg-white rounded-lg shadow-md p-4">
        <p class="text-sm text-gray-500">This Week</p>
        <p class="text-xl font-bold text-gray-800">{{ fmtDur(stats.weekSeconds) }}</p>
        <p class="text-sm text-green-600">${{ fmtMoney(stats.weekSeconds) }}</p>
      </div>
      <div class="bg-white rounded-lg shadow-md p-4">
        <p class="text-sm text-gray-500">This Month</p>
        <p class="text-xl font-bold text-gray-800">{{ fmtDur(stats.monthSeconds) }}</p>
        <p class="text-sm text-green-600">${{ fmtMoney(stats.monthSeconds) }}</p>
      </div>
    </div>

    <!-- Daily breakdown (last 14 days) -->
    <div class="bg-white rounded-lg shadow-md p-6">
      <h2 class="text-lg font-bold text-gray-800 mb-4">Last 14 Days</h2>
      <div v-if="dailyBreakdown.length" class="space-y-2">
        <div v-for="day in dailyBreakdown" :key="day.date" class="flex items-center gap-3">
          <span class="text-sm text-gray-600 w-24 shrink-0">{{ day.label }}</span>
          <div class="flex-1 bg-gray-100 rounded-full h-6 overflow-hidden">
            <div
              class="h-full bg-blue-500 rounded-full transition-all"
              :style="{ width: `${day.pct}%` }"
            />
          </div>
          <span class="text-sm font-medium text-gray-700 w-16 text-right">{{ fmtDur(day.seconds) }}</span>
          <span class="text-xs text-green-600 w-16 text-right">${{ fmtMoney(day.seconds) }}</span>
        </div>
      </div>
      <p v-else class="text-center text-gray-500 py-4">No data yet.</p>
    </div>

    <!-- Payout history -->
    <div class="bg-white rounded-lg shadow-md p-6">
      <h2 class="text-lg font-bold text-gray-800 mb-4">Payout History</h2>
      <div v-if="payouts.length" class="space-y-2">
        <div
          v-for="p in payouts"
          :key="p.id"
          class="flex justify-between items-center p-3 bg-gray-50 rounded-lg"
        >
          <div>
            <span class="text-sm text-gray-600">{{ new Date(p.created_at).toLocaleDateString() }}</span>
            <span class="ml-3 text-sm text-gray-500">{{ fmtDur(p.total_duration) }} @ ${{ p.hourly_rate }}/hr</span>
          </div>
          <span class="font-bold text-green-600">${{ Number(p.total_amount).toFixed(2) }}</span>
        </div>
      </div>
      <p v-else class="text-center text-gray-500 py-4">No payouts yet.</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { TimeLog, Payout } from '~/types'

const HOURLY_RATE = 20

const client = useSupabaseClient()

const logs = ref<TimeLog[]>([])
const payouts = ref<Payout[]>([])

const now = new Date()
const weekStart = new Date(now)
weekStart.setDate(now.getDate() - now.getDay())
weekStart.setHours(0, 0, 0, 0)

const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)

const stats = computed(() => {
  const totalSeconds = logs.value.reduce((s, l) => s + l.duration, 0)
  const unpaidSeconds = logs.value.filter(l => !l.payout_id).reduce((s, l) => s + l.duration, 0)
  const weekSeconds = logs.value
    .filter(l => new Date(l.start_time) >= weekStart)
    .reduce((s, l) => s + l.duration, 0)
  const monthSeconds = logs.value
    .filter(l => new Date(l.start_time) >= monthStart)
    .reduce((s, l) => s + l.duration, 0)
  return { totalSeconds, unpaidSeconds, weekSeconds, monthSeconds }
})

const dailyBreakdown = computed(() => {
  const days: { date: string; label: string; seconds: number; pct: number }[] = []
  const byDate = new Map<string, number>()

  for (const log of logs.value) {
    const d = new Date(log.start_time).toISOString().slice(0, 10)
    byDate.set(d, (byDate.get(d) || 0) + log.duration)
  }

  const today = new Date()
  for (let i = 13; i >= 0; i--) {
    const d = new Date(today)
    d.setDate(today.getDate() - i)
    const key = d.toISOString().slice(0, 10)
    const seconds = byDate.get(key) || 0
    days.push({
      date: key,
      label: d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' }),
      seconds,
      pct: 0,
    })
  }

  const max = Math.max(...days.map(d => d.seconds), 1)
  for (const day of days) {
    day.pct = (day.seconds / max) * 100
  }

  return days
})

function fmtDur(seconds: number) {
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  return `${h}h ${m}m`
}

function fmtMoney(seconds: number) {
  return (seconds / 3600 * HOURLY_RATE).toFixed(2)
}

onMounted(async () => {
  const [logsRes, payoutsRes] = await Promise.all([
    client.from('time_logs').select('*').order('start_time', { ascending: false }),
    client.from('payouts').select('*').order('created_at', { ascending: false }),
  ])
  if (logsRes.data) logs.value = logsRes.data as TimeLog[]
  if (payoutsRes.data) payouts.value = payoutsRes.data as Payout[]
})
</script>
