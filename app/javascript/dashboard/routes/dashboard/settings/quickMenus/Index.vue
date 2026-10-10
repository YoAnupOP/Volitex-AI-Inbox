<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import quickMenuAPI from 'dashboard/api/quickMenu';
import {
  getQuickMenuType,
  validateQuickMenu,
} from 'dashboard/components-next/quickMenus/quickMenuHelper';

const { t } = useI18n();
const store = useStore();
const menus = ref([]);
const selected = ref(null);
const loading = ref(true);
const saving = ref(false);
const errors = ref({});
const confirmDialog = ref(null);
const deleteCandidate = ref(null);
const isAdmin = computed(
  () => store.getters.getCurrentRole === 'administrator'
);
const form = ref({ name: '', body: '', items: [{ title: '' }] });
const menuType = computed(() => getQuickMenuType(form.value.items));
const menuLimitLabel = computed(() => {
  if (menuType.value === 'buttons') return t('QUICK_MENUS.BUTTON_LIMIT');
  return t('QUICK_MENUS.ROW_LIMIT');
});
const validationMessage = error =>
  ({
    required: t('QUICK_MENUS.VALIDATION.REQUIRED'),
    too_long: t('QUICK_MENUS.VALIDATION.TOO_LONG'),
    duplicate: t('QUICK_MENUS.VALIDATION.DUPLICATE'),
  })[error] || '';

const loadMenus = async () => {
  loading.value = true;
  try {
    const { data } = await quickMenuAPI.get();
    menus.value = data;
  } catch (error) {
    useAlert(error?.message || t('QUICK_MENUS.ERRORS.LOAD'));
  } finally {
    loading.value = false;
  }
};

const resetForm = () => {
  selected.value = null;
  form.value = { name: '', body: '', items: [{ title: '' }] };
  errors.value = {};
};

const editMenu = menu => {
  selected.value = menu;
  form.value = {
    name: menu.name,
    body: menu.body,
    items: menu.items.map(item => ({ ...item })),
  };
  errors.value = {};
};

const saveMenu = async () => {
  errors.value = validateQuickMenu(form.value);
  if (Object.keys(errors.value).length) return;
  saving.value = true;
  try {
    const request = { quick_menu: form.value };
    if (selected.value) await quickMenuAPI.update(selected.value.id, request);
    else await quickMenuAPI.create(request);
    await loadMenus();
    resetForm();
    useAlert(t('QUICK_MENUS.SAVED'));
  } catch (error) {
    useAlert(
      error?.response?.data?.error?.message ||
        error?.response?.data?.error ||
        error?.message ||
        t('QUICK_MENUS.ERRORS.SAVE')
    );
  } finally {
    saving.value = false;
  }
};

const deleteMenu = async menu => {
  deleteCandidate.value = menu;
  const confirmed = await confirmDialog.value.showConfirmation();
  if (!confirmed) return;
  try {
    await quickMenuAPI.delete(menu.id);
    await loadMenus();
    if (selected.value?.id === menu.id) resetForm();
    useAlert(t('QUICK_MENUS.DELETED'));
  } catch (error) {
    useAlert(
      error?.response?.data?.error?.message ||
        error?.response?.data?.error ||
        error?.message ||
        t('QUICK_MENUS.ERRORS.DELETE')
    );
  }
};

const addItem = () => {
  if (form.value.items.length < 10) form.value.items.push({ title: '' });
};

const removeItem = index => {
  if (form.value.items.length > 1) form.value.items.splice(index, 1);
};

onMounted(loadMenus);
</script>

