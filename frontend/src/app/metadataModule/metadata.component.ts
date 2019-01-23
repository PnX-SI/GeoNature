import { Component, OnInit, ViewChild } from '@angular/core';
import { CruvedStoreService } from '../services/cruved-store.service';

@Component({
  selector: 'pnx-metadata',
  templateUrl: './metadata.component.html'
})
export class MetadataComponent implements OnInit {
  constructor(_cruvedStore: CruvedStoreService) {}

  ngOnInit() {}
}
