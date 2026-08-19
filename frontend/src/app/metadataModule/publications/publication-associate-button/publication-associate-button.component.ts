import { Component, Input } from '@angular/core';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { Association } from '@geonature/metadataModule/publications/publication.model';
import { PublicationAssociationModalComponent } from '../publication-association-modal/publication-association-modal.component';

@Component({
  selector: 'pnx-publication-associate-button',
  templateUrl: './publication-associate-button.component.html',
})
export class PublicationAssociateButtonComponent {
  @Input() from!: Association;
  @Input() to!: Association;
  @Input() elementId!: number;

  constructor(private _modal: NgbModal) {}

  openAssociationModal(): void {
    if (this.from != 'Publication' && this.to != 'Publication') {
      console.log("Can't open modal, from or to must be Publication");
      return;
    }

    const modalRef = this._modal.open(PublicationAssociationModalComponent, {
      size: 'lg',
      backdrop: 'static',
      keyboard: false,
    });

    modalRef.componentInstance.from = this.from;
    modalRef.componentInstance.to = this.to;
    modalRef.componentInstance.elementId = this.elementId;
  }
}
