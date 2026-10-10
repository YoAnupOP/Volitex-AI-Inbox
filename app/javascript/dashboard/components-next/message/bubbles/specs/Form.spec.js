import { mount } from '@vue/test-utils';
import { ref } from 'vue';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { useMessageContext } from '../../provider.js';

vi.mock('../../provider.js', () => ({ useMessageContext: vi.fn() }));
vi.mock('dashboard/composables/useInbox', () => ({
  useInbox: () => ({ isAWebWidgetInbox: ref(false) }),
}));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));

import Form from '../Form.vue';

const mountForm = ({
  contentType = 'input_select',
  messageType = 1,
  items,
}) => {
  useMessageContext.mockReturnValue({
    content: ref('Choose one'),
    contentAttributes: ref({ items }),
    contentType: ref(contentType),
    messageType: ref(messageType),
  });
  return mount(Form, {
    global: {
      stubs: { BaseBubble: { template: '<div><slot /></div>' } },
      directives: { dompurifyHtml: () => {} },
    },
  });
};

describe('Form input_select rendering', () => {
  beforeEach(() => vi.clearAllMocks());

  it('renders valid outgoing options as read-only items', () => {
    const wrapper = mountForm({
      items: [{ title: 'Billing' }, { title: 'A very long support option' }],
    });

    expect(wrapper.get('[data-testid="input-select-items"]').text()).toBe(
      'BillingA very long support option'
    );
    expect(wrapper.findAll('button')).toHaveLength(0);
  });

  it('ignores malformed options and does not render options on inbound messages', () => {
    const malformed = mountForm({
      items: [
        null,
        { value: 'missing title' },
        { title: ' ' },
        { title: 'Valid' },
      ],
    });
    expect(malformed.get('[data-testid="input-select-items"]').text()).toBe(
      'Valid'
    );

    const inbound = mountForm({
      messageType: 0,
      items: [{ title: 'Pick' }],
    });
    expect(inbound.find('[data-testid="input-select-items"]').exists()).toBe(
      false
    );
  });
});
