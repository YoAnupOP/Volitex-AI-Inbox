import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

export const setColorTheme = () => {
  let theme = LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME);
  if (!theme || theme === 'auto') {
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    theme = prefersDark ? 'dark' : 'light';
  }
  if (theme === 'dark') {
    document.body.classList.add('dark');
    document.documentElement.classList.add('dark');
    document.documentElement.style.setProperty('color-scheme', 'dark');
  } else {
    document.body.classList.remove('dark');
    document.documentElement.classList.remove('dark');
    document.documentElement.style.setProperty('color-scheme', 'light');
  }
};
