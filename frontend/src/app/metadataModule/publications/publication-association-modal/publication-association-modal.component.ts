import { Component, Input, OnInit } from '@angular/core';
import { UntypedFormBuilder, UntypedFormGroup, Validators } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { CommonService } from '@geonature_common/service/common.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { PublicationsService } from '../../services/publication.service';
import { Association } from '../publication.model';
import { TranslateService } from '@ngx-translate/core';
import { Observable } from '@librairies/rxjs';

@Component({
  selector: 'pnx-publication-association-modal',
  templateUrl: './publication-association-modal.component.html',
})
export class PublicationAssociationModalComponent implements OnInit {
  @Input() from!: Association;
  @Input() to!: Association;
  @Input() elementId!: number;

  form: UntypedFormGroup;
  isLoading = false;

  constructor(
    public activeModal: NgbActiveModal,
    private fb: UntypedFormBuilder,
    private commonService: CommonService,
    private publicationsListService: PublicationsService
  ) {
    this.form = this.fb.group({
      targetElement: [null, Validators.required],
    });
  }

  ngOnInit(): void {}

  submit(): void {
    if (this.form.invalid) {
      return;
    }

    this.isLoading = true;

    const targetElement = this.form.value.targetElement;
    let request$: Observable<any>;
    if (this.from === 'AcquisitionFramework') {
      request$ = this.publicationsListService.associateAfToPublication(
        targetElement,
        this.elementId
      );
    } else if (this.from === 'Dataset') {
      request$ = this.publicationsListService.associateDatasetToPublication(
        targetElement,
        this.elementId
      );
    } else {
      if (this.to === 'Dataset')
        request$ = this.publicationsListService.associateDatasetToPublication(
          this.elementId,
          targetElement
        );
      else
        request$ = this.publicationsListService.associateAfToPublication(
          this.elementId,
          targetElement
        );
    }

    request$.subscribe(
      () => {
        this.isLoading = false;
        this.commonService.translateToaster('success', 'MetaData.Messages.AssociationCreated');
        this.activeModal.close(true);
        window.location.reload();
      },
      () => {
        this.isLoading = false;
      }
    );
  }

  cancel(): void {
    this.activeModal.dismiss();
  }
}
