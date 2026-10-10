<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import { useI18n } from 'vue-i18n';
import { CONTENT_TYPES, MESSAGE_TYPES } from '../constants.js';
import { useMessageContext } from '../provider.js';
import { useInbox } from 'dashboard/composables/useInbox';
import { getInputSelectItems } from './inputSelectHelper.js';

const { content, contentAttributes, contentType, messageType } =
  useMessageContext();
const { t } = useI18n();
const { isAWebWidgetInbox } = useInbox();

const formValues = computed(() => {
  if (contentType.value === CONTENT_TYPES.FORM) {
    const { items, submittedValues = [] } = contentAttributes.value;

    if (submittedValues.length) {
      return submittedValues.map(submittedValue => {
        const item = items.find(
          formItem => formItem.name === submittedValue.name
        );
        return {
          title: submittedValue.value,
          value: submittedValue.value,
          label: item?.label,
        };
      });
    }

    return [];
  }

  if (contentType.value === CONTENT_TYPES.INPUT_SELECT) {
    const [item] = Array.isArray(contentAttributes.value?.submittedValues)
      ? contentAttributes.value.submittedValues
      : [];
    if (!item) return [];

    return [
      {
        title: item.title,
        value: item.value,
        label: '',
      },
    ];
  }

  return [];
});

const inputSelectItems = computed(() => {
  if (
    contentType.value !== CONTENT_TYPES.INPUT_SELECT ||
    messageType.value !== MESSAGE_TYPES.OUTGOING
  ) {
    return [];
  }

  return getInputSelectItems(contentAttributes.value?.items);
});
</script>

<template>
  <BaseBubble class="px-4 py-3" data-bubble-name="csat">
    <span v-dompurify-html="content" :title="content" />
    <ul
      v-if="inputSelectItems.length"
      class="mt-3 flex flex-wrap gap-2"
      :aria-label="t('CONVERSATION.INTERACTIVE_OPTIONS')"
      data-testid="input-select-items"
    >
      <li
        v-for="(item, index) in inputSelectItems"
        :key="`${index}-${item.title}`"
        class="max-w-full rounded-lg border border-n-slate-7 bg-n-slate-2 px-3 py-1.5 text-sm text-n-slate-12 dark:border-n-slate-7 dark:bg-n-slate-3 dark:text-n-slate-12"
      >
        <span class="block break-words">{{ item.title }}</span>
      </li>
    </ul>
    <dl v-if="formValues.length" class="mt-4">
      <template v-for="item in formValues" :key="item.title">
        <dt class="text-n-slate-11 italic mt-2">
          {{ item.label || t('CONVERSATION.RESPONSE') }}
        </dt>
        <dd>{{ item.title }}</dd>
      </template>
    </dl>
    <div v-else-if="isAWebWidgetInbox" class="my-2 font-medium">
      {{ t('CONVERSATION.NO_RESPONSE') }}
    </div>
  </BaseBubble>
</template>
