import { Component, OnInit, Input, OnDestroy } from '@angular/core';
import { UntypedFormBuilder, UntypedFormGroup, Validators } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { Publication } from '../publication.model';
import { Nomenclature } from '@geonature_common/interfaces';
import { CommonService } from '@geonature_common/service/common.service';
import { PublicationsService } from '../../services/publication.service';
import { urlValidator } from '@geonature/utils/validator';
import { Subject } from 'rxjs';
import { takeUntil, debounceTime, distinctUntilChanged } from 'rxjs/operators';

@Component({
  selector: 'pnx-publication-form-modal',
  templateUrl: './publication-form-modal.component.html',
  styleUrls: ['./publication-form-modal.component.scss'],
})
export class PublicationFormModalComponent implements OnInit, OnDestroy {
  @Input() publication: Publication | null = null;
  @Input() getPublicationTypeLabel: (id: number) => string;
  public form: UntypedFormGroup;
  public publicationTypes: Nomenclature[] = [];
  public isLoading = false;

  private destroy$ = new Subject<void>();
  similarPublications: any[] = [];
  showSimilarWarning: boolean = false;
  selectedPublication: any = null;
  exactMatchExists: boolean = false;

  constructor(
    public activeModal: NgbActiveModal,
    private formBuilder: UntypedFormBuilder,
    private publicationsListService: PublicationsService,
    private _commonService: CommonService
  ) {
    this.form = this.createForm();
  }

  get isEditMode(): boolean {
    return this.publication != null;
  }

  ngOnInit() {
    this.publicationsListService.getPublicationTypes().subscribe((types) => {
      this.publicationTypes = types;
    });

    if (this.isEditMode && this.publication) {
      this.populateForm(this.publication);
    }

    // Check for similar publication references
    this.form
      .get('publication_reference')
      .valueChanges.pipe(takeUntil(this.destroy$), debounceTime(500), distinctUntilChanged())
      .subscribe((reference) => {
        this.checkSimilarReferences(reference);
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private createForm(): UntypedFormGroup {
    return this.formBuilder.group({
      publication_reference: ['', [Validators.required, Validators.minLength(1)]],
      id_nomenclature_type_publication: [null],
      description_publication: [''],
      publication_url: ['', urlValidator()],
    });
  }

  private populateForm(publication: Publication) {
    this.form.patchValue({
      publication_reference: publication.publication_reference,
      id_nomenclature_type_publication: publication.id_nomenclature_type_publication,
      description_publication: publication.description_publication,
      publication_url: publication.publication_url,
    });
  }

  /**
   * Check if the entered reference is similar to existing publication references
   */
  checkSimilarReferences(inputReference: string): void {
    if (!inputReference) {
      this.similarPublications = [];
      this.showSimilarWarning = false;
      this.exactMatchExists = false;
      return;
    }

    this.publicationsListService.searchSimilarPublications(inputReference).subscribe(
      (response) => {
        this.similarPublications = response.items;

        this.showSimilarWarning = this.similarPublications.length > 0;
        this.exactMatchExists = this.similarPublications.some(
          (pub) => pub.publication_reference === inputReference
        );
      },
      (error) => {
        console.error('Error searching publications:', error);
        this.similarPublications = [];
        this.showSimilarWarning = false;
        this.exactMatchExists = false;
      }
    );
  }

  viewPublicationDetails(publication: any): void {
    if (this.selectedPublication?.id_publication === publication.id_publication) {
      this.selectedPublication = null;
      return;
    }
    this.selectedPublication = publication;
  }

  onSubmit() {
    this.isLoading = true;

    const payload = this.form.value;

    const request$ =
      this.isEditMode && this.publication
        ? this.publicationsListService.updatePublication(this.publication.id_publication, payload)
        : this.publicationsListService.createPublication(payload);
    request$.subscribe(
      () => {
        this.isLoading = false;
        let message = this.isEditMode
          ? 'MetaData.Publications.Messages.PublicationUpdated'
          : 'MetaData.Publications.Messages.PublicationCreated';
        this._commonService.translateToaster('success', message);
        this.activeModal.close(payload);
      },
      () => {
        this.isLoading = false;
        let message = this.isEditMode
          ? 'MetaData.Publications.Errors.Update'
          : 'MetaData.Publications.Errors.Create';
        this._commonService.translateToaster('error', message);
      }
    );
  }

  onCancel() {
    this.activeModal.dismiss();
  }

  similar_element_to_display() {
    return this.exactMatchExists ? 1 : 3;
  }
}
