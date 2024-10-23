import { Component, Input, ViewChild } from '@angular/core';
import { FieldMappingService } from '@geonature/modules/imports/services/mappings/field-mapping.service';
import { ConfigService } from '@geonature/services/config.service';
import { ImportProcessService } from '../../import-process.service';
import { ImportDataService } from '@geonature/modules/imports/services/data.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { FormControl } from '@angular/forms';

@Component({
  selector: 'pnx-field-mapping-modal',
  templateUrl: './field-mapping-modal.component.html',
  styleUrls: ['./field-mapping-modal.component.scss'],
})
export class FieldMappingModalComponent {
  @Input() updateAvailable: boolean;
  @ViewChild('saveMappingModal') saveMappingModal;

  public modalCreateMappingForm = new FormControl('');
  constructor(
    private _fm: FieldMappingService,
    private config: ConfigService,
    private _importProcessService: ImportProcessService,
    private _importDataService: ImportDataService,
    private _modalService: NgbModal
  ) {}

  /**
   * Open the modal
   */
  open() {
    this._modalService.open(this.saveMappingModal, { size: 'lg' });
  }

  updateMapping() {
    // this.spinner = true;
    let name = '';
    // if (this.modalCreateMappingForm.value != this.fieldMappingForm.value.label) {
    //   name = this.modalCreateMappingForm.value;
    // }
    // this._importDataService
    //   .updateFieldMapping(this.fieldMappingForm.value.id, this.getFieldMappingValues(), name)
    //   .pipe()
    //   .subscribe(
    //     () => {
    //       this.processNextStep();
    //     },
    //     () => {
    //       this.spinner = false;
    //     }
    //   );
  }
}
