import { flushPromises, mount } from '@vue/test-utils';
import { beforeEach, describe, expect, it, vi } from 'vitest';

const { quickMenuAPI, useAlert, useStore } = vi.hoisted(() => ({
  quickMenuAPI: { get: vi.fn() },
  useAlert: vi.fn(),
  useStore: vi.fn(),
}));

vi.mock('dashboard/api/quickMenu', () => ({ default: quickMenuAPI }));
vi.mock('dashboard/composables', () => ({ useAlert }));
vi.mock('dashboard/composables/store', () => ({ useStore }));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));

import QuickMenuSettings from '../Index.vue';

const mountSettings = role => {
  useStore.mockReturnValue({ getters: { getCurrentRole: role } });
  return mount(QuickMenuSettings, {
    global: {
      mocks: { $t: key => key },
      stubs: {
        SettingsLayout: { template: '<div><slot name="body" /></div>' },
        BaseSettingsHeader: true,
        Button: {
          props: ['label'],
          template: '<button>{{ label }}</button>',
        },
        'woot-confirm-modal': true,
      },
    },
  });
};

describe('QuickMenuSettings', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    quickMenuAPI.get.mockResolvedValue({ data: [] });
  });

  it('shows management controls only to administrators', async () => {
    const admin = mountSettings('administrator');
    await flushPromises();
    expect(admin.text()).toContain('QUICK_MENUS.NEW');
    expect(admin.find('textarea').exists()).toBe(true);

    const agent = mountSettings('agent');
    await flushPromises();
    expect(agent.find('textarea').exists()).toBe(false);
    expect(agent.findAll('button').map(button => button.text())).not.toContain(
      'QUICK_MENUS.NEW'
    );
  });
});
