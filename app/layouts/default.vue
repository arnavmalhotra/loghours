<template>
  <div class="min-h-screen bg-gray-100">
    <nav class="bg-white shadow-sm">
      <div class="max-w-3xl mx-auto px-4 py-3 flex justify-between items-center">
        <NuxtLink to="/" class="text-xl font-bold text-gray-800 hover:text-gray-600">Hour Logger</NuxtLink>
        <div v-if="user" class="flex items-center gap-4">
          <button
            class="text-sm text-gray-500 hover:text-red-500 transition-colors"
            @click="logout"
          >
            Sign Out
          </button>
        </div>
      </div>
    </nav>
    <main class="max-w-3xl mx-auto px-4 py-8">
      <slot />
    </main>
  </div>
</template>

<script setup lang="ts">
const user = useSupabaseUser()
const client = useSupabaseClient()

async function logout() {
  await client.auth.signOut()
  navigateTo('/login')
}
</script>
