<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import InstagramCommentsAPI from 'dashboard/api/channel/instagramComments';
import InstagramCommentThread from './InstagramCommentThread.vue';

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
const searchQuery = ref('');
const selectedFilter = ref('all');
const selectedSort = ref('newest');

const selectedMedia = computed(() =>
  media.value.find(item => item.id === selectedMediaId.value)
);

const hasMoreMedia = computed(() => Boolean(mediaCursor.value));
const hasMoreComments = computed(() => Boolean(commentsCursor.value));

const normalizedSearchQuery = computed(() =>
  searchQuery.value.trim().toLocaleLowerCase()
);

const mediaOptions = computed(() =>
  media.value.map(item => ({
    value: item.id,
    label: item.caption || item.media_product_type || item.media_type,
  }))
);

const requestError = error =>
  error.response?.data?.message ||
  error.message ||
  t('INBOX_MGMT.INSTAGRAM_COMMENTS.ERRORS.GENERIC');

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
  username: comment.from?.username || comment.username,
  hidden: Boolean(comment.hidden),
  replies: (comment.replies?.data || comment.replies || []).map(
    normalizeComment
  ),
});

const matchesSearch = comment => {
  if (!normalizedSearchQuery.value) return true;

  return [comment.username, comment.text].some(value =>
    value?.toLocaleLowerCase().includes(normalizedSearchQuery.value)
  );
};

const matchesFilter = comment => {
  switch (selectedFilter.value) {
    case 'hidden':
      return comment.hidden;
    case 'visible':
      return !comment.hidden;
    case 'replied':
      return comment.replies.length > 0;
    case 'unreplied':
      return comment.replies.length === 0;
    default:
      return true;
  }
};

const sortByTimestamp = entries =>
  [...entries].sort((left, right) => {
    const difference = new Date(right.timestamp) - new Date(left.timestamp);
    return selectedSort.value === 'newest' ? difference : -difference;
  });

const filterCommentTree = comment => {
  const replies = sortByTimestamp(
    comment.replies.map(filterCommentTree).filter(Boolean)
  );
  return matchesSearch(comment) || replies.length
    ? { ...comment, replies }
    : null;
};

const filteredComments = computed(() =>
  sortByTimestamp(
    comments.value.filter(matchesFilter).map(filterCommentTree).filter(Boolean)
  )
);

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
    await fetchComments();
    useAlert(t('INBOX_MGMT.INSTAGRAM_COMMENTS.SUCCESS.CREATED'));
  } catch (error) {
    setError(error);
  } finally {
    submittingComment.value = false;
  }
};

const findComment = (commentId, entries = comments.value) => {
  const comment = entries.find(item => item.id === commentId);
  return (
    comment ||
    entries.map(item => findComment(commentId, item.replies)).find(Boolean)
  );
};

const removeComment = (entries, commentId) =>
  entries
    .filter(comment => comment.id !== commentId)
    .map(comment => ({
      ...comment,
      replies: removeComment(comment.replies, commentId),
    }));

const startReply = commentId => {
  replyCommentId.value = commentId;
  replyMessage.value = '';
};

const cancelReply = () => {
  replyCommentId.value = '';
  replyMessage.value = '';
};

