import { useAppearanceHotKeys } from '../useAppearanceHotKeys';

describe('useAppearanceHotKeys', () => {
  it.each([
    [false, undefined],
    [true, undefined],
    [false, 'light'],
    [true, 'light'],
    [true, 'dark'],
    [true, 'auto'],
  ])(
    'does not expose theme commands for system dark=%s and saved theme=%s',
    (prefersDark, savedTheme) => {
      window.matchMedia = vi.fn().mockReturnValue({ matches: prefersDark });
      if (savedTheme) {
        localStorage.theme = savedTheme;
      } else {
        localStorage.removeItem('theme');
      }

      const { goToAppearanceHotKeys } = useAppearanceHotKeys();
      expect(goToAppearanceHotKeys.value).toEqual([]);
      expect(window.matchMedia).not.toHaveBeenCalled();
      localStorage.removeItem('theme');
    }
  );
});
