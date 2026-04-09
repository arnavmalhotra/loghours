<template>
  <div class="bg-white rounded-lg shadow-md p-6 mb-8">
    <!-- Timer display -->
    <div class="text-center mb-6">
      <div class="text-5xl font-mono font-bold text-gray-800 mb-2">
        {{ formatDuration(elapsedTime) }}
      </div>
      <p v-if="isTracking && startTime" class="text-sm text-gray-600">
        Started at {{ startTime.toLocaleTimeString() }}
      </p>
      <p v-if="isTracking && locationName" class="text-xs text-gray-400 mt-1">
        {{ locationName }}
      </p>
    </div>

    <!-- Buttons -->
    <div class="flex justify-center gap-4">
      <template v-if="!isTracking">
        <button
          class="px-8 py-3 bg-green-500 text-white font-semibold rounded-lg hover:bg-green-600 transition-colors shadow-md"
          @click="handleStart"
        >
          Start
        </button>
        <button
          class="px-8 py-3 bg-blue-500 text-white font-semibold rounded-lg hover:bg-blue-600 transition-colors shadow-md"
          @click="showCustom = !showCustom"
        >
          Start from Past
        </button>
      </template>
      <button
        v-else
        class="px-8 py-3 bg-red-500 text-white font-semibold rounded-lg hover:bg-red-600 transition-colors shadow-md"
        @click="handleStop"
      >
        Stop
      </button>
    </div>

    <!-- Custom start time -->
    <div v-if="showCustom" class="mt-6 p-4 bg-gray-50 rounded-lg">
      <label class="block text-sm font-medium text-gray-700 mb-2">
        Select start date and time:
      </label>
      <div class="flex gap-2">
        <input
          v-model="customDateTime"
          type="datetime-local"
          class="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
        <button
          class="px-4 py-2 bg-blue-500 text-white font-medium rounded-md hover:bg-blue-600 transition-colors"
          @click="handleCustomStart"
        >
          Start
        </button>
        <button
          class="px-4 py-2 bg-gray-400 text-white font-medium rounded-md hover:bg-gray-500 transition-colors"
          @click="showCustom = false"
        >
          Cancel
        </button>
      </div>
    </div>

    <!-- Notes input (visible while tracking) -->
    <div v-if="isTracking" class="mt-6">
      <label class="block text-sm font-medium text-gray-700 mb-1">Notes (optional)</label>
      <textarea
        v-model="notes"
        rows="2"
        placeholder="What are you working on?"
        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
const emit = defineEmits<{
  'new-log': [log: {
    start_time: string
    end_time: string
    duration: number
    notes: string | null
    latitude: number | null
    longitude: number | null
    location_name: string | null
  }]
}>()

const isTracking = ref(false)
const startTime = ref<Date | null>(null)
const elapsedTime = ref(0)
const showCustom = ref(false)
const customDateTime = ref('')
const notes = ref('')
const latitude = ref<number | null>(null)
const longitude = ref<number | null>(null)
const locationName = ref<string | null>(null)

let interval: ReturnType<typeof setInterval> | null = null

const STORAGE_KEY = 'activeTimer'

function saveTimerState() {
  if (startTime.value) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({
      startTime: startTime.value.toISOString(),
      notes: notes.value,
      latitude: latitude.value,
      longitude: longitude.value,
      locationName: locationName.value,
    }))
  }
}

function clearTimerState() {
  localStorage.removeItem(STORAGE_KEY)
}

function restoreTimerState() {
  const saved = localStorage.getItem(STORAGE_KEY)
  if (!saved) return
  try {
    const state = JSON.parse(saved)
    startTime.value = new Date(state.startTime)
    notes.value = state.notes || ''
    latitude.value = state.latitude
    longitude.value = state.longitude
    locationName.value = state.locationName
    isTracking.value = true
    elapsedTime.value = Math.floor((Date.now() - startTime.value!.getTime()) / 1000)
    startInterval()
  } catch {
    clearTimerState()
  }
}

onMounted(restoreTimerState)

function captureLocation() {
  if (!navigator.geolocation) return
  navigator.geolocation.getCurrentPosition(
    async (pos) => {
      latitude.value = pos.coords.latitude
      longitude.value = pos.coords.longitude
      // Reverse geocode for a friendly name
      try {
        const res = await fetch(
          `https://nominatim.openstreetmap.org/reverse?lat=${pos.coords.latitude}&lon=${pos.coords.longitude}&format=json`
        )
        const data = await res.json()
        if (data.address) {
          const a = data.address
          locationName.value = [a.city || a.town || a.village, a.state, a.country]
            .filter(Boolean)
            .join(', ')
        }
      } catch {
        // location name is optional
      }
    },
    () => {
      // user denied location - that's fine
    }
  )
}

function handleStart() {
  startTime.value = new Date()
  isTracking.value = true
  elapsedTime.value = 0
  notes.value = ''
  captureLocation()
  saveTimerState()
  startInterval()
}

function handleCustomStart() {
  const d = new Date(customDateTime.value)
  startTime.value = d
  isTracking.value = true
  elapsedTime.value = Math.floor((Date.now() - d.getTime()) / 1000)
  notes.value = ''
  showCustom.value = false
  captureLocation()
  saveTimerState()
  startInterval()
}

function handleStop() {
  if (!startTime.value) return
  const endTime = new Date()
  const duration = Math.floor((endTime.getTime() - startTime.value.getTime()) / 1000)

  emit('new-log', {
    start_time: startTime.value.toISOString(),
    end_time: endTime.toISOString(),
    duration,
    notes: notes.value.trim() || null,
    latitude: latitude.value,
    longitude: longitude.value,
    location_name: locationName.value,
  })

  clearTimerState()
  isTracking.value = false
  startTime.value = null
  elapsedTime.value = 0
  notes.value = ''
  latitude.value = null
  longitude.value = null
  locationName.value = null
  if (interval) clearInterval(interval)
}

function startInterval() {
  if (interval) clearInterval(interval)
  interval = setInterval(() => {
    if (startTime.value) {
      elapsedTime.value = Math.floor((Date.now() - startTime.value.getTime()) / 1000)
    }
  }, 1000)
}

function formatDuration(seconds: number) {
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  const s = seconds % 60
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}

onUnmounted(() => {
  if (interval) clearInterval(interval)
})
</script>
