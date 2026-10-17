import { setColorTheme } from 'dashboard/helper/themeHelper.js';
import { LocalStorage } from 'shared/helpers/localStorage';

vi.mock('shared/helpers/localStorage');

describe('setColorTheme', () => {
  beforeEach(() => {
    document.body.className = '';
    document.documentElement.className = '';
    document.documentElement.removeAttribute('style');
    window.matchMedia = vi.fn().mockReturnValue({ matches: true });
  });
  it('should set body class to dark if selectedColorScheme is dark', () => {
    LocalStorage.get.mockReturnValue('dark');
    setColorTheme();
    expect(document.body.classList.contains('dark')).toBe(true);
  });

  it('should set body class to dark if selectedColorScheme is auto and isOSOnDarkMode is true', () => {
    LocalStorage.get.mockReturnValue('auto');
    setColorTheme();
    expect(document.body.classList.contains('dark')).toBe(true);
  });

  it('should not set body class to dark if selectedColorScheme is auto and isOSOnDarkMode is false', () => {
    LocalStorage.get.mockReturnValue('auto');
    window.matchMedia.mockReturnValue({ matches: false });
    setColorTheme();
    expect(document.body.classList.contains('dark')).toBe(false);
  });

  it('should not set body class to dark if selectedColorScheme is light', () => {
    LocalStorage.get.mockReturnValue('light');
    setColorTheme();
    expect(document.body.classList.contains('dark')).toBe(false);
  });

  it('should not set body class to dark if selectedColorScheme is undefined', () => {
    LocalStorage.get.mockReturnValue(undefined);
    setColorTheme();
    expect(document.body.classList.contains('dark')).toBe(true);
  });

  it('should set documentElement style to dark if selectedColorScheme is dark', () => {
    LocalStorage.get.mockReturnValue('dark');
    setColorTheme();
    expect(document.documentElement.getAttribute('style')).toBe(
      'color-scheme: dark;'
    );
  });

  it('should set documentElement style to dark if selectedColorScheme is auto and isOSOnDarkMode is true', () => {
    LocalStorage.get.mockReturnValue('auto');
    setColorTheme();
    expect(document.documentElement.getAttribute('style')).toBe(
      'color-scheme: dark;'
    );
  });

  it('should set documentElement style to light if selectedColorScheme is auto and isOSOnDarkMode is false', () => {
    LocalStorage.get.mockReturnValue('auto');
    window.matchMedia.mockReturnValue({ matches: false });
    setColorTheme();
    expect(document.documentElement.getAttribute('style')).toBe(
      'color-scheme: light;'
    );
  });

  it('should set documentElement style to light if selectedColorScheme is light', () => {
    LocalStorage.get.mockReturnValue('light');
    setColorTheme();
    expect(document.documentElement.getAttribute('style')).toBe(
      'color-scheme: light;'
    );
  });

  it('should set documentElement style to light if selectedColorScheme is undefined', () => {
    LocalStorage.get.mockReturnValue(undefined);
    setColorTheme();
    expect(document.documentElement.getAttribute('style')).toBe(
      'color-scheme: dark;'
    );
  });
});