<template>
  <SettingsLayout
    :is-loading="loading"
    :loading-message="$t('QUICK_MENUS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('QUICK_MENUS.TITLE')"
        :description="$t('QUICK_MENUS.DESCRIPTION')"
      />
    </template>
    <template #body>
      <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
        <section class="flex flex-col gap-3">
          <h2 class="text-base font-semibold text-n-slate-12">
            {{ $t('QUICK_MENUS.AVAILABLE') }}
          </h2>
          <p v-if="!menus.length" class="text-sm text-n-slate-11">
            {{ $t('QUICK_MENUS.EMPTY') }}
          </p>
          <article
            v-for="menu in menus"
            :key="menu.id"
            class="flex items-start justify-between gap-3 rounded-lg border border-n-weak p-4"
          >
            <button class="min-w-0 flex-1 text-left" @click="editMenu(menu)">
              <strong class="block text-n-slate-12">{{ menu.name }}</strong>
              <span class="mt-1 block truncate text-sm text-n-slate-11">{{
                menu.body
              }}</span>
              <span class="mt-2 block text-xs text-n-slate-10">{{
                $t('QUICK_MENUS.ITEM_COUNT_LABEL', {
                  count: menu.items.length,
                  type:
                    menu.items.length <= 3
                      ? $t('QUICK_MENUS.BUTTONS')
                      : $t('QUICK_MENUS.LIST'),
                })
              }}</span>
              <span class="mt-2 flex flex-wrap gap-1">
                <span
                  v-for="(item, index) in menu.items"
                  :key="index"
                  class="rounded-full bg-n-alpha-2 px-2 py-0.5 text-xs text-n-slate-11"
                  >{{ item.title }}</span
                >
              </span>
            </button>
            <div v-if="isAdmin" class="flex gap-2">
              <Button
                :label="$t('QUICK_MENUS.EDIT')"
                size="sm"
                slate
                faded
                @click="editMenu(menu)"
              />
              <Button
                :label="$t('QUICK_MENUS.DELETE')"
                size="sm"
                slate
                faded
                @click="deleteMenu(menu)"
              />
            </div>
          </article>
          <Button
            v-if="isAdmin"
            :label="$t('QUICK_MENUS.NEW')"
            class="self-start"
            size="sm"
            @click="resetForm"
          />
        </section>

        <section
          v-if="isAdmin"
          class="flex flex-col gap-4 rounded-lg border border-n-weak p-4"
        >
          <h2 class="text-base font-semibold text-n-slate-12">
            {{
              selected ? $t('QUICK_MENUS.EDIT_TITLE') : $t('QUICK_MENUS.NEW')
            }}
          </h2>
          <label class="flex flex-col gap-1 text-sm text-n-slate-11">
            {{ $t('QUICK_MENUS.NAME') }}
            <input
              v-model="form.name"
              class="rounded-md border border-n-weak bg-n-solid-1 p-2 text-n-slate-12"
            />
            <span v-if="errors.name" class="text-sm text-n-ruby-9">{{
              $t('QUICK_MENUS.VALIDATION.NAME_REQUIRED')
            }}</span>
          </label>
          <label class="flex flex-col gap-1 text-sm text-n-slate-11">
            {{ $t('QUICK_MENUS.BODY') }}
            <textarea
              v-model="form.body"
              rows="4"
              class="rounded-md border border-n-weak bg-n-solid-1 p-2 text-n-slate-12"
            />
            <span class="text-right text-xs">{{
              $t('QUICK_MENUS.BODY_COUNTER', { count: form.body.length })
            }}</span>
            <span v-if="errors.body" class="text-sm text-n-ruby-9">{{
              errors.body === 'required'
                ? $t('QUICK_MENUS.VALIDATION.BODY_REQUIRED')
                : $t('QUICK_MENUS.VALIDATION.BODY_TOO_LONG')
            }}</span>
          </label>
          <div class="flex flex-col gap-2">
            <div class="flex items-center justify-between">
              <h3 class="font-medium text-n-slate-12">
                {{ $t('QUICK_MENUS.ITEMS') }}
              </h3>
              <span class="text-xs text-n-slate-11">{{ menuLimitLabel }}</span>
            </div>
            <div
              v-for="(item, index) in form.items"
              :key="index"
              class="flex items-center gap-2"
            >
              <input
                v-model="item.title"
                :aria-label="
                  $t('QUICK_MENUS.ITEM_TITLE', { number: index + 1 })
                "
                class="min-w-0 flex-1 rounded-md border border-n-weak bg-n-solid-1 p-2 text-n-slate-12"
              />
              <span class="text-xs text-n-slate-10">{{
                $t('QUICK_MENUS.TITLE_COUNTER', {
                  count: item.title.length,
                  limit: menuType === 'buttons' ? 20 : 24,
                })
              }}</span>
              <Button
                :label="$t('QUICK_MENUS.REMOVE')"
                size="sm"
                slate
                faded
                :disabled="form.items.length === 1"
                @click="removeItem(index)"
              />
            </div>
            <Button
              v-if="form.items.length < 10"
              :label="$t('QUICK_MENUS.ADD_ITEM')"
              size="sm"
              slate
              faded
              class="self-start"
              @click="addItem"
            />
            <p v-if="errors.items" class="text-sm text-n-ruby-9">
              {{ $t('QUICK_MENUS.VALIDATION.ITEM_COUNT') }}
            </p>
            <p
              v-for="(item, index) in form.items"
              :key="`error-${index}`"
              class="text-sm text-n-ruby-9"
            >
              {{ validationMessage(errors[`item-${index}`]) }}
            </p>
          </div>
          <div class="rounded-lg border border-n-weak bg-n-alpha-1 p-4">
            <h3 class="mb-2 text-sm font-semibold text-n-slate-12">
              {{ $t('QUICK_MENUS.PREVIEW') }}
            </h3>
            <p class="whitespace-pre-wrap break-words text-sm text-n-slate-12">
              {{ form.body || $t('QUICK_MENUS.BODY') }}
            </p>
            <div class="mt-3 flex flex-wrap gap-2">
              <span
                v-for="(item, index) in form.items"
                :key="index"
                class="max-w-full rounded-lg border border-n-slate-7 px-3 py-1 text-sm text-n-slate-12"
                ><span class="break-words">{{
                  item.title ||
                  $t('QUICK_MENUS.ITEM_TITLE', { number: index + 1 })
                }}</span></span
              >
            </div>
          </div>
          <Button
            :label="$t('QUICK_MENUS.SAVE')"
            :is-loading="saving"
            :disabled="saving"
            class="self-start"
            @click="saveMenu"
          />
        </section>
      </div>
    </template>
    <woot-confirm-modal
      ref="confirmDialog"
      :title="$t('QUICK_MENUS.DELETE_TITLE')"
      :description="
        $t('QUICK_MENUS.DELETE_CONFIRM', { name: deleteCandidate?.name })
      "
    />
  </SettingsLayout>
</template>
