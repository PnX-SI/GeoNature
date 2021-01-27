import { DomSanitizer } from '@angular/platform-browser';
import { PipeTransform, Pipe } from '@angular/core';

@Pipe({ name: 'stripHTML', pure: true })
export class StripHtmlPipe implements PipeTransform {
  constructor(private sanitized: DomSanitizer) {}
  transform(html: string) {
    // WARNING: this method is not safe ! Use it carrefully !
    return html.replace(/<.*?>/g, ''); // replace tags
  }
}

@Pipe({ name: 'safeStripHTML', pure: true })
export class SafeStripHtmlPipe implements PipeTransform {
  constructor(private sanitized: DomSanitizer) {}
  transform(html: string) {
    // WARNING: this method can be used only in browser !
    const tmp = document.createElement('DIV');
    tmp.innerHTML = html;
    return tmp.textContent || tmp.innerText || '';
  }
}
