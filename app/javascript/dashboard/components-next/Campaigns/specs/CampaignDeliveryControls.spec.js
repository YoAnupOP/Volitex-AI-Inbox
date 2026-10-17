import { flushPromises, mount } from '@vue/test-utils';
import { beforeEach, describe, expect, it, vi } from 'vitest';

const { api, dispatch } = vi.hoisted(() => ({
  api: { control: vi.fn(), recipients: vi.fn() },
  dispatch: vi.fn(),
}));
vi.mock('dashboard/api/campaigns', () => ({ default: api }));
vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch }),
}));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
import CampaignDeliveryControls from '../CampaignDeliveryControls.vue';

const render = (status = 'processing') =>
  mount(CampaignDeliveryControls, {
    props: {
      campaign: {
        id: 4,
        title: 'Test',
        campaign_status: status,
        recipient_counts: { accepted: 2, unknown: 1 },
      },
    },
    global: {
      stubs: {
        Button: {
          props: ['label', 'disabled'],
          template:
            '<button :disabled="disabled" @click="$emit(\'click\')">{{ label }}</button>',
        },
      },
    },
  });

describe('CampaignDeliveryControls', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    api.control.mockResolvedValue({});
    api.recipients.mockResolvedValue({ data: [] });
    dispatch.mockResolvedValue({});
  });

  it('shows progress and warns about uncertain and in-flight outcomes', () => {
    const wrapper = render();
    expect(wrapper.text()).toContain('CAMPAIGN.DELIVERY.STATES.unknown');
    expect(wrapper.text()).toContain('CAMPAIGN.DELIVERY.WARNING');
  });

  it('pauses through the account-scoped API and refreshes progress', async () => {
    const wrapper = render();
    await wrapper.findAll('button')[0].trigger('click');
    await flushPromises();
    expect(api.control).toHaveBeenCalledWith(4, 'pause');
    expect(dispatch).toHaveBeenCalledWith('campaigns/get');
  });

  it('prevents duplicate submissions while pending', async () => {
    api.control.mockReturnValue(new Promise(() => {}));
    const wrapper = render();
    const pause = wrapper.findAll('button')[0];
    await pause.trigger('click');
    await pause.trigger('click');
    expect(api.control).toHaveBeenCalledTimes(1);
    expect(pause.attributes('disabled')).toBeDefined();
  });

  it('shows actionable failures and clears loading', async () => {
    api.control.mockRejectedValue(new Error('offline'));
    const wrapper = render();
    await wrapper.findAll('button')[0].trigger('click');
    await flushPromises();
    expect(wrapper.find('[role="alert"]').text()).toBe(
      'CAMPAIGN.DELIVERY.ERROR'
    );
    expect(wrapper.findAll('button')[0].attributes('disabled')).toBeUndefined();
  });

  it('offers resume for paused campaigns', async () => {
    const wrapper = render('paused');
    await wrapper.findAll('button')[0].trigger('click');
    expect(api.control).toHaveBeenCalledWith(4, 'resume');
  });

  it('does not offer mutation controls for terminal campaigns', () => {
    const wrapper = render('cancelled');
    expect(wrapper.text()).not.toContain('CAMPAIGN.DELIVERY.PAUSE');
    expect(wrapper.text()).not.toContain('CAMPAIGN.DELIVERY.RESUME');
    expect(wrapper.text()).not.toContain('CAMPAIGN.DELIVERY.CANCEL');
  });

  it('loads bounded recipient pages and stops at the end', async () => {
    const wrapper = render();
    const button = wrapper
      .findAll('button')
      .find(item => item.text() === 'CAMPAIGN.DELIVERY.RECIPIENTS');
    await button.trigger('click');
    await flushPromises();
    expect(api.recipients).toHaveBeenCalledWith(4, 0);
    expect(wrapper.text()).not.toContain('CAMPAIGN.DELIVERY.RECIPIENTS');
  });
});
