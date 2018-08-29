import { Component, OnInit, Input, EventEmitter, Output } from '@angular/core';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpParams } from '@angular/common/http';

@Component({
  selector: 'pnx-modal-download',
  templateUrl: 'modal-download.component.html',
  styleUrls: ['./modal-download.component.scss']
})
export class ModalDownloadComponent implements OnInit {
  @Input() pathDownload: string;
  @Input() queryString: HttpParams;
  @Input() exportFormat: Array<string>;
  @Input() labelButton: string;
  @Input() downloadMessage: string;
  @Output() buttonClicked = new EventEmitter<any>();

  constructor(private _modalService: NgbModal) {}

  ngOnInit() {
    this.labelButton = this.labelButton || 'Télécharger';
    this.queryString = this.queryString || new HttpParams();
  }

  loadData(format) {
    this.queryString = this.queryString.append('export_format', format);
    document.location.href = this.pathDownload + this.queryString.toString();
  }

  openModal(content) {
    this._modalService.open(content);
    this.buttonClicked.emit();
  }
}
