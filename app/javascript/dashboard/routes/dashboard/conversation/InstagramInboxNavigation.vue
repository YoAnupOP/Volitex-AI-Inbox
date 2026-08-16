<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';

const props = defineProps({
  inboxId: { type: [String, Number], required: true },
});

const store = useStore();
const { accountScopedRoute } = useAccount();

const inbox = computed(() => store.getters['inboxes/getInbox'](props.inboxId));

const isInstagramInbox = computed(
  () => inbox.value?.channel_type === 'Channel::Instagram'
);

const conversationsRoute = computed(() =>
  accountScopedRoute('inbox_dashboard', { inbox_id: props.inboxId })
);

const commentsRoute = computed(() =>
  accountScopedRoute('instagram_comments', { inbox_id: props.inboxId })
);
</script>

<template>
  <nav
    v-if="isInstagramInbox"
    :aria-label="$t('INBOX_MGMT.INSTAGRAM_COMMENTS.WORKSPACE.NAV_LABEL')"
    class="flex gap-1 border-b border-n-weak px-3 pt-2"
  >
    <router-link
      :to="conversationsRoute"
      class="rounded-t-lg px-3 py-2 text-sm font-medium text-n-slate-11 hover:bg-n-slate-3 hover:text-n-slate-12"
      active-class="bg-n-slate-3 text-n-slate-12"
      exact-active-class="bg-n-slate-3 text-n-slate-12"
    >
      {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.WORKSPACE.CONVERSATIONS') }}
    </router-link>
    <router-link
      :to="commentsRoute"
      class="rounded-t-lg px-3 py-2 text-sm font-medium text-n-slate-11 hover:bg-n-slate-3 hover:text-n-slate-12"
      active-class="bg-n-slate-3 text-n-slate-12"
      exact-active-class="bg-n-slate-3 text-n-slate-12"
    >
      {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.WORKSPACE.COMMENTS') }}
    </router-link>
  </nav>
</template>
