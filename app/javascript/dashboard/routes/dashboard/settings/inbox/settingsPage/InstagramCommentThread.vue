<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  comment: { type: Object, required: true },
  depth: { type: Number, default: 0 },
  replyCommentId: { type: String, default: '' },
  replyMessage: { type: String, default: '' },
  pendingAction: { type: String, default: '' },
  formatTimestamp: { type: Function, required: true },
});

defineEmits([
  'startReply',
  'update:replyMessage',
  'cancelReply',
  'submitReply',
  'setVisibility',
  'deleteComment',
]);

defineOptions({ name: 'InstagramCommentThread' });

const { t } = useI18n();
const isReplying = computed(() => props.replyCommentId === props.comment.id);
const isTopLevel = computed(() => props.depth === 0);
const displayName = computed(
  () =>
    `@${props.comment.username || t('INBOX_MGMT.INSTAGRAM_COMMENTS.UNKNOWN_USER')}`
);
</script>

<template>
  <article
    :class="
      isTopLevel
        ? 'rounded-2xl bg-n-surface-1 p-5 outline outline-1 -outline-offset-1 outline-n-weak'
        : 'rounded-xl bg-n-surface-2 p-3'
    "
    :data-comment-id="comment.id"
  >
    <div class="flex flex-wrap items-start justify-between gap-3">
      <div class="min-w-0">
        <div class="flex flex-wrap items-center gap-2">
          <p class="m-0 text-sm font-semibold text-n-slate-12">
            {{ displayName }}
          </p>
          <span
            v-if="!isTopLevel"
            class="rounded-full bg-n-slate-3 px-2 py-0.5 text-xs font-medium text-n-slate-11"
          >
            {{ t('INBOX_MGMT.INSTAGRAM_COMMENTS.STATUS.REPLY') }}
          </span>
          <span
            :class="
              comment.hidden
                ? 'bg-n-amber-3 text-n-amber-11'
                : 'bg-n-teal-3 text-n-teal-11'
            "
            class="rounded-full px-2 py-0.5 text-xs font-medium"
          >
            {{
              t(
                comment.hidden
                  ? 'INBOX_MGMT.INSTAGRAM_COMMENTS.STATUS.HIDDEN'
                  : 'INBOX_MGMT.INSTAGRAM_COMMENTS.STATUS.VISIBLE'
              )
            }}
          </span>
        </div>
        <p class="mt-1 mb-0 text-xs text-n-slate-11">
          {{ formatTimestamp(comment.timestamp) }}
        </p>
      </div>
      <div class="flex flex-wrap gap-2">
        <Button
          size="xs"
          variant="outline"
          color="slate"
          icon="i-lucide-reply"
          :label="t('INBOX_MGMT.INSTAGRAM_COMMENTS.ACTIONS.REPLY')"
          @click="$emit('startReply', comment.id)"
        />
        <Button
          size="xs"
          variant="outline"
          :color="comment.hidden ? 'teal' : 'amber'"
          :icon="comment.hidden ? 'i-lucide-eye' : 'i-lucide-eye-off'"
          :label="
            t(
              comment.hidden
                ? 'INBOX_MGMT.INSTAGRAM_COMMENTS.ACTIONS.UNHIDE'
                : 'INBOX_MGMT.INSTAGRAM_COMMENTS.ACTIONS.HIDE'
            )
          "
          :is-loading="pendingAction === `visibility-${comment.id}`"
          @click="$emit('setVisibility', comment)"
        />
        <Button
          size="xs"
          variant="outline"
          color="ruby"
          icon="i-lucide-trash-2"
          :label="t('INBOX_MGMT.INSTAGRAM_COMMENTS.ACTIONS.DELETE')"
          :is-loading="pendingAction === `delete-${comment.id}`"
          @click="$emit('deleteComment', comment)"
        />
      </div>
    </div>
    <p
      :class="isTopLevel ? 'mb-0 mt-4' : 'mb-0 mt-3'"
      class="whitespace-pre-wrap text-sm text-n-slate-12"
    >
      {{ comment.text }}
    </p>

    <form
      v-if="isReplying"
      class="mt-4 rounded-xl bg-n-surface-1 p-3"
      @submit.prevent="$emit('submitReply')"
    >
      <label class="mb-2 block text-sm font-medium text-n-slate-12">
        {{ t('INBOX_MGMT.INSTAGRAM_COMMENTS.REPLY.LABEL') }}
      </label>
      <textarea
        :value="replyMessage"
        rows="2"
        :placeholder="t('INBOX_MGMT.INSTAGRAM_COMMENTS.REPLY.PLACEHOLDER')"
        class="mb-3 w-full resize-y rounded-lg border-0 bg-n-surface-2 px-3 py-2 text-sm text-n-slate-12 outline outline-1 -outline-offset-1 outline-n-weak focus:outline-n-brand"
        @input="$emit('update:replyMessage', $event.target.value)"
      />
      <div class="flex justify-end gap-2">
        <Button
          size="sm"
          variant="ghost"
          color="slate"
          :label="t('INBOX_MGMT.INSTAGRAM_COMMENTS.REPLY.CANCEL')"
          @click.prevent="$emit('cancelReply')"
        />
        <Button
          size="sm"
          icon="i-lucide-send"
          :label="t('INBOX_MGMT.INSTAGRAM_COMMENTS.REPLY.SEND')"
          :disabled="!replyMessage.trim()"
          :is-loading="pendingAction === `reply-${comment.id}`"
          type="submit"
        />
      </div>
    </form>

    <div
      v-if="comment.replies.length"
      class="mt-4 flex flex-col gap-3 border-l-2 border-n-weak pl-4"
    >
      <InstagramCommentThread
        v-for="reply in comment.replies"
        :key="reply.id"
        :comment="reply"
        :depth="depth + 1"
        :reply-comment-id="replyCommentId"
        :reply-message="replyMessage"
        :pending-action="pendingAction"
        :format-timestamp="formatTimestamp"
        @start-reply="$emit('startReply', $event)"
        @update:reply-message="$emit('update:replyMessage', $event)"
        @cancel-reply="$emit('cancelReply')"
        @submit-reply="$emit('submitReply')"
        @set-visibility="$emit('setVisibility', $event)"
        @delete-comment="$emit('deleteComment', $event)"
      />
    </div>
  </article>
</template>
