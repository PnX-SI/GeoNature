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
import { TaxonomyComponent } from './form/taxonomy/taxonomy.component';
import { CountingComponent } from './form/counting/counting.component';
import { ObservationComponent } from './form/observation/observation.component';
import { MapComponent } from './map/map.component';
import { MarkerComponent } from './map/marker/marker.component'
import { LeafletDrawComponent } from './map/leaflet-draw/leaflet-draw.component'

import { GPSComponent } from './map/gps/gps.component';
import { GeojsonComponent } from './map/geojson/geojson.component';
import { MapListComponent } from './map-list/map-list.component';
import { MapDataComponent } from './map-list/map-data/map-data.component';
import { OccurrenceComponent } from './form/occurrence/occurrence.component'
import { TranslateModule, TranslateLoader} from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';

// Service
import { MapService } from './map/map.service';
import { DataFormService } from './form/data-form.service';
import { FormService } from './form/form.service';

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
    TaxonomyComponent,
    MapComponent,
    MarkerComponent,
    GeojsonComponent,
    LeafletDrawComponent,
    GPSComponent,
    MapListComponent,
    MapDataComponent,
    OccurrenceComponent,
    CountingComponent,
    ObservationComponent

  ],
  providers : [
    MapService,
    DataFormService,
    FormService
    ],
  exports: [
    NomenclatureComponent,
    ObserversComponent,
    TaxonomyComponent,
    MapComponent,
    MarkerComponent,
    LeafletDrawComponent,
    GeojsonComponent,
    GPSComponent,
    MapListComponent,
    MapDataComponent,
    OccurrenceComponent,
    CountingComponent,
    ObservationComponent,
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
