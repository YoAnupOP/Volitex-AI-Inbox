<script setup>
import { useAttrs } from 'vue';
const attrs = useAttrs();
</script>

<template>
  <svg
    v-bind="attrs"
    viewBox="0 0 100 100"
    xmlns="http://www.w3.org/2000/svg"
    class="text-black dark:text-white transition-colors duration-200"
  >
    <path fill-rule="evenodd" d="M10 10H90L50 90ZM27 10H73L50 77Z" fill="currentColor" />
  </svg>
</template>
