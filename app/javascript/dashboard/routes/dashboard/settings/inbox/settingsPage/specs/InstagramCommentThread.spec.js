import { mount } from '@vue/test-utils';
import InstagramCommentThread from '../InstagramCommentThread.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

const comment = {
  id: 'a',
  username: 'parent_a',
  text: 'Parent A',
  timestamp: '2026-08-16T00:00:00Z',
  hidden: false,
  replies: [
    {
      id: 'b',
      username: 'parent_b',
      text: 'B replies to A',
      timestamp: '2026-08-16T00:01:00Z',
      hidden: false,
      replies: [
        {
          id: 'c-to-b',
          username: 'child_c',
          text: 'C replies to B',
          timestamp: '2026-08-16T00:02:00Z',
          hidden: false,
          replies: [
            {
              id: 'd-to-c',
              username: 'child_d',
              text: 'D replies to C',
              timestamp: '2026-08-16T00:03:00Z',
              hidden: false,
              replies: [],
            },
          ],
        },
      ],
    },
    {
      id: 'c-to-a',
      username: 'child_c',
      text: 'C replies to A',
      timestamp: '2026-08-16T00:04:00Z',
      hidden: false,
      replies: [],
    },
  ],
};

describe('InstagramCommentThread', () => {
  it('renders nested replies under their actual parent branch', () => {
    const wrapper = mount(InstagramCommentThread, {
      props: {
        comment,
        formatTimestamp: timestamp => timestamp,
      },
      global: {
        stubs: { Button: true },
      },
    });

    expect(
      wrapper
        .findAll('[data-comment-id]')
        .map(item => item.attributes('data-comment-id'))
    ).toEqual(['a', 'b', 'c-to-b', 'd-to-c', 'c-to-a']);
    expect(
      wrapper
        .find('[data-comment-id="b"]')
        .find('[data-comment-id="c-to-b"]')
        .exists()
    ).toBe(true);
    expect(
      wrapper
        .find('[data-comment-id="c-to-b"]')
        .find('[data-comment-id="d-to-c"]')
        .exists()
    ).toBe(true);
    expect(
      wrapper
        .find('[data-comment-id="c-to-a"]')
        .find('[data-comment-id="c-to-b"]')
        .exists()
    ).toBe(false);
  });
});
