import { Component, OnInit } from '@angular/core';
import { ModuleLayoutComponent } from './components/moduleLayout/module-layout.component';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { TaxonAdvancedStoreService } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-store.service';
import { SyntheseCarteComponent } from './carte/synthese-carte.component';
import { SyntheseContentComponent } from './content/synthese-content.component';
import { SyntheseApiProxyService } from './services/synthese-api-proxy.service';
@Component({
  standalone: true,
  selector: 'pnx-synthese',
  styleUrls: ['synthese.component.scss'],
  templateUrl: 'synthese.component.html',
  imports: [
    GN2CommonModule,
    ModuleLayoutComponent,
    SyntheseCarteComponent,
    SyntheseContentComponent,
  ],
  providers: [SyntheseApiProxyService, TaxonAdvancedStoreService],
})
export class SyntheseComponent implements OnInit {
  constructor(private _apiProxyService: SyntheseApiProxyService) {}

  ngOnInit() {}

  onSearchEvent(event) {
    this._apiProxyService.filters = event;
    this._apiProxyService.fetchObservationsList();
  }
}
