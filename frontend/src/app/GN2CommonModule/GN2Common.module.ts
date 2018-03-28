import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  MatCardModule,
  MatMenuModule,
  MatSidenavModule,
  MatTooltipModule,
  MatListModule,
  MatIconModule,
  MatToolbarModule
} from '@angular/material';

import { Http } from '@angular/http';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import {
  HttpClientModule,
  HttpClient,
  HttpClientXsrfModule,
  HTTP_INTERCEPTORS
} from '@angular/common/http';

import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { AutoCompleteModule } from 'primeng/primeng';

// Components
import { NomenclatureComponent } from './form/nomenclature/nomenclature.component';
import { ObserversComponent } from './form/observers/observers.component';
import { DateComponent } from './form/date/date.component';
import { TaxonomyComponent } from './form/taxonomy/taxonomy.component';
import { AreasIntersectedComponent } from './form/areas-intersected/areas-intersected-modal.component';
import { DatasetsComponent } from './form/datasets/datasets.component';
import { DynamicFormComponent } from './form/dynamic-form/dynamic-form.component';
import { DynamicFormService } from './form/dynamic-form/dynamic-form.service';

import { MapComponent } from './map/map.component';
import { MarkerComponent } from './map/marker/marker.component';
import { LeafletDrawComponent } from './map/leaflet-draw/leaflet-draw.component';

import { GPSComponent } from './map/gps/gps.component';
import { GeojsonComponent } from './map/geojson/geojson.component';
import { MapListComponent } from './map-list/map-list.component';
import { MapDataComponent } from './map-list/map-data/map-data.component';
import { MapListGenericFiltersComponent } from './map-list/generic-filters/generic-filters.component';
import { TranslateModule, TranslateLoader, TranslateService } from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';
import { ObserversTextComponent } from '@geonature_common/form/observers-text/observers-text.component';
// directive
import { DisableControlDirective } from './form/disable-control.directive';
// pipe

import { ReadablePropertiePipe } from './pipe/readable-propertie.pipe';

// Service
import { MapService } from './map/map.service';
import { DataFormService } from './form/data-form.service';
import { MapListService } from './map-list/map-list.service';
import { CommonService } from './service/common.service';
import { FormService } from './form/form.service';

// add all rxjs operators
import 'rxjs/Rx';

export function HttpLoaderFactory(http: Http) {
  return new TranslateHttpLoader(http, './assets/i18n/', '.json');
}

@NgModule({
  imports: [
    CommonModule,
    MatIconModule,
    MatTooltipModule,
    MatSidenavModule,
    MatMenuModule,
    MatCardModule,
    MatListModule,
    MatToolbarModule,
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
    DatasetsComponent,
    MapListGenericFiltersComponent,
    ObserversTextComponent,
    DynamicFormComponent
  ],
  providers: [
    TranslateService,
    MapService,
    DataFormService,
    MapListService,
    CommonService,
    FormService,
    DynamicFormService
  ],
  exports: [
    DynamicFormComponent,
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
    MatTooltipModule,
    MatSidenavModule,
    MatMenuModule,
    MatCardModule,
    MatListModule,
    MatToolbarModule,
    NgxDatatableModule,
    NgbModule,
    TranslateModule,
    MapListGenericFiltersComponent,
    ObserversTextComponent
  ]
})
export class GN2CommonModule {}
