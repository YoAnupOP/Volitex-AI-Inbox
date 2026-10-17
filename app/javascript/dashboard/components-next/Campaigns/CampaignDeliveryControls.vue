<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import CampaignsAPI from 'dashboard/api/campaigns';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({ campaign: { type: Object, required: true } });
const { t } = useI18n();
const store = useStore();
const busy = ref(false);
const error = ref('');
const recipients = ref([]);
const hasMore = ref(true);

const control = async action => {
  if (busy.value) return;
  busy.value = true;
  error.value = '';
  try {
    await CampaignsAPI.control(props.campaign.id, action);
    await store.dispatch('campaigns/get');
  } catch {
    error.value = t('CAMPAIGN.DELIVERY.ERROR');
  } finally {
    busy.value = false;
  }
};

const loadRecipients = async () => {
  if (busy.value) return;
  busy.value = true;
  error.value = '';
  try {
    const after = recipients.value.at(-1)?.id || 0;
    const { data } = await CampaignsAPI.recipients(props.campaign.id, after);
    recipients.value.push(...data);
    hasMore.value = data.length === 100;
  } catch {
    error.value = t('CAMPAIGN.DELIVERY.ERROR');
  } finally {
    busy.value = false;
  }
};
</script>

<template>
  <section class="rounded-xl border border-n-weak p-4 text-n-slate-12">
    <h3 class="text-sm font-medium">{{ campaign.title }}</h3>
    <p class="text-sm">
      {{ t(`CAMPAIGN.DELIVERY.STATES.${campaign.campaign_status}`) }}
    </p>
    <p class="text-sm text-n-slate-11">{{ t('CAMPAIGN.DELIVERY.WARNING') }}</p>
    <p
      v-if="campaign.delivery_error"
      role="alert"
      class="text-sm text-n-ruby-11"
    >
      {{ t('CAMPAIGN.DELIVERY.PREPARATION_ERROR') }}
    </p>
    <dl class="my-3 flex flex-wrap gap-3 text-sm">
      <div v-for="(count, state) in campaign.recipient_counts" :key="state">
        <dt>{{ t(`CAMPAIGN.DELIVERY.STATES.${state}`) }}</dt>
        <dd>{{ count }}</dd>
      </div>
    </dl>
    <div class="flex flex-wrap gap-2">
      <Button
        v-if="['active', 'processing'].includes(campaign.campaign_status)"
        :label="t('CAMPAIGN.DELIVERY.PAUSE')"
        :disabled="busy"
        @click="control('pause')"
      />
      <Button
        v-if="campaign.campaign_status === 'paused'"
        :label="t('CAMPAIGN.DELIVERY.RESUME')"
        :disabled="busy"
        @click="control('resume')"
      />
      <Button
        v-if="
          ['active', 'processing', 'paused'].includes(campaign.campaign_status)
        "
        :label="t('CAMPAIGN.DELIVERY.CANCEL')"
        :disabled="busy"
        @click="control('cancel')"
      />
      <Button
        :label="t('CAMPAIGN.DELIVERY.REFRESH')"
        :disabled="busy"
        @click="store.dispatch('campaigns/get')"
      />
      <Button
        v-if="hasMore"
        :label="t('CAMPAIGN.DELIVERY.RECIPIENTS')"
        :disabled="busy"
        @click="loadRecipients"
      />
    </div>
    <p v-if="error" role="alert" class="mt-2 text-sm text-n-ruby-11">
      {{ error }}
    </p>
    <ul class="mt-3 max-h-64 overflow-auto text-sm">
      <li v-for="recipient in recipients" :key="recipient.id">
        {{
          t('CAMPAIGN.DELIVERY.RECIPIENT', {
            id: recipient.contact_id,
            state: t(`CAMPAIGN.DELIVERY.STATES.${recipient.state}`),
            attempts: recipient.attempts,
            error: recipient.error_code || '',
          })
        }}
      </li>
    </ul>
  </section>
</template>
