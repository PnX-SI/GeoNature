import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
// import { MdIconModule } from '@angular/material/icon';
import { MatIconModule } from '@angular/material/icon';

import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { HttpModule, Http } from '@angular/http';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { AutoCompleteModule } from 'primeng/primeng';

// Components
import { NomenclatureComponent } from './form/nomenclature/nomenclature.component';
import { ObserversComponent } from './form/observers/observers.component';
import { DateComponent } from './form/date/date.component';
import { TaxonomyComponent } from './form/taxonomy/taxonomy.component';
import { AreasIntersectedComponent } from './form/areas-intersected/areas-intersected-modal.component';
import { DatasetsComponent } from './form/datasets/datasets.component';

import { MapComponent } from './map/map.component';
import { MarkerComponent } from './map/marker/marker.component';
import { LeafletDrawComponent } from './map/leaflet-draw/leaflet-draw.component';

import { GPSComponent } from './map/gps/gps.component';
import { GeojsonComponent } from './map/geojson/geojson.component';
import { MapListComponent } from './map-list/map-list.component';
import { MapDataComponent } from './map-list/map-data/map-data.component';
import { TranslateModule, TranslateLoader, TranslateService } from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';
// directive
import { DisableControlDirective } from './form/disable-control.directive';
// pipe

import { ReadablePropertiePipe } from './pipe/readable-propertie.pipe';

// Service
import { MapService } from './map/map.service';
import { DataFormService } from './form/data-form.service';
import { MapListService } from './map-list/map-list.service';
import { CommonService } from './service/common.service';

export function HttpLoaderFactory(http: Http) {
  return new TranslateHttpLoader(http, './assets/i18n/', '.json');
}

@NgModule({
  imports: [
    CommonModule,
    MatIconModule,
    FormsModule,
    ReactiveFormsModule,
    NgxDatatableModule,
    TranslateModule.forChild(),
  NgbModule.forRoot(),
  AutoCompleteModule
  ],
  declarations: [
    NomenclatureComponent,
    ObserversComponent,
    DateComponent,
    TaxonomyComponent,
    AreasIntersectedComponent,
    MapComponent,
    MarkerComponent,
    GeojsonComponent,
    LeafletDrawComponent,
    GPSComponent,
    MapListComponent,
    MapDataComponent,
    DisableControlDirective,
    ReadablePropertiePipe,
    DatasetsComponent
  ],
  providers : [
    TranslateService,
    MapService,
    DataFormService,
    MapListService,
    CommonService
    ],
  exports: [
    NomenclatureComponent,
    ObserversComponent,
    DateComponent,
    TaxonomyComponent,
    AreasIntersectedComponent,
    MapComponent,
    MarkerComponent,
    LeafletDrawComponent,
    GeojsonComponent,
    GPSComponent,
    MapListComponent,
    MapDataComponent,
    DisableControlDirective,
    ReadablePropertiePipe,
    DatasetsComponent,
    FormsModule,
    ReactiveFormsModule,
    MatIconModule,
    NgxDatatableModule,
    NgbModule,
    TranslateModule
  ]
})
export class GN2CommonModule {

}
