import { describe, expect, it } from 'vitest';
import { getInputSelectItems } from '../inputSelectHelper';

describe('getInputSelectItems', () => {
  it('returns valid items while preserving their exact titles', () => {
    const items = [
      { title: '  Billing help  ', value: 'billing' },
      { title: 'Long title '.repeat(10), value: 'long' },
    ];

    expect(getInputSelectItems(items)).toEqual(items);
  });

  it('ignores malformed items and blank titles', () => {
    expect(
      getInputSelectItems([
        null,
        'not an item',
        [],
        {},
        { title: '   ' },
        { title: 12 },
        { title: 'Valid' },
      ])
    ).toEqual([{ title: 'Valid' }]);
  });

  it('returns an empty array for missing or malformed attributes', () => {
    expect(getInputSelectItems(undefined)).toEqual([]);
    expect(getInputSelectItems({})).toEqual([]);
  });
});
