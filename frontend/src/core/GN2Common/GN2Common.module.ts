import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MaterialModule, MdIconModule, MdNativeDateModule } from '@angular/material';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { HttpModule, Http } from '@angular/http';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { AutoCompleteModule } from 'primeng/primeng';

// Components
import { NomenclatureComponent } from './form/nomenclature/nomenclature.component';
import { ObserversComponent } from './form/observers/observers.component';
import { DateComponent } from './form/date/date.component';
import { TaxonomyComponent } from './form/taxonomy/taxonomy.component';

import { MapComponent } from './map/map.component';
import { MarkerComponent } from './map/marker/marker.component'
import { LeafletDrawComponent } from './map/leaflet-draw/leaflet-draw.component'

import { GPSComponent } from './map/gps/gps.component';
import { GeojsonComponent } from './map/geojson/geojson.component';
import { MapListComponent } from './map-list/map-list.component';
import { MapDataComponent } from './map-list/map-data/map-data.component';
import { TranslateModule, TranslateLoader} from '@ngx-translate/core';
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
    MaterialModule,
    MdIconModule,
    MdNativeDateModule,
    FormsModule,
    ReactiveFormsModule,
    NgxDatatableModule,
    TranslateModule.forRoot({
      loader: {
          provide: TranslateLoader,
          useFactory: HttpLoaderFactory,
          deps: [Http]
      }
  }),
  NgbModule.forRoot(),
  AutoCompleteModule
  ],
  declarations: [
    NomenclatureComponent,
    ObserversComponent,
    DateComponent,
    TaxonomyComponent,
    MapComponent,
    MarkerComponent,
    GeojsonComponent,
    LeafletDrawComponent,
    GPSComponent,
    MapListComponent,
    MapDataComponent,
    DisableControlDirective,
    ReadablePropertiePipe
  ],
  providers : [
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
    MapComponent,
    MarkerComponent,
    LeafletDrawComponent,
    GeojsonComponent,
    GPSComponent,
    MapListComponent,
    MapDataComponent,
    DisableControlDirective,
    ReadablePropertiePipe,
    FormsModule,
    ReactiveFormsModule,
    MaterialModule,
    MdIconModule,
    MdNativeDateModule,
    NgxDatatableModule,
    TranslateModule,
    NgbModule
  ]
})
export class GN2CommonModule {
}