const replyToComment = async () => {
  const message = replyMessage.value.trim();
  if (!message || !replyCommentId.value) return;

  const commentId = replyCommentId.value;
  pendingAction.value = `reply-${commentId}`;
  errorMessage.value = '';
  try {
    const response = await InstagramCommentsAPI.reply(
      props.inbox.id,
      commentId,
      message
    );
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
    cancelReply();
    await fetchComments();
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
    useAlert(
      t(
        hide
          ? 'INBOX_MGMT.INSTAGRAM_COMMENTS.SUCCESS.HIDDEN'
          : 'INBOX_MGMT.INSTAGRAM_COMMENTS.SUCCESS.UNHIDDEN'
      )
    );
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
    comments.value = removeComment(comments.value, comment.id);
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
        <p class="text-sm font-medium m-0">
          {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.EYEBROW') }}
        </p>
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
      <aside
        class="rounded-2xl bg-n-surface-1 p-5 outline outline-1 -outline-offset-1 outline-n-weak h-fit"
      >
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

        <label
          class="block text-sm font-medium text-n-slate-12 mb-2"
          for="instagram-media"
        >
          {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.MEDIA.SELECT_LABEL') }}
        </label>
        <select
          id="instagram-media"
          v-model="selectedMediaId"
          :disabled="loadingMedia || !mediaOptions.length"
          class="w-full rounded-lg border-0 bg-n-surface-2 px-3 py-2 text-sm text-n-slate-12 outline outline-1 -outline-offset-1 outline-n-weak focus:outline-n-brand disabled:cursor-not-allowed disabled:opacity-60"
        >
          <option value="" disabled>
            {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.MEDIA.PLACEHOLDER') }}
          </option>
          <option
            v-for="item in mediaOptions"
            :key="item.value"
            :value="item.value"
          >
            {{ item.label }}
          </option>
        </select>

        <div
          v-if="selectedMedia"
          class="mt-4 overflow-hidden rounded-xl bg-n-surface-2"
        >
          <img
            v-if="mediaThumbnail(selectedMedia)"
            :src="mediaThumbnail(selectedMedia)"
            :alt="
              selectedMedia.caption ||
              $t('INBOX_MGMT.INSTAGRAM_COMMENTS.MEDIA.PREVIEW_ALT')
            "
            class="aspect-square w-full object-cover"
          />
          <div class="p-3">
            <p class="line-clamp-2 text-sm font-medium text-n-slate-12 m-0">
              {{
                selectedMedia.caption ||
                $t('INBOX_MGMT.INSTAGRAM_COMMENTS.MEDIA.UNTITLED')
              }}
            </p>
            <p
              class="mt-1 mb-0 text-xs uppercase tracking-wide text-n-slate-11"
            >
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

        <p
          v-if="!loadingMedia && !media.length"
          class="mt-4 text-sm text-n-slate-11"
        >
          {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.MEDIA.EMPTY') }}
        </p>
      </aside>

      <main class="min-w-0">
        <div
          class="rounded-2xl bg-n-surface-1 p-5 outline outline-1 -outline-offset-1 outline-n-weak"
        >
          <div class="flex items-start justify-between gap-4 mb-4">
            <div>
              <h3 class="font-semibold text-n-slate-12 m-0">
                {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.CREATE.TITLE') }}
              </h3>
              <p class="mt-1 mb-0 text-sm text-n-slate-11">
                {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.CREATE.DESCRIPTION') }}
              </p>
            </div>
            <span
              class="rounded-full bg-n-blue-3 px-2.5 py-1 text-xs font-medium text-n-blue-11"
            >
              {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.CREATE.META_REVIEW_LABEL') }}
            </span>
          </div>
          <textarea
            v-model="newComment"
            :disabled="!selectedMediaId || submittingComment"
            :placeholder="
              $t('INBOX_MGMT.INSTAGRAM_COMMENTS.CREATE.PLACEHOLDER')
            "
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

          <div
            v-if="selectedMediaId && comments.length"
            class="mb-4 grid gap-3 rounded-2xl bg-n-surface-1 p-4 outline outline-1 -outline-offset-1 outline-n-weak md:grid-cols-[minmax(0,1fr)_11rem_11rem]"
          >
            <label class="block text-sm font-medium text-n-slate-12">
              <span class="mb-2 block">{{
                $t('INBOX_MGMT.INSTAGRAM_COMMENTS.FILTERS.SEARCH_LABEL')
              }}</span>
              <input
                v-model="searchQuery"
                type="search"
                :placeholder="
                  $t('INBOX_MGMT.INSTAGRAM_COMMENTS.FILTERS.SEARCH_PLACEHOLDER')
                "
                class="w-full rounded-lg border-0 bg-n-surface-2 px-3 py-2 text-sm text-n-slate-12 outline outline-1 -outline-offset-1 outline-n-weak focus:outline-n-brand"
              />
            </label>
            <label class="block text-sm font-medium text-n-slate-12">
              <span class="mb-2 block">{{
                $t('INBOX_MGMT.INSTAGRAM_COMMENTS.FILTERS.STATUS_LABEL')
              }}</span>
              <select
                v-model="selectedFilter"
                class="w-full rounded-lg border-0 bg-n-surface-2 px-3 py-2 text-sm text-n-slate-12 outline outline-1 -outline-offset-1 outline-n-weak focus:outline-n-brand"
              >
                <option value="all">
                  {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.FILTERS.ALL') }}
                </option>
                <option value="visible">
                  {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.FILTERS.VISIBLE') }}
                </option>
                <option value="hidden">
                  {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.FILTERS.HIDDEN') }}
                </option>
                <option value="replied">
                  {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.FILTERS.REPLIED') }}
                </option>
                <option value="unreplied">
                  {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.FILTERS.UNREPLIED') }}
                </option>
              </select>
            </label>
            <label class="block text-sm font-medium text-n-slate-12">
              <span class="mb-2 block">{{
                $t('INBOX_MGMT.INSTAGRAM_COMMENTS.FILTERS.SORT_LABEL')
              }}</span>
              <select
                v-model="selectedSort"
                class="w-full rounded-lg border-0 bg-n-surface-2 px-3 py-2 text-sm text-n-slate-12 outline outline-1 -outline-offset-1 outline-n-weak focus:outline-n-brand"
              >
                <option value="newest">
                  {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.FILTERS.NEWEST') }}
                </option>
                <option value="oldest">
                  {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.FILTERS.OLDEST') }}
                </option>
              </select>
            </label>
          </div>

          <div
            v-if="loadingComments && !comments.length"
            class="flex min-h-40 items-center justify-center rounded-2xl bg-n-surface-1 outline outline-1 -outline-offset-1 outline-n-weak"
          >
            <Spinner :size="26" class="text-n-blue-9" />
          </div>
          <div
            v-else-if="!selectedMediaId"
            class="rounded-2xl bg-n-surface-1 p-8 text-center text-sm text-n-slate-11 outline outline-1 -outline-offset-1 outline-n-weak"
          >
            {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.LIST.SELECT_MEDIA') }}
          </div>
          <div
            v-else-if="!comments.length"
            class="rounded-2xl bg-n-surface-1 p-8 text-center text-sm text-n-slate-11 outline outline-1 -outline-offset-1 outline-n-weak"
          >
            {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.LIST.EMPTY') }}
          </div>
          <div
            v-else-if="!filteredComments.length"
            class="rounded-2xl bg-n-surface-1 p-8 text-center text-sm text-n-slate-11 outline outline-1 -outline-offset-1 outline-n-weak"
          >
            {{ $t('INBOX_MGMT.INSTAGRAM_COMMENTS.FILTERS.EMPTY') }}
          </div>
          <div v-else class="flex flex-col gap-3">
            <InstagramCommentThread
              v-for="comment in filteredComments"
              :key="comment.id"
              :comment="comment"
              :reply-comment-id="replyCommentId"
              :reply-message="replyMessage"
              :pending-action="pendingAction"
              :format-timestamp="formatTimestamp"
              @start-reply="startReply"
              @update:reply-message="replyMessage = $event"
              @cancel-reply="cancelReply"
              @submit-reply="replyToComment"
              @set-visibility="setVisibility"
              @delete-comment="deleteComment"
            />
          </div>

          <Button
            v-if="hasMoreComments"
            class="mt-4 w-full"
            variant="outline"
            color="slate"
            :label="$t('INBOX_MGMT.INSTAGRAM_COMMENTS.LIST.LOAD_MORE')"
            :is-loading="loadingComments"
            @click="fetchComments({ append: true })"
          />
        </div>
      </main>
    </div>
  </section>
</template>
