import { ref, readonly, computed } from 'vue';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

const activeTheme = ref('light');

export const useTheme = () => {
  const getThemeFromStorage = () => {
    let theme = LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME);
    if (!theme || theme === 'auto') {
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      theme = prefersDark ? 'dark' : 'light';
    }
    return theme;
  };

  const setTheme = (theme) => {
    activeTheme.value = theme;
    if (theme === 'dark') {
      document.body.classList.add('dark');
      document.documentElement.classList.add('dark');
      document.documentElement.style.setProperty('color-scheme', 'dark');
      LocalStorage.set(LOCAL_STORAGE_KEYS.COLOR_SCHEME, 'dark');
    } else {
      document.body.classList.remove('dark');
      document.documentElement.classList.remove('dark');
      document.documentElement.style.setProperty('color-scheme', 'light');
      LocalStorage.set(LOCAL_STORAGE_KEYS.COLOR_SCHEME, 'light');
    }
  };

  const toggleTheme = () => {
    setTheme(activeTheme.value === 'dark' ? 'light' : 'dark');
  };

  // Sync state initially
  activeTheme.value = getThemeFromStorage();

  return {
    theme: readonly(activeTheme),
    isDarkMode: computed(() => activeTheme.value === 'dark'),
    setTheme,
    toggleTheme,
  };
};
