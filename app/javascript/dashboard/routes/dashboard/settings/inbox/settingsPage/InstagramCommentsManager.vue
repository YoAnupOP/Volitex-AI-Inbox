<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import InstagramCommentsAPI from 'dashboard/api/channel/instagramComments';

const props = defineProps({
  inbox: { type: Object, required: true },
});

const { t } = useI18n();
const media = ref([]);
const comments = ref([]);
const selectedMediaId = ref('');
const newComment = ref('');
const replyCommentId = ref('');
const replyMessage = ref('');
const mediaCursor = ref('');
const commentsCursor = ref('');
const loadingMedia = ref(false);
const loadingComments = ref(false);
const submittingComment = ref(false);
const pendingAction = ref('');
const errorMessage = ref('');

const selectedMedia = computed(() =>
  media.value.find(item => item.id === selectedMediaId.value)
);

const hasMoreMedia = computed(() => Boolean(mediaCursor.value));
const hasMoreComments = computed(() => Boolean(commentsCursor.value));

const mediaOptions = computed(() =>
  media.value.map(item => ({
    value: item.id,
    label: item.caption || item.media_product_type || item.media_type,
  }))
);

const requestError = error =>
  error.response?.data?.message || error.message || t('INBOX_MGMT.INSTAGRAM_COMMENTS.ERRORS.GENERIC');

const setError = error => {
  errorMessage.value =
    error.response?.status === 429
      ? t('INBOX_MGMT.INSTAGRAM_COMMENTS.ERRORS.RATE_LIMITED')
      : requestError(error);
  useAlert(errorMessage.value);
};

const pagingCursor = response => response?.data?.paging?.cursors?.after || '';
const responseData = response => response?.data?.data || [];

const normalizeComment = comment => ({
  ...comment,
  hidden: Boolean(comment.hidden),
  replies: comment.replies?.data || comment.replies || [],
});

const fetchMedia = async ({ append = false } = {}) => {
  loadingMedia.value = true;
  errorMessage.value = '';
  try {
    const response = await InstagramCommentsAPI.media(
      props.inbox.id,
      append ? mediaCursor.value : undefined
    );
    const items = responseData(response);
    media.value = append ? [...media.value, ...items] : items;
    mediaCursor.value = pagingCursor(response);

    if (!selectedMediaId.value && media.value.length) {
      selectedMediaId.value = media.value[0].id;
    }
  } catch (error) {
    setError(error);
  } finally {
    loadingMedia.value = false;
  }
};

const fetchComments = async ({ append = false } = {}) => {
  if (!selectedMediaId.value) return;

  loadingComments.value = true;
  errorMessage.value = '';
  try {
    const response = await InstagramCommentsAPI.list(
      props.inbox.id,
      selectedMediaId.value,
      append ? commentsCursor.value : undefined
    );
    const items = responseData(response).map(normalizeComment);
    comments.value = append ? [...comments.value, ...items] : items;
    commentsCursor.value = pagingCursor(response);
  } catch (error) {
    setError(error);
  } finally {
    loadingComments.value = false;
  }
};

const changeMedia = async () => {
  comments.value = [];
  commentsCursor.value = '';
  replyCommentId.value = '';
  await fetchComments();
};

const createComment = async () => {
  const message = newComment.value.trim();
  if (!message || !selectedMediaId.value) return;

  submittingComment.value = true;
  errorMessage.value = '';
  try {
    const response = await InstagramCommentsAPI.create(
      props.inbox.id,
      selectedMediaId.value,
      message
    );
    comments.value.unshift(
      normalizeComment({
        id: response.data.id,
        text: message,
        timestamp: new Date().toISOString(),
        username: t('INBOX_MGMT.INSTAGRAM_COMMENTS.YOU'),
        hidden: false,
      })
    );
    newComment.value = '';
    useAlert(t('INBOX_MGMT.INSTAGRAM_COMMENTS.SUCCESS.CREATED'));
  } catch (error) {
    setError(error);
  } finally {
    submittingComment.value = false;
  }
};

