import {
  setPortalHoverColor,
  removeQueryParamsFromUrl,
  updateThemeInHeader,
  switchTheme,
  initializeThemeHandlers,
  initializeMediaQueryListener,
  initializeTheme,
} from '../portalThemeHelper.js';
import { adjustColorForContrast } from '../../shared/helpers/colorHelper.js';

describe('portalThemeHelper', () => {
  let themeToggleButton;
  let appearanceDropdown;

  beforeEach(() => {
    themeToggleButton = document.createElement('div');
    themeToggleButton.id = 'toggle-appearance';
    document.body.appendChild(themeToggleButton);

    appearanceDropdown = document.createElement('div');
    appearanceDropdown.id = 'appearance-dropdown';
    appearanceDropdown.classList.add('appearance-menu');
    document.body.appendChild(appearanceDropdown);

    window.matchMedia = vi.fn().mockImplementation(query => ({
      matches: query === '(prefers-color-scheme: dark)',
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
    }));

    window.portalConfig = { portalColor: '#ff5733' };
    document.documentElement.style.setProperty = vi.fn();
    document.documentElement.classList.remove('dark', 'light');

    vi.clearAllMocks();
  });

  afterEach(() => {
    themeToggleButton.remove();
    appearanceDropdown.remove();
    delete window.portalConfig;
    document.documentElement.style.setProperty.mockRestore();
    document.documentElement.classList.remove('dark', 'light');
    localStorage.clear();
  });

  describe('#setPortalHoverColor', () => {
    it('keeps the light hover color when dark theme is requested', () => {
      const hoverColor = adjustColorForContrast('#ff5733', 'white');
      setPortalHoverColor('dark');
      expect(document.documentElement.style.setProperty).toHaveBeenCalledWith(
        '--dynamic-hover-color',
        hoverColor
      );
    });

    it('should apply light hover color in light theme', () => {
      const hoverColor = adjustColorForContrast('#ff5733', 'white');
      setPortalHoverColor('light');
      expect(document.documentElement.style.setProperty).toHaveBeenCalledWith(
        '--dynamic-hover-color',
        hoverColor
      );
    });
  });

  describe('#removeQueryParamsFromUrl', () => {
    let originalLocation;

    beforeEach(() => {
      originalLocation = window.location;
      delete window.location;
      window.location = new URL('http://localhost:3000/');
      window.history.replaceState = vi.fn();
    });

    afterEach(() => {
      window.location = originalLocation;
    });

    it('should not remove query params if theme is not in the URL', () => {
      removeQueryParamsFromUrl();
      expect(window.history.replaceState).not.toHaveBeenCalled();
    });

    it('should remove theme query param from the URL', () => {
      window.location = new URL(
        'http://localhost:3000/?theme=light&show_plain_layout=true'
      );
      removeQueryParamsFromUrl('theme');
      expect(window.history.replaceState).toHaveBeenCalledWith(
        {},
        '',
        'http://localhost:3000/?show_plain_layout=true'
      );
    });
  });

  describe('#updateThemeInHeader', () => {
    beforeEach(() => {
      themeToggleButton.innerHTML = `
        <div class="theme-button" data-theme="light"></div>
        <div class="theme-button" data-theme="dark"></div>
        <div class="theme-button" data-theme="system"></div>
      `;
    });

    it('should not update header if theme toggle button is not found', () => {
      themeToggleButton.remove();
      updateThemeInHeader('light');
      expect(document.querySelector('.theme-button')).toBeNull();
    });

    it('should show the theme button for the selected theme', () => {
      updateThemeInHeader('light');
      const lightButton = themeToggleButton.querySelector(
        '.theme-button[data-theme="light"]'
      );
      expect(lightButton.classList).toContain('flex');
    });
  });

  describe('#switchTheme', () => {
    it('uses light theme even when the system prefers dark', () => {
      window.matchMedia = vi.fn().mockReturnValue({ matches: true });
      switchTheme('system');
      expect(localStorage.theme).toBe('light');
      expect(document.documentElement.classList).toContain('light');
      expect(document.documentElement.classList).not.toContain('dark');
    });

    it('should set theme to light theme and update classes', () => {
      switchTheme('light');
      expect(localStorage.theme).toBe('light');
      expect(document.documentElement.classList).toContain('light');
    });

    it('normalizes a dark theme request to light', () => {
      switchTheme('dark');
      expect(localStorage.theme).toBe('light');
      expect(document.documentElement.classList).toContain('light');
      expect(document.documentElement.classList).not.toContain('dark');
    });
  });

  describe('#initializeThemeHandlers', () => {
    beforeEach(() => {
      appearanceDropdown.innerHTML = `
        <button data-theme="light"><span class="check-mark-icon light-theme"></span></button>
        <button data-theme="dark"><span class="check-mark-icon dark-theme"></span></button>
        <button data-theme="system"><span class="check-mark-icon system-theme"></span></button>
      `;
    });

    it('does nothing if the appearance dropdown is not found', () => {
      appearanceDropdown.remove();
      expect(() => initializeThemeHandlers()).not.toThrow();
    });

    it('should handle theme button clicks', () => {
      initializeThemeHandlers();

      // Simulate clicking a theme button
      const lightButton = appearanceDropdown.querySelector(
        'button[data-theme="light"]'
      );
      const clickEvent = new Event('click', { bubbles: true });
      Object.defineProperty(clickEvent, 'target', {
        value: lightButton,
        enumerable: true,
      });

      document.dispatchEvent(clickEvent);

      expect(localStorage.theme).toBe('light');
      expect(appearanceDropdown.dataset.currentTheme).toBe('light');
    });

    it('should toggle dropdown visibility on toggle button click', () => {
      initializeThemeHandlers();

      // Initially closed
      expect(appearanceDropdown.dataset.dropdownOpen).toBeUndefined();

      // Click to open
      themeToggleButton.click();
      expect(appearanceDropdown.dataset.dropdownOpen).toBe('true');

      // Click to close
      themeToggleButton.click();
      expect(appearanceDropdown.dataset.dropdownOpen).toBe('false');
    });

    it('should close dropdown when clicking outside', () => {
      initializeThemeHandlers();

      // Open dropdown
      appearanceDropdown.dataset.dropdownOpen = 'true';

      // Click outside
      const outsideClick = new Event('click', { bubbles: true });
      Object.defineProperty(outsideClick, 'target', {
        value: document.body,
        enumerable: true,
      });
      document.dispatchEvent(outsideClick);

      expect(appearanceDropdown.dataset.dropdownOpen).toBe('false');
    });
  });

  describe('#initializeMediaQueryListener', () => {
    let mediaQuery;

    beforeEach(() => {
      mediaQuery = {
        addEventListener: vi.fn(),
        matches: false,
      };
      window.matchMedia = vi.fn().mockReturnValue(mediaQuery);
    });

    it('does not subscribe to system theme changes', () => {
      initializeMediaQueryListener();
      expect(window.matchMedia).not.toHaveBeenCalled();
      expect(mediaQuery.addEventListener).not.toHaveBeenCalled();
    });

    it('preserves light theme without registering a listener', () => {
      localStorage.theme = 'light';
      initializeMediaQueryListener();
      expect(localStorage.theme).toBe('light');
      expect(mediaQuery.addEventListener).not.toHaveBeenCalled();
    });

    it('does not apply the system dark preference', () => {
      mediaQuery.matches = true;
      switchTheme();
      initializeMediaQueryListener();
      expect(document.documentElement.classList).toContain('light');
      expect(document.documentElement.classList).not.toContain('dark');
      expect(mediaQuery.addEventListener).not.toHaveBeenCalled();
    });

    it('keeps light theme when the system preference is light', () => {
      mediaQuery.matches = false;
      switchTheme();
      initializeMediaQueryListener();
      expect(document.documentElement.classList).toContain('light');
      expect(mediaQuery.addEventListener).not.toHaveBeenCalled();
    });
  });

  describe('#initializeTheme', () => {
    it('should not initialize theme if plain layout is enabled', () => {
      window.portalConfig.isPlainLayoutEnabled = 'true';
      initializeTheme();
      expect(localStorage.theme).toBeUndefined();
      expect(document.documentElement.classList).not.toContain('light');
      expect(document.documentElement.classList).not.toContain('dark');
    });

    it('initializes light theme regardless of the system preference', () => {
      initializeTheme();
      expect(localStorage.theme).toBe('light');
      expect(document.documentElement.classList).toContain('light');
      expect(document.documentElement.classList).not.toContain('dark');
      expect(window.matchMedia).not.toHaveBeenCalled();
    });

    it('sets the theme to the light theme', () => {
      localStorage.theme = 'light';
      document.documentElement.classList.add('light');
      initializeTheme();
      expect(localStorage.theme).toBe('light');
      expect(document.documentElement.classList.contains('light')).toBe(true);
    });

    it('replaces a saved dark preference with light theme', () => {
      localStorage.theme = 'dark';
      document.documentElement.classList.add('dark');
      initializeTheme();
      expect(localStorage.theme).toBe('light');
      expect(document.documentElement.classList.contains('light')).toBe(true);
      expect(document.documentElement.classList.contains('dark')).toBe(false);
    });
  });
});
