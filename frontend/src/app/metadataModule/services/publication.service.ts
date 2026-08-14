import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { UntypedFormGroup, UntypedFormBuilder } from '@angular/forms';
import { BehaviorSubject, Observable } from 'rxjs';
import { map, tap, finalize } from 'rxjs/operators';

import { ConfigService } from '@geonature/services/config.service';
import { Publication } from '../publications/publication.model';
import { Nomenclature } from '@geonature_common/interfaces';

@Injectable({
  providedIn: 'root',
})
export class PublicationsListService {
  private _publications$ = new BehaviorSubject<Publication[]>([]);
  public publications: Observable<Publication[]> = this._publications$.asObservable();

  private _currentPage = 1;

  public readonly pageSize = 25;

  public totalItems = new BehaviorSubject<number>(0);

  public isLoading = false;

  public form: UntypedFormGroup;

  constructor(
    private _http: HttpClient,
    private _fb: UntypedFormBuilder,
    private _config: ConfigService
  ) {
    this.form = this._fb.group({
      search: [null],
      type_publication: [null],
      orderby: ['id_publication'],
      order: ['desc'],
    });
  }
  getPublication(id_publication: number): Observable<Publication> {
    const apiEndpoint = `${this._config.API_ENDPOINT}/meta/publication/${id_publication}`;

    return this._http.get<Publication>(apiEndpoint);
  }

  get currentPage(): number {
    return this._currentPage;
  }

  setPage(page: number) {
    // Start at page 1
    this._currentPage = Math.max(1, page);

    this.search().subscribe();
  }

  searchFromFirstPage(): Observable<Publication[]> {
    this._currentPage = 1;

    return this.search();
  }

  private buildParams(): HttpParams {
    let params = new HttpParams()
      .set('page', this._currentPage.toString())
      .set('per_page', this.pageSize.toString());

    const values = this.form.value;

    Object.keys(values).forEach((key) => {
      const value = values[key];

      if (value !== null && value !== undefined && value !== '') {
        if (Array.isArray(value)) {
          value.forEach((v) => {
            params = params.append(key, v);
          });
        } else {
          params = params.set(key, value);
        }
      }
    });

    return params;
  }

  search(): Observable<Publication[]> {
    this.isLoading = true;

    const params = this.buildParams();

    const apiEndpoint = `${this._config.API_ENDPOINT}/meta/publications`;

    return this._http
      .get<{
        items: Publication[];
        total: number;
        page: number;
        pages: number;
        per_page: number;
      }>(apiEndpoint, { params })
      .pipe(
        tap((result) => {
          this._publications$.next(result.items || []);
          this.totalItems.next(result.total || 0);
        }),
        map((result) => result.items || []),
        finalize(() => {
          this.isLoading = false;
        })
      );
  }

  getPublicationTypes(): Observable<Nomenclature[]> {
    const apiEndpoint = `${this._config.API_ENDPOINT}/nomenclatures/nomenclature/PUBLICATION_TYPE`;

    return this._http
      .get<{ values: Nomenclature[] }>(apiEndpoint)
      .pipe(map((response) => response.values ?? []));
  }

  searchSimilarPublications(similarity_search: string): Observable<{
    items: Publication[];
    total: number;
  }> {
    let params = new HttpParams()
      .set('page', '1')
      .set('per_page', '3')
      .set('similarity_search', similarity_search);

    const apiEndpoint = `${this._config.API_ENDPOINT}/meta/publications`;

    return this._http
      .get<{
        items: Publication[];
        total: number;
      }>(apiEndpoint, { params })
      .pipe(
        map((result) => ({
          items: result.items || [],
          total: result.total || 0,
        }))
      );
  }

  createPublication(publication: Partial<Publication>): Observable<Publication> {
    const apiEndpoint = `${this._config.API_ENDPOINT}/meta/publication`;

    return this._http.post<Publication>(apiEndpoint, publication).pipe(
      tap(() => {
        // Reload list after creation
        this.searchFromFirstPage().subscribe();
      })
    );
  }

  updatePublication(
    id_publication: number,
    publication: Partial<Publication>
  ): Observable<Publication> {
    const apiEndpoint = `${this._config.API_ENDPOINT}/meta/publication/${id_publication}`;

    return this._http.post<Publication>(apiEndpoint, publication).pipe(
      tap(() => {
        // Reload list after update
        this.searchFromFirstPage().subscribe();
      })
    );
  }

  deletePublication(id_publication: number): Observable<Publication> {
    const apiEndpoint = `${this._config.API_ENDPOINT}/meta/publication/${id_publication}`;
    return this._http.delete<Publication>(apiEndpoint).pipe(
      tap(() => {
        this.searchFromFirstPage().subscribe();
      })
    );
  }
}
