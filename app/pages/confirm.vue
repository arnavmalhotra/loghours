<template>
  <div class="flex items-center justify-center min-h-[80vh]">
    <p class="text-gray-600">Confirming your account...</p>
  </div>
</template>

<script setup lang="ts">
const user = useSupabaseUser()
watchEffect(() => {
  if (user.value) navigateTo('/')
})
</script>
