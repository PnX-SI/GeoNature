import {
  Component,
} from '@angular/core';
import { SyntheseContentListColumnsService } from './synthese-content-list-columns.service';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';

@Component({
  standalone: true,
  selector: 'pnx-synthese-content-list',
  templateUrl: 'synthese-content-list.component.html',
  styleUrls: ['synthese-content-list.component.scss'],
  imports: [GN2CommonModule, CommonModule],
  providers: [SyntheseContentListColumnsService],
})
export class SyntheseContentListComponent {

  constructor(
    public columnService: SyntheseContentListColumnsService,

  ) {}

  // //////////////////////////////////////////////////////////////////////////
  // data
  // //////////////////////////////////////////////////////////////////////////

  data: Array<any>;


}
