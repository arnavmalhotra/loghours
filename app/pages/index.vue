<template>
  <div>
    <TimeTracker @new-log="addLog" />
    <LogsList :logs="logs" @delete="deleteLog" @update-notes="updateNotes" />
  </div>
</template>

<script setup lang="ts">
import type { TimeLog } from '~/types'

const client = useSupabaseClient()
const user = useSupabaseUser()

const logs = ref<TimeLog[]>([])

async function fetchLogs() {
  const { data } = await client
    .from('time_logs')
    .select('*')
    .order('start_time', { ascending: false })

  if (data) logs.value = data as TimeLog[]
}

async function addLog(log: Omit<TimeLog, 'id' | 'created_at'>) {
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

onMounted(fetchLogs)
</script>
