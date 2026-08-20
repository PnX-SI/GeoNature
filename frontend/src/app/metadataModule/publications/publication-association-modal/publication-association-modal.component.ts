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
  targetItems: any[] = [];

  constructor(
    public activeModal: NgbActiveModal,
    private fb: UntypedFormBuilder,
    private commonService: CommonService,
    private dataFormService: DataFormService,
    private publicationsListService: PublicationsService,
    private translateService: TranslateService
  ) {
    this.form = this.fb.group({
      targetElement: [null, Validators.required],
    });
  }

  ngOnInit(): void {
    this.loadTargets();
  }

  getTargetName(): string {
    const labels: { [key: string]: string } = {
      AcquisitionFramework: 'AcquisitionFramework',
      Dataset: 'Dataset',
      Publication: 'MetaData.Publications.Publication',
    };

    return this.translateService.instant(labels[this.to]);
  }

  private loadTargets(): void {
    if (this.to === 'AcquisitionFramework') {
      this.dataFormService.getAcquisitionFrameworksList({}, {}, 1, -1).subscribe((response) => {
        this.targetItems = response.items ?? [];
      });
      return;
    }

    if (this.to === 'Dataset') {
      this.dataFormService.getDatasets({}, {}).subscribe((response) => {
        this.targetItems = response ?? [];
      });
      return;
    }

    if (this.to === 'Publication') {
      this.publicationsListService.searchFromFirstPage().subscribe((items) => {
        this.targetItems = items ?? [];
      });
    }
  }

  getItemLabel(item: any): string {
    return (
      item?.publication_reference ||
      item?.dataset_name ||
      item?.acquisition_framework_name ||
      item?.acquisition_framework?.acquisition_framework_name ||
      item?.id_publication ||
      item?.id_dataset ||
      item?.id_acquisition_framework ||
      ''
    );
  }

  submit(): void {
    if (this.form.invalid) {
      return;
    }

    this.isLoading = true;

    const targetElement = this.form.value.targetElement;
    let request$: Observable<any>;
    if (this.from === 'AcquisitionFramework') {
      request$ = this.publicationsListService.associateAfToPublication(
        targetElement.id_publication,
        this.elementId
      );
    } else if (this.from === 'Dataset') {
      request$ = this.publicationsListService.associateDatasetToPublication(
        targetElement.id_publication,
        this.elementId
      );
    } else {
      if (this.to === 'Dataset')
        request$ = this.publicationsListService.associateDatasetToPublication(
          this.elementId,
          targetElement.id_dataset
        );
      else
        request$ = this.publicationsListService.associateAfToPublication(
          this.elementId,
          targetElement.id_acquisition_framework
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
