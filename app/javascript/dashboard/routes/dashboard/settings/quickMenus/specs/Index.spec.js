import { flushPromises, mount } from '@vue/test-utils';
import { beforeEach, describe, expect, it, vi } from 'vitest';

const { quickMenuAPI, useAlert, useStore } = vi.hoisted(() => ({
  quickMenuAPI: {
    get: vi.fn(),
    create: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
  },
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
        SettingsLayout: { template: '<div><slot name="body" /><slot /></div>' },
        BaseSettingsHeader: true,
        Button: {
          props: ['label'],
          template: '<button>{{ label }}</button>',
        },
        'woot-confirm-modal': {
          template: '<div />',
          methods: { showConfirmation: () => Promise.resolve(true) },
        },
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

  it('validates the form before creating a menu and renders its preview', async () => {
    const wrapper = mountSettings('administrator');
    await flushPromises();
    await wrapper
      .findAll('button')
      .find(button => button.text() === 'QUICK_MENUS.SAVE')
      .trigger('click');
    expect(quickMenuAPI.create).not.toHaveBeenCalled();
    expect(wrapper.text()).toContain('QUICK_MENUS.VALIDATION.NAME_REQUIRED');
    await wrapper.findAll('input')[0].setValue('Support');
    await wrapper.find('textarea').setValue('Choose a department');
    await wrapper.findAll('input')[1].setValue('Billing');
    expect(wrapper.text()).toContain('Choose a department');
    await wrapper
      .findAll('button')
      .find(button => button.text() === 'QUICK_MENUS.SAVE')
      .trigger('click');
    await flushPromises();
    expect(quickMenuAPI.create).toHaveBeenCalledWith({
      quick_menu: {
        name: 'Support',
        body: 'Choose a department',
        items: [{ title: 'Billing' }],
      },
    });
  });

  it('updates and deletes a selected menu through the account API', async () => {
    const menu = {
      id: 3,
      name: 'Support',
      body: 'Choose',
      items: [{ title: 'Billing' }],
    };
    quickMenuAPI.get.mockResolvedValue({ data: [menu] });
    const wrapper = mountSettings('administrator');
    await flushPromises();
    await wrapper
      .findAll('button')
      .find(button => button.text() === 'QUICK_MENUS.EDIT')
      .trigger('click');
    await wrapper.findAll('input')[0].setValue('Support desk');
    await wrapper
      .findAll('button')
      .find(button => button.text() === 'QUICK_MENUS.SAVE')
      .trigger('click');
    await flushPromises();
    expect(quickMenuAPI.update).toHaveBeenCalledWith(3, {
      quick_menu: {
        name: 'Support desk',
        body: 'Choose',
        items: [{ title: 'Billing' }],
      },
    });
    await wrapper
      .findAll('button')
      .find(button => button.text() === 'QUICK_MENUS.DELETE')
      .trigger('click');
    await flushPromises();
    expect(quickMenuAPI.delete).toHaveBeenCalledWith(3);
  });
});
