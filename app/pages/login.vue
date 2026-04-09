<template>
  <div class="flex items-center justify-center min-h-[80vh]">
    <div class="bg-white rounded-lg shadow-md p-8 w-full max-w-sm">
      <h2 class="text-2xl font-bold text-gray-800 text-center mb-6">Sign In</h2>

      <form @submit.prevent="handleAuth" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
          <input
            v-model="email"
            type="email"
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
          <input
            v-model="password"
            type="password"
            required
            minlength="6"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <p v-if="error" class="text-red-500 text-sm">{{ error }}</p>
        <p v-if="message" class="text-green-600 text-sm">{{ message }}</p>

        <button
          type="submit"
          :disabled="loading"
          class="w-full py-2 bg-blue-500 text-white font-semibold rounded-md hover:bg-blue-600 transition-colors disabled:opacity-50"
        >
          {{ loading ? 'Loading...' : (isSignUp ? 'Sign Up' : 'Sign In') }}
        </button>
      </form>

      <button
        class="w-full mt-3 text-sm text-blue-500 hover:underline"
        @click="isSignUp = !isSignUp"
      >
        {{ isSignUp ? 'Already have an account? Sign In' : "Don't have an account? Sign Up" }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const client = useSupabaseClient()
const user = useSupabaseUser()

const email = ref('')
const password = ref('')
const isSignUp = ref(false)
const loading = ref(false)
const error = ref('')
const message = ref('')

watchEffect(() => {
  if (user.value) navigateTo('/')
})

async function handleAuth() {
  loading.value = true
  error.value = ''
  message.value = ''

  if (isSignUp.value) {
    const { error: err } = await client.auth.signUp({
      email: email.value,
      password: password.value,
    })
    if (err) error.value = err.message
    else message.value = 'Check your email for a confirmation link!'
  } else {
    const { error: err } = await client.auth.signInWithPassword({
      email: email.value,
      password: password.value,
    })
    if (err) error.value = err.message
    else navigateTo('/')
  }

  loading.value = false
}
</script>
