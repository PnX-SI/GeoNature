import { readdirSync, readFileSync, statSync } from 'fs';
import { join } from 'path';

// The buttons of the templates are Angular Material buttons: no Bootstrap button class
// (btn, btn-primary, btn-outline-*...) and no Bootstrap modal close button.
const ROOTS = [join(__dirname, '../..'), join(__dirname, '../../../../contrib')];

function templates(dir: string): string[] {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    if (name === 'node_modules') {
      return [];
    }
    return statSync(path).isDirectory() ? templates(path) : path.endsWith('.html') ? [path] : [];
  });
}

/** Opening tags of buttons and links, with the quotes of their attributes respected */
function buttonTags(template: string): string[] {
  const tags: string[] = [];
  const start = /<(button|a)(?=[\s>])/g;
  let match: RegExpExecArray;
  while ((match = start.exec(template))) {
    let quote: string = null;
    let i = match.index;
    for (; i < template.length; i++) {
      const c = template[i];
      if (quote) {
        quote = c === quote ? null : quote;
      } else if (c === '"' || c === "'") {
        quote = c;
      } else if (c === '>') {
        break;
      }
    }
    tags.push(template.slice(match.index, i + 1));
  }
  return tags;
}

const BOOTSTRAP_BUTTON =
  /\bbtn(-(sm|xs|lg|primary|secondary|success|danger|warning|info|light|dark|link|block|outline-[a-z]+))?\b(?!-)/;

describe('button templates', () => {
  const all = ROOTS.flatMap((root) => templates(root));

  it('finds the templates', () => {
    expect(all.length).toBeGreaterThan(100);
  });

  it('use no Bootstrap button class', () => {
    const offenders = all.flatMap((file) =>
      buttonTags(readFileSync(file, 'utf8').replace(/<!--[\s\S]*?-->/g, ''))
        .filter((tag) => {
          const classes = /\sclass="([^"]*)"/.exec(tag)?.[1].split(/\s+/) ?? [];
          return classes.some(
            (c) =>
              BOOTSTRAP_BUTTON.test(c) &&
              /^btn(-[a-z-]+)?$/.test(c) &&
              !/^btn-(row|action|actions|clear|neutral|ghost|no-padding|add-.*|valid-media|cancel-media|toogle-sidenav)$/.test(
                c
              )
          );
        })
        .map((tag) => `${file}: ${tag.replace(/\s+/g, ' ').slice(0, 100)}`)
    );
    expect(offenders).toEqual([]);
  });

  it('use no Bootstrap modal close button', () => {
    const offenders = all.flatMap((file) =>
      buttonTags(readFileSync(file, 'utf8').replace(/<!--[\s\S]*?-->/g, ''))
        .filter((tag) => /\sclass="[^"]*\bclose\b/.test(tag) && !/\bmat-[a-z-]*button\b/.test(tag))
        .map((tag) => `${file}: ${tag.replace(/\s+/g, ' ').slice(0, 100)}`)
    );
    expect(offenders).toEqual([]);
  });
});
