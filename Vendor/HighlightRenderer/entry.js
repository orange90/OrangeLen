import hljs from 'highlight.js';
export function render(source, language) {
  if (!language || !hljs.getLanguage(language)) return null;
  return hljs.highlight(source, {language, ignoreIllegals: true}).value;
}
export function languages() { return hljs.listLanguages(); }
