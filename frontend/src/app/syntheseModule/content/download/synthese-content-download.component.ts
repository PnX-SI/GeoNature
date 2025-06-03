import {
  Component,
} from '@angular/core';

import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { NgbModal, NgbModalModule } from '@ng-bootstrap/ng-bootstrap';
import { SyntheseModalDownloadComponent } from './modal-download/modal-download.component';

// Todo: à renommer
@Component({
  standalone: true,
  selector: 'pnx-synthese-content-download',
  templateUrl: 'synthese-content-download.component.html',
  styleUrls: ['synthese-content-download.component.scss'],
  imports: [GN2CommonModule, NgbModalModule],
})
export class SyntheseContentDownloadComponent {
  constructor(
    public cruvedStore: CruvedStoreService,
    private _ngbModal: NgbModal
  ) {}

  openDownloadModal() {
    this._ngbModal.open(SyntheseModalDownloadComponent, {
      size: 'lg',
    });
  }
}