const findComment = commentId => {
  const topLevel = comments.value.find(comment => comment.id === commentId);
  if (topLevel) return topLevel;

  return comments.value.flatMap(comment => comment.replies).find(reply => reply.id === commentId);
};

const replyToComment = async () => {
  const message = replyMessage.value.trim();
  if (!message || !replyCommentId.value) return;

  const commentId = replyCommentId.value;
  pendingAction.value = `reply-${commentId}`;
  errorMessage.value = '';
  try {
    const response = await InstagramCommentsAPI.reply(props.inbox.id, commentId, message);
    const parent = findComment(commentId);
    if (parent) {
      parent.replies = parent.replies || [];
      parent.replies.push(
        normalizeComment({
          id: response.data.id,
          text: message,
          timestamp: new Date().toISOString(),
          username: t('INBOX_MGMT.INSTAGRAM_COMMENTS.YOU'),
          hidden: false,
        })
      );
    }
    replyCommentId.value = '';
    replyMessage.value = '';
    useAlert(t('INBOX_MGMT.INSTAGRAM_COMMENTS.SUCCESS.REPLIED'));
  } catch (error) {
    setError(error);
  } finally {
    pendingAction.value = '';
  }
};

const setVisibility = async comment => {
  const hide = !comment.hidden;
  pendingAction.value = `visibility-${comment.id}`;
  errorMessage.value = '';
  try {
    await InstagramCommentsAPI.setVisibility(props.inbox.id, comment.id, hide);
    comment.hidden = hide;
    useAlert(t(hide ? 'INBOX_MGMT.INSTAGRAM_COMMENTS.SUCCESS.HIDDEN' : 'INBOX_MGMT.INSTAGRAM_COMMENTS.SUCCESS.UNHIDDEN'));
  } catch (error) {
    setError(error);
  } finally {
    pendingAction.value = '';
  }
};

const deleteComment = async comment => {
  pendingAction.value = `delete-${comment.id}`;
  errorMessage.value = '';
  try {
    await InstagramCommentsAPI.delete(props.inbox.id, comment.id);
    const topLevelIndex = comments.value.findIndex(item => item.id === comment.id);
    if (topLevelIndex >= 0) {
      comments.value.splice(topLevelIndex, 1);
    } else {
      comments.value.forEach(item => {
        item.replies = item.replies.filter(reply => reply.id !== comment.id);
      });
    }
    useAlert(t('INBOX_MGMT.INSTAGRAM_COMMENTS.SUCCESS.DELETED'));
  } catch (error) {
    setError(error);
  } finally {
    pendingAction.value = '';
  }
};

const formatTimestamp = timestamp =>
  timestamp
    ? new Intl.DateTimeFormat(undefined, {
        dateStyle: 'medium',
        timeStyle: 'short',
      }).format(new Date(timestamp))
    : '';

const mediaThumbnail = item => item.thumbnail_url || item.media_url;

watch(selectedMediaId, value => {
  if (value) changeMedia();
});

watch(
  () => props.inbox.id,
  async () => {
    media.value = [];
    comments.value = [];
    selectedMediaId.value = '';
    await fetchMedia();
  }
);

onMounted(fetchMedia);
</script>

