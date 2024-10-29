import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { CommonService } from '@geonature_common/service/common.service';
import { ImportDataService } from '../../services/data.service';
import { TranslateService } from '@ngx-translate/core';
import { Import } from '../../models/import.model';

@Component({
  selector: 'import-delete',
  templateUrl: './delete-modal.component.html',
})
export class ModalDeleteImport implements OnInit {
  @Input() row: Import;
  @Input() c: any;
  @Output() onDelete = new EventEmitter();
  constructor(
    private _commonService: CommonService,
    private _ds: ImportDataService,
    private translate: TranslateService
  ) {}

  ngOnInit() {}

  deleteImport() {
    this._ds.deleteImport(this.row.id_import).subscribe(() => {
      this._commonService.translateToaster('success', 'Import.ImportStatus.DeleteSuccessfully');
      this.onDelete.emit();
      this.c();
    });
  }
}
