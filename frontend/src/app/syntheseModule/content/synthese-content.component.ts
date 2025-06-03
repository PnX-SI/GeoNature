import {
  Component,
  OnInit,
} from '@angular/core';

import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { SyntheseContentDownloadComponent } from "./download/synthese-content-download.component";

// Todo: à renommer
@Component({
  standalone: true,
  selector: 'pnx-synthese-content',
  templateUrl: 'synthese-content.component.html',
  styleUrls: ['synthese-content.component.scss'],
  imports: [GN2CommonModule, SyntheseContentDownloadComponent],
})
export class SyntheseContentComponent implements OnInit {

  constructor() {
  }

  ngOnInit() {
  }
}