<template>
  <section class="mx-6 max-w-7xl pb-8">
    <div class="flex flex-col gap-1 mb-6">
      <div class="flex items-center gap-2 text-n-blue-11">
        <span class="i-lucide-message-square-more size-5" />
        <p class="text-sm font-medium m-0">{{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.EYEBROW') }}</p>
      </div>
      <h2 class="text-2xl font-semibold text-n-slate-12 m-0">
        {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.TITLE') }}
      </h2>
      <p class="text-sm text-n-slate-11 m-0">
        {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.DESCRIPTION') }}
      </p>
    </div>

    <div
      v-if="errorMessage"
      class="mb-5 flex gap-3 rounded-xl bg-n-ruby-2 p-4 text-sm text-n-ruby-11"
      role="alert"
    >
      <span class="i-lucide-circle-alert mt-0.5 size-4 shrink-0" />
      <span>{{ errorMessage }}</span>
    </div>

    <div class="grid gap-6 xl:grid-cols-[minmax(18rem,0.7fr)_minmax(0,1.6fr)]">
      <aside class="rounded-2xl bg-n-surface-1 p-5 outline outline-1 -outline-offset-1 outline-n-weak h-fit">
        <div class="flex items-center justify-between gap-3 mb-4">
          <div>
            <h3 class="font-semibold text-n-slate-12 m-0">
              {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.MEDIA.TITLE') }}
            </h3>
            <p class="mt-1 mb-0 text-sm text-n-slate-11">
              {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.MEDIA.DESCRIPTION') }}
            </p>
          </div>
          <Spinner v-if="loadingMedia" :size="18" class="text-n-blue-9" />
        </div>

        <label class="block text-sm font-medium text-n-slate-12 mb-2" for="instagram-media">
          {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.MEDIA.SELECT_LABEL') }}
        </label>
        <select
          id="instagram-media"
          v-model="selectedMediaId"
          :disabled="loadingMedia || !mediaOptions.length"
          class="w-full rounded-lg border-0 bg-n-surface-2 px-3 py-2 text-sm text-n-slate-12 outline outline-1 -outline-offset-1 outline-n-weak focus:outline-n-brand disabled:cursor-not-allowed disabled:opacity-60"
        >
          <option value="" disabled>{{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.MEDIA.PLACEHOLDER') }}</option>
          <option v-for="item in mediaOptions" :key="item.value" :value="item.value">
            {{ item.label }}
          </option>
        </select>

        <div v-if="selectedMedia" class="mt-4 overflow-hidden rounded-xl bg-n-surface-2">
          <img
            v-if="mediaThumbnail(selectedMedia)"
            :src="mediaThumbnail(selectedMedia)"
            :alt="selectedMedia.caption || $t('INBOX_MGMT.INSTAGRAM_COMMENTS.MEDIA.PREVIEW_ALT')"
            class="aspect-square w-full object-cover"
          />
          <div class="p-3">
            <p class="line-clamp-2 text-sm font-medium text-n-slate-12 m-0">
              {{ selectedMedia.caption || $t('INBOX_MGMT.INSTAGRAM_COMMENTS.MEDIA.UNTITLED') }}
            </p>
            <p class="mt-1 mb-0 text-xs uppercase tracking-wide text-n-slate-11">
              {{ selectedMedia.media_product_type || selectedMedia.media_type }}
            </p>
          </div>
        </div>

        <Button
          v-if="hasMoreMedia"
          class="mt-4 w-full"
          variant="outline"
          color="slate"
          size="sm"
          :label="$t('INBOX_MGMT.INSTAGRAM_COMMENTS.MEDIA.LOAD_MORE')"
          :is-loading="loadingMedia"
          @click="fetchMedia({ append: true })"
        />

        <p v-if="!loadingMedia && !media.length" class="mt-4 text-sm text-n-slate-11">
          {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.MEDIA.EMPTY') }}
        </p>
      </aside>

      <main class="min-w-0">
        <div class="rounded-2xl bg-n-surface-1 p-5 outline outline-1 -outline-offset-1 outline-n-weak">
          <div class="flex items-start justify-between gap-4 mb-4">
            <div>
              <h3 class="font-semibold text-n-slate-12 m-0">
                {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.CREATE.TITLE') }}
              </h3>
              <p class="mt-1 mb-0 text-sm text-n-slate-11">
                {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.CREATE.DESCRIPTION') }}
              </p>
            </div>
            <span class="rounded-full bg-n-blue-3 px-2.5 py-1 text-xs font-medium text-n-blue-11">
              {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.CREATE.META_REVIEW_LABEL') }}
            </span>
          </div>
          <textarea
            v-model="newComment"
            :disabled="!selectedMediaId || submittingComment"
            :placeholder="$t('INBOX_MGMT.INSTAGRAM_COMMENTS.CREATE.PLACEHOLDER')"
            rows="3"
            class="mb-3 w-full resize-y rounded-xl border-0 bg-n-surface-2 px-3 py-2 text-sm text-n-slate-12 outline outline-1 -outline-offset-1 outline-n-weak focus:outline-n-brand disabled:cursor-not-allowed disabled:opacity-60"
          />
          <div class="flex justify-end">
            <Button
              icon="i-lucide-send"
              :label="$t('INBOX_MGMT.INSTAGRAM_COMMENTS.CREATE.ACTION')"
              :disabled="!selectedMediaId || !newComment.trim()"
              :is-loading="submittingComment"
              @click="createComment"
            />
          </div>
        </div>

        <div class="mt-6">
          <div class="flex items-center justify-between gap-4 mb-3">
            <div>
              <h3 class="font-semibold text-n-slate-12 m-0">
                {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.LIST.TITLE') }}
              </h3>
              <p class="mt-1 mb-0 text-sm text-n-slate-11">
                {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.LIST.DESCRIPTION') }}
              </p>
            </div>
            <Button
              variant="outline"
              color="slate"
              size="sm"
              icon="i-lucide-refresh-cw"
              :label="$t('INBOX_MGMT.INSTAGRAM_COMMENTS.LIST.REFRESH')"
              :disabled="!selectedMediaId"
              :is-loading="loadingComments"
              @click="fetchComments"
            />
          </div>

          <div v-if="loadingComments && !comments.length" class="flex min-h-40 items-center justify-center rounded-2xl bg-n-surface-1 outline outline-1 -outline-offset-1 outline-n-weak">
            <Spinner :size="26" class="text-n-blue-9" />
          </div>
          <div v-else-if="!selectedMediaId" class="rounded-2xl bg-n-surface-1 p-8 text-center text-sm text-n-slate-11 outline outline-1 -outline-offset-1 outline-n-weak">
            {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.LIST.SELECT_MEDIA') }}
          </div>
          <div v-else-if="!comments.length" class="rounded-2xl bg-n-surface-1 p-8 text-center text-sm text-n-slate-11 outline outline-1 -outline-offset-1 outline-n-weak">
            {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.LIST.EMPTY') }}
          </div>
          <div v-else class="flex flex-col gap-3">
            <article
              v-for="comment in comments"
              :key="comment.id"
              class="rounded-2xl bg-n-surface-1 p-5 outline outline-1 -outline-offset-1 outline-n-weak"
            >
              <div class="flex flex-wrap items-start justify-between gap-3">
                <div class="min-w-0">
                  <div class="flex flex-wrap items-center gap-2">
                    <p class="m-0 text-sm font-semibold text-n-slate-12">@{{ comment.username || $t('INBOX_MGMT.INSTAGRAM_COMMENTS.UNKNOWN_USER') }}</p>
                    <span v-if="comment.hidden" class="rounded-full bg-n-amber-3 px-2 py-0.5 text-xs font-medium text-n-amber-11">
                      {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.STATUS.HIDDEN') }}
                    </span>
                    <span v-else class="rounded-full bg-n-teal-3 px-2 py-0.5 text-xs font-medium text-n-teal-11">
                      {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.STATUS.VISIBLE') }}
                    </span>
                  </div>
                  <p class="mt-1 mb-0 text-xs text-n-slate-11">{{ formatTimestamp(comment.timestamp) }}</p>
                </div>
                <div class="flex flex-wrap gap-2">
                  <Button size="xs" variant="outline" color="slate" icon="i-lucide-reply" :label="$t('INBOX_MGMT.INSTAGRAM_COMMENTS.ACTIONS.REPLY')" @click="replyCommentId = comment.id; replyMessage = ''" />
                  <Button size="xs" variant="outline" :color="comment.hidden ? 'teal' : 'amber'" :icon="comment.hidden ? 'i-lucide-eye' : 'i-lucide-eye-off'" :label="$t(comment.hidden ? 'INBOX_MGMT.INSTAGRAM_COMMENTS.ACTIONS.UNHIDE' : 'INBOX_MGMT.INSTAGRAM_COMMENTS.ACTIONS.HIDE')" :is-loading="pendingAction === `visibility-${comment.id}`" @click="setVisibility(comment)" />
                  <Button size="xs" variant="outline" color="ruby" icon="i-lucide-trash-2" :label="$t('INBOX_MGMT.INSTAGRAM_COMMENTS.ACTIONS.DELETE')" :is-loading="pendingAction === `delete-${comment.id}`" @click="deleteComment(comment)" />
                </div>
              </div>
              <p class="mb-0 mt-4 whitespace-pre-wrap text-sm text-n-slate-12">{{ comment.text }}</p>

              <form v-if="replyCommentId === comment.id" class="mt-4 rounded-xl bg-n-surface-2 p-3" @submit.prevent="replyToComment">
                <label class="mb-2 block text-sm font-medium text-n-slate-12">{{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.REPLY.LABEL') }}</label>
                <textarea v-model="replyMessage" rows="2" :placeholder="$t('INBOX_MGMT.INSTAGRAM_COMMENTS.REPLY.PLACEHOLDER')" class="mb-3 w-full resize-y rounded-lg border-0 bg-n-surface-1 px-3 py-2 text-sm text-n-slate-12 outline outline-1 -outline-offset-1 outline-n-weak focus:outline-n-brand" />
                <div class="flex justify-end gap-2"><Button size="sm" variant="ghost" color="slate" :label="$t('INBOX_MGMT.INSTAGRAM_COMMENTS.REPLY.CANCEL')" @click.prevent="replyCommentId = ''; replyMessage = ''" /><Button size="sm" icon="i-lucide-send" :label="$t('INBOX_MGMT.INSTAGRAM_COMMENTS.REPLY.SEND')" :disabled="!replyMessage.trim()" :is-loading="pendingAction === `reply-${comment.id}`" type="submit" /></div>
              </form>

              <div v-if="comment.replies.length" class="mt-4 flex flex-col gap-3 border-l-2 border-n-weak pl-4">
                <div v-for="reply in comment.replies" :key="reply.id" class="rounded-xl bg-n-surface-2 p-3">
                  <div class="flex flex-wrap items-start justify-between gap-3"><div><div class="flex items-center gap-2"><p class="m-0 text-sm font-semibold text-n-slate-12">@{{ reply.username || $t('INBOX_MGMT.INSTAGRAM_COMMENTS.UNKNOWN_USER') }}</p><span v-if="reply.hidden" class="rounded-full bg-n-amber-3 px-2 py-0.5 text-xs font-medium text-n-amber-11">{{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.STATUS.HIDDEN') }}</span></div><p class="mt-1 mb-0 text-xs text-n-slate-11">{{ formatTimestamp(reply.timestamp) }}</p></div><div class="flex flex-wrap gap-2"><Button size="xs" variant="outline" :color="reply.hidden ? 'teal' : 'amber'" :label="$t(reply.hidden ? 'INBOX_MGMT.INSTAGRAM_COMMENTS.ACTIONS.UNHIDE' : 'INBOX_MGMT.INSTAGRAM_COMMENTS.ACTIONS.HIDE')" :is-loading="pendingAction === `visibility-${reply.id}`" @click="setVisibility(reply)" /><Button size="xs" variant="outline" color="ruby" :label="$t('INBOX_MGMT.INSTAGRAM_COMMENTS.ACTIONS.DELETE')" :is-loading="pendingAction === `delete-${reply.id}`" @click="deleteComment(reply)" /></div></div>
                  <p class="mb-0 mt-3 whitespace-pre-wrap text-sm text-n-slate-12">{{ reply.text }}</p>
                </div>
              </div>
            </article>
          </div>

          <Button v-if="hasMoreComments" class="mt-4 w-full" variant="outline" color="slate" :label="$t('INBOX_MGMT.INSTAGRAM_COMMENTS.LIST.LOAD_MORE')" :is-loading="loadingComments" @click="fetchComments({ append: true })" />
        </div>
      </main>
    </div>
  </section>
</template>
