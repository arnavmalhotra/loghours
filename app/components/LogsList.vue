<template>
  <div class="bg-white rounded-lg shadow-md p-6">
    <div class="flex justify-between items-center mb-6">
      <h2 class="text-2xl font-bold text-gray-800">Time Logs</h2>
      <span v-if="logs.length" class="text-sm text-gray-600">
        Total: <span class="font-bold text-gray-800">{{ totalHours }}</span>
      </span>
    </div>

    <p v-if="!logs.length" class="text-center text-gray-500 py-8">
      No logs yet. Start tracking your time!
    </p>

    <div v-else class="space-y-6">
      <div
        v-for="[date, dateLogs] in logsByDate"
        :key="date"
        class="border-b border-gray-200 last:border-0 pb-4"
      >
        <div class="flex justify-between items-center mb-3">
          <h3 class="text-lg font-semibold text-gray-700">{{ date }}</h3>
          <span class="text-sm text-gray-600 font-medium">
            Day: {{ dayTotal(dateLogs) }}
          </span>
        </div>

        <div class="space-y-2">
          <div
            v-for="log in dateLogs"
            :key="log.id"
            class="p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
          >
            <div class="flex justify-between items-center">
              <div class="flex-1">
                <span class="text-sm text-gray-600">
                  {{ fmtTime(log.start_time) }} - {{ fmtTime(log.end_time) }}
                </span>
                <span class="ml-4 font-medium text-gray-800">
                  {{ formatDuration(log.duration) }}
                </span>
                <span v-if="log.location_name" class="ml-3 text-xs text-gray-400">
                  {{ log.location_name }}
                </span>
              </div>
              <button
                class="ml-4 px-3 py-1 text-sm text-red-600 hover:bg-red-50 rounded transition-colors"
                @click="$emit('delete', log.id)"
              >
                Delete
              </button>
            </div>

            <!-- Notes -->
            <div class="mt-2">
              <div v-if="editingId === log.id" class="flex gap-2">
                <input
                  v-model="editText"
                  type="text"
                  placeholder="Add a note..."
                  class="flex-1 px-2 py-1 text-sm border border-gray-300 rounded focus:outline-none focus:ring-1 focus:ring-blue-500"
                  @keyup.enter="saveNote(log.id)"
                />
                <button
                  class="px-2 py-1 text-xs bg-blue-500 text-white rounded hover:bg-blue-600"
                  @click="saveNote(log.id)"
                >
                  Save
                </button>
                <button
                  class="px-2 py-1 text-xs bg-gray-300 rounded hover:bg-gray-400"
                  @click="editingId = null"
                >
                  Cancel
                </button>
              </div>
              <button
                v-else
                class="text-xs text-gray-400 hover:text-blue-500"
                @click="startEdit(log)"
              >
                {{ log.notes || 'Add note...' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { TimeLog } from '~/types'

const props = defineProps<{ logs: TimeLog[] }>()
const emit = defineEmits<{
  delete: [id: string]
  'update-notes': [id: string, notes: string]
}>()

const editingId = ref<string | null>(null)
const editText = ref('')

function startEdit(log: TimeLog) {
  editingId.value = log.id
  editText.value = log.notes || ''
}

function saveNote(id: string) {
  emit('update-notes', id, editText.value)
  editingId.value = null
}

const logsByDate = computed(() => {
  const grouped = new Map<string, TimeLog[]>()
  for (const log of props.logs) {
    const date = new Date(log.start_time).toLocaleDateString()
    if (!grouped.has(date)) grouped.set(date, [])
    grouped.get(date)!.push(log)
  }
  return [...grouped.entries()]
})

const totalHours = computed(() => {
  const total = props.logs.reduce((s, l) => s + l.duration, 0)
  const h = Math.floor(total / 3600)
  const m = Math.floor((total % 3600) / 60)
  return `${h}h ${m}m`
})

function dayTotal(logs: TimeLog[]) {
  const total = logs.reduce((s, l) => s + l.duration, 0)
  const h = Math.floor(total / 3600)
  const m = Math.floor((total % 3600) / 60)
  return `${h}h ${m}m`
}

function fmtTime(iso: string) {
  return new Date(iso).toLocaleTimeString()
}

function formatDuration(seconds: number) {
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  const s = seconds % 60
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}
</script>
