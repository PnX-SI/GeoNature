import { Component, OnInit, Input } from '@angular/core';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';

@Component({
    selector: 'pnx-modal-download',
    templateUrl: 'modal-download.component.html',
    styleUrls: ['./modal-download.component.scss'],

})

export class ModalDownloadComponent implements OnInit {

@Input ()pathDownload: string; 
@Input ()exportFormat : Array<string>;  

    constructor (private _modalService: NgbModal,) { }


    ngOnInit() {
        console.log("là", this.pathDownload);
        console.log(this.exportFormat);
        
     }

    
    loadData(format){
        document.location.href = this.pathDownload + '&export_format=' + format
    }
   
    openIntesectionModal(content) {
        this._modalService.open(content);
      }
}