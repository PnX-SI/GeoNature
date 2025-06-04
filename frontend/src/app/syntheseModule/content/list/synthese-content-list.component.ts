import {
  Component,
} from '@angular/core';
import { RouterModule } from '@angular/router';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';
import { SyntheseContentListColumnsService } from './synthese-content-list-columns.service';

@Component({
  standalone: true,
  selector: 'pnx-synthese-content-list',
  templateUrl: 'synthese-content-list.component.html',
  styleUrls: ['synthese-content-list.component.scss'],
  imports: [NgxDatatableModule, RouterModule],
  providers: [SyntheseContentListColumnsService],
})
export class SyntheseContentListComponent {
  // //////////////////////////////////////////////////////////////////////////
  // data
  // //////////////////////////////////////////////////////////////////////////

  constructor(columnService: SyntheseContentListColumnsService) { }

  data: Array<any>;
}
