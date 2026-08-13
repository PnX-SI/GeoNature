import { Component, OnInit, Input } from '@angular/core';
import { UntypedFormBuilder, UntypedFormGroup, Validators } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { Publication } from './publication.model';
import { Nomenclature } from '@geonature_common/interfaces';
import { CommonService } from '@geonature_common/service/common.service';
import { PublicationsListService } from '../services/publication.service';

@Component({
  selector: 'pnx-publication-form-modal',
  templateUrl: './publication-form-modal.component.html',
})
export class PublicationFormModalComponent implements OnInit {
  @Input() publication: Publication | null = null;

  public form: UntypedFormGroup;
  public publicationTypes: Nomenclature[] = [];
  public isLoading = false;

  constructor(
    public activeModal: NgbActiveModal,
    private formBuilder: UntypedFormBuilder,
    private publicationsListService: PublicationsListService,
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
  }

  private createForm(): UntypedFormGroup {
    return this.formBuilder.group({
      publication_reference: ['', [Validators.required, Validators.minLength(1)]],
      id_nomenclature_type_publication: [null],
      description_publication: [''],
      publication_url: [''],
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
          ? 'MetaData.PublicationsList.Messages.PublicationUpdated'
          : 'MetaData.PublicationsList.Messages.PublicationCreated';
        this._commonService.translateToaster('success', message);
        this.activeModal.close(payload);
      },
      () => {
        this.isLoading = false;
        let message = this.isEditMode
          ? 'MetaData.PublicationsList.Errors.Update'
          : 'MetaData.PublicationsList.Errors.Create';
        this._commonService.translateToaster('error', message);
      }
    );
  }

  onCancel() {
    this.activeModal.dismiss();
  }
}
