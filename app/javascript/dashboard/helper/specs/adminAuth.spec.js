import { readFileSync } from 'node:fs';
import { JSDOM } from 'jsdom';

const pages = [
  'app/views/super_admin/devise/sessions/new.html.erb',
  'app/views/installation/onboarding/index.html.erb',
];

describe.each(pages)('%s theme initialization', page => {
  const template = readFileSync(page, 'utf8');
  const script = template.match(/<script>([\s\S]*?)<\/script>/)[1];

  it.each([
    ['light', true, false],
    ['dark', false, true],
    ['auto', true, true],
    ['auto', false, false],
    [null, true, true],
    [null, false, false],
  ])(
    'respects stored %s with system dark=%s',
    (stored, systemDark, expected) => {
      const dom = new JSDOM(
        `<!doctype html><html class="admin-auth"><head><script>${script}</script></head><body></body></html>`,
        {
          url: 'http://localhost',
          runScripts: 'dangerously',
          beforeParse(window) {
            if (stored) window.localStorage.setItem('color_scheme', stored);
            window.matchMedia = () => ({ matches: systemDark });
          },
        }
      );
      expect(
        dom.window.document.documentElement.classList.contains('dark')
      ).toBe(expected);
      expect(
        dom.window.document.documentElement.classList.contains('admin-auth')
      ).toBe(true);
      dom.window.close();
    }
  );
});

const stylesheet = readFileSync(
  'app/javascript/dashboard/assets/scss/super_admin/index.scss',
  'utf8'
);

const luminance = value => {
  const channels = value
    .split(' ')
    .map(Number)
    .map(channel => {
      const s = channel / 255;
      return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
    });
  return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722;
};

describe.each([':root', '.dark'])('admin form contrast in %s', selector => {
  const block = stylesheet
    .slice(stylesheet.indexOf(`${selector} {`))
    .split('}')[0];
  const color = token => block.match(new RegExp(`--${token}: ([0-9 ]+);`))[1];

  it.each([
    ['slate-12', 'background-color'],
    ['slate-12', 'solid-2'],
    ['slate-11', 'solid-1'],
    ['slate-12', 'slate-1'],
    ['slate-11', 'slate-1'],
    ['ruby-11', 'ruby-3'],
  ])(
    '%s against %s meets WCAG AA normal text contrast',
    (foreground, background) => {
      const values = [
        luminance(color(foreground)),
        luminance(color(background)),
      ];
      expect(
        (Math.max(...values) + 0.05) / (Math.min(...values) + 0.05)
      ).toBeGreaterThanOrEqual(4.5);
    }
  );

  it('keeps the input focus ring distinguishable from its surface', () => {
    const values = [luminance(color('slate-9')), luminance(color('solid-2'))];
    expect(
      (Math.max(...values) + 0.05) / (Math.min(...values) + 0.05)
    ).toBeGreaterThanOrEqual(3);
  });
});
