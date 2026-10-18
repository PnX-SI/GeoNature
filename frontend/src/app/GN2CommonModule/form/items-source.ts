import { Observable } from 'rxjs';

/**
 * Where the items of a field come from. The connected components (``pnx-datasets``,
 * ``pnx-nomenclature``, ...) only know a source, so they can be tested without HTTP and the
 * source can be replaced.
 * @typeParam Q what the source needs to load the items
 * @typeParam T the items
 */
export interface ItemsSource<Q, T> {
  load(query: Q): Observable<T[]>;
}
