<template>
  <div>
    <TimeTracker @new-log="addLog" />

    <!-- Payout summary bar -->
    <div v-if="unpaidLogs.length" class="bg-white rounded-lg shadow-md p-4 mb-4 flex justify-between items-center">
      <div>
        <span class="text-gray-600 text-sm">Unpaid hours:</span>
        <span class="ml-2 font-bold text-gray-800">{{ totalUnpaidHours }}</span>
        <span class="ml-4 text-gray-600 text-sm">@ ${{ HOURLY_RATE }}/hr =</span>
        <span class="ml-2 font-bold text-green-600 text-lg">${{ totalUnpaidAmount }}</span>
      </div>
      <button
        class="px-5 py-2 bg-green-600 text-white font-semibold rounded-lg hover:bg-green-700 transition-colors shadow-md"
        :disabled="payingOut"
        @click="confirmPayout"
      >
        {{ payingOut ? 'Processing...' : 'Payout' }}
      </button>
    </div>

    <LogsList :logs="unpaidLogs" @delete="deleteLog" @update-notes="updateNotes" />
  </div>
</template>

<script setup lang="ts">
import type { TimeLog } from '~/types'

const HOURLY_RATE = 20

const client = useSupabaseClient()
const user = useSupabaseUser()

const logs = ref<TimeLog[]>([])
const payingOut = ref(false)

const unpaidLogs = computed(() => logs.value.filter(l => !l.payout_id))

const totalUnpaidSeconds = computed(() => unpaidLogs.value.reduce((s, l) => s + l.duration, 0))

const totalUnpaidHours = computed(() => {
  const h = Math.floor(totalUnpaidSeconds.value / 3600)
  const m = Math.floor((totalUnpaidSeconds.value % 3600) / 60)
  return `${h}h ${m}m`
})

const totalUnpaidAmount = computed(() => {
  return (totalUnpaidSeconds.value / 3600 * HOURLY_RATE).toFixed(2)
})

async function fetchLogs() {
  const { data } = await client
    .from('time_logs')
    .select('*')
    .order('start_time', { ascending: false })

  if (data) logs.value = data as TimeLog[]
}

async function addLog(log: Omit<TimeLog, 'id' | 'created_at' | 'payout_id'>) {
  const { data, error } = await client
    .from('time_logs')
    .insert(log)
    .select()
    .single()

  if (data) {
    logs.value.unshift(data as TimeLog)
  }
  if (error) console.error('Failed to save log:', error)
}

async function deleteLog(id: string) {
  await client.from('time_logs').delete().eq('id', id)
  logs.value = logs.value.filter(l => l.id !== id)
}

async function updateNotes(id: string, notes: string) {
  await client.from('time_logs').update({ notes }).eq('id', id)
  const log = logs.value.find(l => l.id === id)
  if (log) log.notes = notes
}

async function confirmPayout() {
  if (!unpaidLogs.value.length) return
  const amount = totalUnpaidAmount.value
  const hours = totalUnpaidHours.value
  if (!confirm(`Process payout of $${amount} for ${hours}? This will archive these hours.`)) return

  payingOut.value = true
  try {
    // Create payout record
    const { data: payout, error: payoutError } = await client
      .from('payouts')
      .insert({
        total_duration: totalUnpaidSeconds.value,
        total_amount: parseFloat(amount),
        hourly_rate: HOURLY_RATE,
      })
      .select()
      .single()

    if (payoutError || !payout) {
      console.error('Failed to create payout:', payoutError)
      return
    }

    // Link all unpaid logs to this payout
    const ids = unpaidLogs.value.map(l => l.id)
    const { error: updateError } = await client
      .from('time_logs')
      .update({ payout_id: (payout as any).id })
      .in('id', ids)

    if (updateError) {
      console.error('Failed to update logs:', updateError)
      return
    }

    // Update local state
    for (const log of logs.value) {
      if (ids.includes(log.id)) {
        log.payout_id = (payout as any).id
      }
    }
  } finally {
    payingOut.value = false
  }
}

onMounted(fetchLogs)
</script>
