import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { CommonService } from '@geonature_common/service/common.service';
import { ImportDataService } from '../../services/data.service';
import { Import } from '../../models/import.model';
import { ModalData } from '../../models/modal-data.model';

@Component({
  selector: 'import-action-modal',
  templateUrl: './action-modal.component.html',
  styleUrls: ['./action-modal.component.scss'],
})
export class ModalActionImport implements OnInit {
  @Input() data: Import; 
  @Input() c: any;  
  @Input() actionType: 'delete' | 'edit' = 'delete';
  @Input() modalData: ModalData = {
    title: 'Confirmation',
    bodyMessage: 'Êtes-vous sûr de vouloir effectuer cette action ?',
    additionalMessage: '',
    cancelButtonText: 'Annuler',
    confirmButtonText: 'Confirmer',
    confirmButtonColor: 'warn',
    headerDataQa: 'generic-modal-header',
    confirmButtonDataQa: 'modal-confirm-action',
  };
  @Output() onAction = new EventEmitter<{ confirmed: boolean; actionType: string; data?: any }>();

  constructor(
    private _commonService: CommonService,
    private _ds: ImportDataService
  ) {}

  ngOnInit() {}

  // Méthode générique pour traiter les actions
  performAction() {
    if (this.actionType === 'delete') {
      this.deleteImport();
    } else if (this.actionType === 'edit') {
      this.editImport();
    }
  }

  // Supprimer l'import
  deleteImport() {
    this._ds.deleteImport(this.data.id_import).subscribe(() => {
      this._commonService.translateToaster('success', 'Import.ImportStatus.DeleteSuccessfully');
      this.onAction.emit({ confirmed: true, actionType: this.actionType, data: this.data });
      this.c();
    });
  }

  // Modifier l'import
  editImport() {
      this.onAction.emit({ confirmed: true, actionType: this.actionType, data: this.data });
      this.c();
  }
}
