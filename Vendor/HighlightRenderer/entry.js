import hljs from 'highlight.js';
import {registerExtras} from './extra-languages.js';
registerExtras(hljs);
export function render(source, language) {
  if (!language || !hljs.getLanguage(language)) return null;
  return hljs.highlight(source, {language, ignoreIllegals: true}).value;
}
export function languages() { return hljs.listLanguages(); }
