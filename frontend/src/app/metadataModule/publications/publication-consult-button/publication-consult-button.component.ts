import { Component, Input, TemplateRef, ViewChild } from '@angular/core';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { TranslateService } from '@ngx-translate/core';

@Component({
  selector: 'pnx-publication-consult-button',
  templateUrl: `publication-consult-button.component.html`,
})
export class PublicationConsultButtonComponent {
  @Input() publicationUrl: string | null = null;
  @ViewChild('externalLinkModal', { static: true })
  externalLinkModal!: TemplateRef<any>;

  public pendingExternalUrl: string | null = null;
  @Input() detailLook: boolean = false;

  constructor(
    private modal: NgbModal,
    private _translateService: TranslateService
  ) {}

  getTooltip(): string {
    return this._translateService.instant(
      this.publicationUrl ? 'MetaData.Publications.Consult' : 'MetaData.Publications.NoURL'
    );
  }

  onConsult() {
    if (!this.publicationUrl) {
      return;
    }

    this.pendingExternalUrl = this.publicationUrl;
    const modalRef = this.modal.open(this.externalLinkModal);
    modalRef.result.finally(() => {
      this.pendingExternalUrl = null;
    });
  }

  openExternalLink() {
    if (this.pendingExternalUrl) {
      window.open(this.pendingExternalUrl, '_blank', 'noopener,noreferrer');
    }
    this.pendingExternalUrl = null;
  }
}
