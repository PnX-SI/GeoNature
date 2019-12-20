import { PipeTransform, Pipe } from '@angular/core';

@Pipe({ name: 'readablePropertie' })
export class ReadablePropertiePipe implements PipeTransform {
  transform(value, args) {
    const str: string = value.charAt(0).toUpperCase() + value.slice(1);

    return str.split('_').join(' ');
  }
}
