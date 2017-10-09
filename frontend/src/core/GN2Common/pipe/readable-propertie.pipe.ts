import { PipeTransform, Pipe } from '@angular/core';

@Pipe({ name: 'readablePropertie' })
export class ReadablePropertiePipe implements PipeTransform {
  transform(value, args) {
    const test: string = value.charAt(0).toUpperCase() + value.slice(1);

    return test.split('_').join(' ');
  }
}
