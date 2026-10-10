export const isQuickMenuActionVisible = inbox =>
  inbox?.channel_type === 'Channel::Whatsapp' &&
  inbox?.provider === 'whatsapp_cloud';

export const getQuickMenuType = items =>
  Array.isArray(items) && items.length >= 4 ? 'list' : 'buttons';

export const validateQuickMenu = ({ name, body, items }) => {
  const errors = {};
  if (!name?.trim()) errors.name = 'required';
  if (!body?.trim()) errors.body = 'required';
  if (body?.length > 1024) errors.body = 'too_long';
  if (!Array.isArray(items) || items.length < 1 || items.length > 10) {
    errors.items = 'count';
    return errors;
  }

  const titleLimit = items.length <= 3 ? 20 : 24;
  const normalized = new Set();
  items.forEach((item, index) => {
    const title = item?.title;
    if (typeof title !== 'string' || !title.trim()) {
      errors[`item-${index}`] = 'required';
    } else if (title.length > titleLimit) {
      errors[`item-${index}`] = 'too_long';
    } else {
      const key = title
        .normalize('NFKC')
        .trim()
        .replace(/\s+/g, ' ')
        .toLowerCase();
      if (normalized.has(key)) errors[`item-${index}`] = 'duplicate';
      normalized.add(key);
    }
  });

  return errors;
};
