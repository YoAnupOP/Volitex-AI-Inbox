import { describe, expect, it } from 'vitest';
import {
  getQuickMenuType,
  isQuickMenuActionVisible,
  validateQuickMenu,
} from '../quickMenuHelper';

describe('quickMenuHelper', () => {
  it('maps 1–3 items to buttons and 4–10 to a list', () => {
    expect(getQuickMenuType([{ title: 'One' }])).toBe('buttons');
    expect(getQuickMenuType(new Array(4).fill({ title: 'One' }))).toBe('list');
  });

  it('shows the action only for WhatsApp Cloud inboxes', () => {
    expect(
      isQuickMenuActionVisible({
        channel_type: 'Channel::Whatsapp',
        provider: 'whatsapp_cloud',
      })
    ).toBe(true);
    expect(
      isQuickMenuActionVisible({
        channel_type: 'Channel::Whatsapp',
        provider: 'default',
      })
    ).toBe(false);
  });

  it('validates body, count, title limits and normalized duplicates', () => {
    expect(
      validateQuickMenu({
        name: 'Menu',
        body: 'Body',
        items: [{ title: 'Help' }, { title: ' help ' }],
      })['item-1']
    ).toBe('duplicate');
    expect(
      validateQuickMenu({
        name: 'Menu',
        body: 'x'.repeat(1025),
        items: [{ title: 'x'.repeat(21) }],
      })
    ).toMatchObject({ body: 'too_long', 'item-0': 'too_long' });
  });
});
