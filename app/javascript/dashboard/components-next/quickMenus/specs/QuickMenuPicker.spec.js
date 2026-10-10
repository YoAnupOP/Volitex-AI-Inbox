import { flushPromises, mount } from '@vue/test-utils';
import { beforeEach, describe, expect, it, vi } from 'vitest';

const { quickMenuAPI, useAlert } = vi.hoisted(() => ({
  quickMenuAPI: { get: vi.fn(), send: vi.fn() },
  useAlert: vi.fn(),
}));

vi.mock('dashboard/api/quickMenu', () => ({ default: quickMenuAPI }));
vi.mock('dashboard/composables', () => ({ useAlert }));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));

import QuickMenuPicker from '../QuickMenuPicker.vue';

const mountPicker = canReply =>
  mount(QuickMenuPicker, {
    props: { conversationId: 42, canReply },
    global: {
      stubs: {
        Button: {
          props: ['label', 'disabled', 'ariaLabel', 'icon'],
          emits: ['click'],
          inheritAttrs: false,
          template:
            '<button :disabled="disabled" @click="$emit(\'click\')">{{ label }}</button>',
        },
        'woot-modal': {
          props: ['show'],
          template: '<div v-if="show"><slot /></div>',
        },
        'woot-modal-header': { template: '<header />' },
      },
    },
  });

describe('QuickMenuPicker', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    quickMenuAPI.get.mockResolvedValue({
      data: [
        { id: 3, name: 'Support', body: 'Choose', items: [{ title: 'Help' }] },
      ],
    });
    quickMenuAPI.send.mockResolvedValue({});
  });

  it('disables the action for a closed service window and loads and sends a menu', async () => {
    const closed = mountPicker(false);
    expect(closed.find('button').element.disabled).toBe(true);
    closed.unmount();

    const wrapper = mountPicker(true);
    await wrapper.find('button').trigger('click');
    await flushPromises();
    expect(quickMenuAPI.get).toHaveBeenCalledOnce();
    await wrapper.get('button[type="button"]').trigger('click');
    await flushPromises();
    expect(quickMenuAPI.send).toHaveBeenCalledWith(42, 3);
    expect(useAlert).toHaveBeenCalledWith('QUICK_MENUS.COMPOSER.SENT');
  });

  it('shows API errors through the existing alert pattern', async () => {
    quickMenuAPI.get.mockRejectedValueOnce({
      response: { data: { error: { message: 'The window is closed.' } } },
    });
    const wrapper = mountPicker(true);
    await wrapper.find('button').trigger('click');
    await flushPromises();
    expect(useAlert).toHaveBeenCalledWith('The window is closed.');
  });
});
