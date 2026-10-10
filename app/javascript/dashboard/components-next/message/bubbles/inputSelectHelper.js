export const getInputSelectItems = items => {
  if (!Array.isArray(items)) return [];

  return items.filter(
    item =>
      item &&
      typeof item === 'object' &&
      !Array.isArray(item) &&
      typeof item.title === 'string' &&
      item.title.trim().length > 0
  );
};
