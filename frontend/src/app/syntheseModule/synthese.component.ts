import { Component, OnInit } from '@angular/core';
import { ModuleLayoutComponent } from './components/moduleLayout/module-layout.component';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { TaxonAdvancedStoreService } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-store.service';
@Component({
  standalone: true,
  selector: 'pnx-synthese',
  styleUrls: ['synthese.component.scss'],
  templateUrl: 'synthese.component.html',
  imports: [GN2CommonModule, ModuleLayoutComponent],
  providers: [SyntheseFormService, TaxonAdvancedStoreService],
})
export class SyntheseComponent implements OnInit {

  constructor() {}

  ngOnInit() {}

  onSearchEvent() {
    console.log('trigger search event');
  }
}
