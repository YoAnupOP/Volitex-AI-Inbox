<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import InstagramInboxNavigation from './InstagramInboxNavigation.vue';
import InstagramCommentsManager from '../settings/inbox/settingsPage/InstagramCommentsManager.vue';

const route = useRoute();
const store = useStore();

const inboxId = computed(() => route.params.inbox_id);
const inbox = computed(() => store.getters['inboxes/getInbox'](inboxId.value));
</script>

<template>
  <section
    class="flex h-full w-full min-w-0 flex-col overflow-y-auto bg-n-background"
  >
    <InstagramInboxNavigation :inbox-id="inboxId" />
    <InstagramCommentsManager v-if="inbox" :inbox="inbox" />
  </section>
</template>
