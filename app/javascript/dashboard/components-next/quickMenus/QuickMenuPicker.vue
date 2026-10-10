<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import quickMenuAPI from 'dashboard/api/quickMenu';

const props = defineProps({
  conversationId: { type: Number, required: true },
  canReply: { type: Boolean, default: false },
});

const { t } = useI18n();
const show = ref(false);
const loading = ref(false);
const sendingId = ref(null);
const menus = ref([]);

const open = async () => {
  show.value = true;
  loading.value = true;
  try {
    const { data } = await quickMenuAPI.get();
    menus.value = data;
  } catch (error) {
    show.value = false;
    useAlert(
      error?.response?.data?.error?.message ||
        t('QUICK_MENUS.COMPOSER.LOAD_ERROR')
    );
  } finally {
    loading.value = false;
  }
};

const send = async menu => {
  if (sendingId.value) return;
  sendingId.value = menu.id;
  try {
    await quickMenuAPI.send(props.conversationId, menu.id);
    show.value = false;
    useAlert(t('QUICK_MENUS.COMPOSER.SENT'));
  } catch (error) {
    useAlert(
      error?.response?.data?.error?.message ||
        error?.message ||
        t('QUICK_MENUS.COMPOSER.SEND_ERROR')
    );
  } finally {
    sendingId.value = null;
  }
};
</script>

<template>
  <span>
    <span
      v-tooltip.top-end="
        canReply
          ? t('QUICK_MENUS.COMPOSER.ACTION')
          : t('QUICK_MENUS.COMPOSER.CLOSED_WINDOW')
      "
    >
      <Button
        :aria-label="t('QUICK_MENUS.COMPOSER.ACTION')"
        icon="i-ph-list-bullets"
        slate
        faded
        sm
        :disabled="!canReply || Boolean(sendingId)"
        @click="open"
      />
    </span>
    <woot-modal :show="show" size="medium" :on-close="() => (show = false)">
      <woot-modal-header
        :header-title="t('QUICK_MENUS.COMPOSER.PICKER_TITLE')"
      />
      <div class="flex flex-col gap-2 p-4">
        <p v-if="loading" class="text-sm text-n-slate-11">
          {{ t('QUICK_MENUS.LOADING') }}
        </p>
        <p v-else-if="!menus.length" class="text-sm text-n-slate-11">
          {{ t('QUICK_MENUS.COMPOSER.EMPTY') }}
        </p>
        <button
          v-for="menu in menus"
          :key="menu.id"
          type="button"
          class="flex flex-col gap-1 rounded-lg border border-n-weak p-3 text-left hover:bg-n-alpha-2 disabled:opacity-50"
          :disabled="Boolean(sendingId)"
          @click="send(menu)"
        >
          <span class="font-medium text-n-slate-12">{{ menu.name }}</span>
          <span class="text-sm text-n-slate-11">{{ menu.body }}</span>
          <span class="text-xs text-n-slate-10"
            >{{ menu.items.length }} {{ t('QUICK_MENUS.ITEMS') }}</span
          >
          <span v-if="sendingId === menu.id" class="text-xs text-n-slate-11">{{
            t('QUICK_MENUS.COMPOSER.SENDING')
          }}</span>
        </button>
      </div>
    </woot-modal>
  </span>
</template>
