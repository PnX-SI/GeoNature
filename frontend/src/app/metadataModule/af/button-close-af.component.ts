import { Component, Input, Output, EventEmitter, ViewChild, TemplateRef } from '@angular/core';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { TranslateService } from '@ngx-translate/core';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { CommonService } from '@geonature_common/service/common.service';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'gn-button-close-af',
  templateUrl: './button-close-af.component.html',
  styleUrls: ['./button-close-af.component.scss'],
})
export class ButtonCloseAfComponent {
  @Input() acquisitionFramework: any;
  @Input() buttonType: 'Toolbar' | 'Floating' = 'Toolbar';
  @Output() afClosed = new EventEmitter<void>();
  @Output() afOpened = new EventEmitter<void>();

  @ViewChild('publishModal') publishModal: TemplateRef<any>;

  afPublishModalLabel: string;
  afPublishModalContent: string;

  constructor(
    private _dfs: DataFormService,
    private _commonService: CommonService,
    private modal: NgbModal,
    private translate: TranslateService,
    public config: ConfigService
  ) {
    this.afPublishModalLabel = this.config.METADATA.CLOSED_MODAL_LABEL;
    this.afPublishModalContent = this.config.METADATA.CLOSED_MODAL_CONTENT;
  }

  get opened(): boolean {
    return this.acquisitionFramework?.opened;
  }

  isOpenable(): boolean {
    return (
      this.config.METADATA?.AF_OPENABLE &&
      this.acquisitionFramework?.cruved?.U &&
      !this.acquisitionFramework?.opened
    );
  }

  getTooltip(): string {
    if (!this.acquisitionFramework?.cruved?.U) {
      return this.translate.instant('Errors.NotAllowed');
    }
    if (!this.config.METADATA?.AF_OPENABLE && !this.acquisitionFramework?.opened) {
      return this.translate.instant('MetaData.Messages.OpenAFImpossible');
    }
    return this.acquisitionFramework?.opened
      ? this.translate.instant('MetaData.Actions.CloseAF')
      : this.translate.instant('MetaData.Actions.OpenAF');
  }

  openPublishModal(event: MouseEvent) {
    event?.stopPropagation();
    this.modal.open(this.publishModal, { size: 'lg' });
  }

  publishAf() {
    this._dfs.publishAf(this.acquisitionFramework.id_acquisition_framework).subscribe(
      () => {
        this.afClosed.emit();
      },
      (error) => {
        if (error?.error?.name == 'mailError') {
          this._commonService.regularToaster(
            'warning',
            "Erreur lors de l'envoi de l'email de confirmation. Le cadre d'acquisition a bien été fermé"
          );
          this.afClosed.emit();
        }
      }
    );
    this.modal.dismissAll();
  }

  openAf(click_event: MouseEvent) {
    click_event?.stopPropagation();
    this._dfs.openAf(this.acquisitionFramework.id_acquisition_framework).subscribe(() => {
      this.afOpened.emit();
    });
  }

  get disabled(): boolean {
    return !this.acquisitionFramework?.cruved?.U;
  }
}
