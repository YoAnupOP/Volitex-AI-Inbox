import { EditorState, EditorView } from '@chatwoot/prosemirror-schema';
import { Schema } from 'prosemirror-model';

describe('ProseMirror clipboard security', () => {
  it('validates attributes supplied by untrusted clipboard slice context', () => {
    const unsafeProtocol = ['java', 'script'].join('').concat(':');
    const unsafeHref = `${unsafeProtocol}alert(1)`;
    const validate = vi.fn(value => {
      if (typeof value !== 'string' || value.startsWith(unsafeProtocol)) {
        throw new RangeError('Invalid clipboard attribute');
      }
    });
    const schema = new Schema({
      nodes: {
        doc: { content: 'block+' },
        wrapper: {
          content: 'paragraph+',
          group: 'block',
          attrs: { href: { default: '', validate } },
          toDOM: node => ['section', { 'data-href': node.attrs.href }, 0],
        },
        paragraph: {
          content: 'text*',
          group: 'block',
          parseDOM: [{ tag: 'p' }],
          toDOM: () => ['p', 0],
        },
        text: {},
      },
    });
    const element = document.createElement('div');
    document.body.appendChild(element);
    const view = new EditorView(element, {
      state: EditorState.create({ schema }),
    });
    try {
      view.pasteHTML(
        '<p data-pm-slice="0 0 [&quot;wrapper&quot;,{&quot;href&quot;:&quot;javascript:alert(1)&quot;}]">customer text</p>',
        new Event('paste')
      );
      expect(validate).toHaveBeenCalledWith(unsafeHref);
      expect(view.state.doc.textContent).toBe('customer text');
      expect(element.innerHTML).not.toContain(unsafeProtocol);
    } finally {
      view.destroy();
      element.remove();
    }
  });
});
