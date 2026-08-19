import { Component, OnInit, ViewChild } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { distinctUntilChanged, debounceTime, tap, switchMap, startWith } from 'rxjs/operators';
import { DatatableComponent } from '@swimlane/ngx-datatable';
import { PublicationsService } from '../../services/publication.service';
import { ConfigService } from '@geonature/services/config.service';
import { Publication } from '../publication.model';
import { Nomenclature } from '@geonature_common/interfaces';
import { PublicationFormModalComponent } from '@geonature/metadataModule/publications/publication-form-modal/publication-form-modal.component';

@Component({
  selector: 'pnx-publications-list',
  templateUrl: './publications-list.component.html',
  styleUrls: ['./publications-list.component.scss'],
})
export class PublicationsListComponent implements OnInit {
  @ViewChild(DatatableComponent)
  table: DatatableComponent;

  public publications: Publication[] = [];

  public rapidSearchControl: UntypedFormControl = new UntypedFormControl();

  public typeFilterControl: UntypedFormControl = new UntypedFormControl();

  public organisms: any[] = [];
  public roles: any[] = [];

  public publicationTypes: Nomenclature[] = [];

  constructor(
    private modal: NgbModal,
    public publicationsListService: PublicationsService,
    public config: ConfigService
  ) {}

  get isLoading(): boolean {
    return this.publicationsListService.isLoading;
  }

  get pageSize(): number {
    return this.publicationsListService.pageSize;
  }

  get pageOffset(): number {
    return this.publicationsListService.currentPage - 1;
  }

  get totalItems(): number {
    return this.publicationsListService.totalItems.value;
  }

  ngOnInit() {
    this.publicationsListService.getPublicationTypes().subscribe((types) => {
      this.publicationTypes = [
        { id_nomenclature: -1, label_fr: 'Aucun', label_default: 'Aucun' } as any,
        ...types,
      ];
    });

    this.publicationsListService.publications
      .pipe(distinctUntilChanged())
      .subscribe((publications) => {
        this.publications = publications;
      });

    this.rapidSearchControl.valueChanges
      .pipe(
        startWith(''),
        debounceTime(500),
        distinctUntilChanged(),
        tap((term) => {
          this.publicationsListService.form.patchValue({
            search: term === '' || term === null ? null : term,
          });
        }),
        switchMap(() => {
          return this.publicationsListService.searchFromFirstPage();
        })
      )
      .subscribe();

    this.typeFilterControl.valueChanges
      .pipe(
        distinctUntilChanged(),
        tap((type) => {
          this.publicationsListService.form.patchValue({
            type_publication: type,
          });
        }),
        switchMap(() => {
          return this.publicationsListService.searchFromFirstPage();
        })
      )
      .subscribe();

    this.publicationsListService.search().subscribe();
  }

  /**
   * return label of nomenclature by id
   */
  getPublicationTypeLabel(idNomenclature: number): string {
    const type = this.publicationTypes.find((t) => t.id_nomenclature === idNomenclature);

    return type?.label_default ?? String(idNomenclature);
  }

  onDatatablePage(event: { offset: number }) {
    this.publicationsListService.setPage(event.offset + 1);
  }

  onDatatableSort(event: {
    sorts: {
      prop: string;
      dir: string;
    }[];
  }) {
    const sort = event.sorts?.[0];
    if (!sort) {
      return;
    }
    this.publicationsListService.form.patchValue({
      orderby: sort.prop,
      order: sort.dir,
    });

    this.publicationsListService.searchFromFirstPage().subscribe();
  }

  GetUpsertModal() {
    return this.modal.open(PublicationFormModalComponent, {
      size: 'lg',
      backdrop: 'static',
      keyboard: false,
    });
  }

  onCreatePublication() {
    let modalRef = this.GetUpsertModal();
    modalRef.componentInstance.getPublicationTypeLabel = this.getPublicationTypeLabel.bind(this);

    modalRef.result.then((result) => {
      if (result) {
        this.publicationsListService.searchFromFirstPage().subscribe();
      }
    });
  }

  onEditPublication(publication: Publication) {
    const modalRef = this.GetUpsertModal();
    modalRef.componentInstance.publication = publication;
    modalRef.componentInstance.getPublicationTypeLabel = this.getPublicationTypeLabel.bind(this);

    modalRef.result.then((result) => {
      if (result) {
        this.publicationsListService.searchFromFirstPage().subscribe();
      }
    });
  }
}
