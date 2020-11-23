import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  MatCardModule,
  MatMenuModule,
  MatSidenavModule,
  MatTooltipModule,
  MatListModule,
  MatIconModule,
  MatToolbarModule,
  MatExpansionModule,
  MatPaginatorModule,
  MatStepperModule,
  MatProgressSpinnerModule,
  MatButtonModule,
  MatDialogModule,
  MatBadgeModule,
  MatProgressBarModule,
  MatSlideToggleModule,
  MatFormFieldModule,
  MatAutocompleteModule,
  MatSelectModule,
  MatInputModule,
  MatChipsModule,
  MatTabsModule
} from '@angular/material';
import { RouterModule } from '@angular/router';

import { NgxMatSelectSearchModule } from 'ngx-mat-select-search';

import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { AutoCompleteModule } from 'primeng/primeng';
import { TreeModule } from 'angular-tree-component';

// Components
import { NomenclatureComponent } from './form/nomenclature/nomenclature.component';
import { ObserversComponent } from './form/observers/observers.component';
import { DateComponent } from './form/date/date.component';
import { TaxonomyComponent } from './form/taxonomy/taxonomy.component';
import { AreasIntersectedComponent } from './form/areas-intersected/areas-intersected-modal.component';
import { BreadcrumbsComponent } from '@geonature_common/others/breadcrumbs/breadcrumbs.component'
import { DatasetsComponent } from './form/datasets/datasets.component';
import { DynamicFormComponent } from './form/dynamic-form/dynamic-form.component';
import { DynamicFormService } from '@geonature_common/form/dynamic-form-generator/dynamic-form.service';
import { GeometryFormComponent } from '@geonature_common/form/geometry-form/geometry-form.component';

import { MapComponent } from './map/map.component';
import { MarkerComponent } from './map/marker/marker.component';
import { LeafletDrawComponent } from './map/leaflet-draw/leaflet-draw.component';
import { MapOverLaysComponent } from './map/overlays/overlays.component';

import { GPSComponent } from './map/gps/gps.component';
import { GeojsonComponent } from './map/geojson/geojson.component';
import { LeafletFileLayerComponent } from './map/filelayer/filelayer.component';
import { MapListComponent } from './map-list/map-list.component';
import { MapDataComponent } from './map-list/map-data/map-data.component';
import { MapListGenericFiltersComponent } from './map-list/generic-filters/generic-filters.component';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';
import { ObserversTextComponent } from '@geonature_common/form/observers-text/observers-text.component';
import { MunicipalitiesComponent } from '@geonature_common/form/municipalities/municipalities.component';
import { GenericFormGeneratorComponent } from '@geonature_common/form/dynamic-form-generator/dynamic-form-generator.component';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { AreasComponent } from '@geonature_common/form/areas/areas.component';
import { AcquisitionFrameworksComponent } from '@geonature_common/form/acquisition-frameworks/acquisition-frameworks.component';
import { ModalDownloadComponent } from '@geonature_common/others/modal-download/modal-download.component';
import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { PeriodComponent } from '@geonature_common/form/date/period.component';
import { AutoCompleteComponent } from '@geonature_common/form/autocomplete/autocomplete.component';
import { SyntheseSearchComponent } from '@geonature_common/form/synthese-form/synthese-form.component';
import { TaxonAdvancedModalComponent } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-component';
import { DumbSelectComponent } from '@geonature_common/form/dumb-select/dumb-select.component';
import { DisplayMediasComponent } from '@geonature_common/form/media/display-medias.component';
import { MediaComponent } from '@geonature_common/form/media/media.component';
import { MediaDialog } from '@geonature_common/form/media/media-dialog.component';
import { MediasComponent } from '@geonature_common/form/media/medias.component';
import { MediasTestComponent } from '@geonature_common/form/media/medias-test.component';
import { DatalistComponent } from '@geonature_common/form/datalist/datalist.component';
import { PlacesComponent } from './map/places/places.component';
import { PlacesListComponent } from './map/placesList/placesList.component';
import { TaxaComponent } from '@geonature_common/form/taxa/taxa.component';

// directive
import { DisableControlDirective } from './form/disable-control.directive';
import { DisplayMouseOverDirective } from './directive/display-mouse-over.directive';

// pipe
import { ReadablePropertiePipe } from './pipe/readable-propertie.pipe';
import { SafeHtmlPipe } from './pipe/sanitizer.pipe';

// Service
import { MapService } from './map/map.service';
import { DataFormService } from './form/data-form.service';
import { MapListService } from './map-list/map-list.service';
import { CommonService } from './service/common.service';
import { FormService } from './form/form.service';
import { NgbDatePeriodParserFormatter } from '@geonature_common/form/date/ngb-date-custom-parser-formatter';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { MediaService } from '@geonature_common/service/media.service';

// add all rxjs operators
import 'rxjs/Rx';
import { MultiSelectComponent } from './form/multiselect/multiselect.component';

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
    MatExpansionModule,
    MatPaginatorModule,
    MatStepperModule,
    MatProgressSpinnerModule,
    MatButtonModule,
    MatDialogModule,
    MatBadgeModule,
    MatProgressBarModule,
    MatSlideToggleModule,
    MatFormFieldModule,
    MatAutocompleteModule,
    MatSelectModule,
    MatInputModule,
    MatChipsModule,
    NgxMatSelectSearchModule,
    FormsModule,
    ReactiveFormsModule,
    NgxDatatableModule,
    RouterModule,
    TranslateModule.forChild(),
    NgbModule.forRoot(),
    AutoCompleteModule,
    TreeModule,
    MatTabsModule
  ],
  declarations: [
    NomenclatureComponent,
    ObserversComponent,
    BreadcrumbsComponent,
    DateComponent,
    TaxonomyComponent,
    AreasIntersectedComponent,
    MapComponent,
    MarkerComponent,
    GeojsonComponent,
    LeafletDrawComponent,
    LeafletFileLayerComponent,
    GPSComponent,
    MapOverLaysComponent,
    MapListComponent,
    MapDataComponent,
    DisableControlDirective,
    DisplayMouseOverDirective,
    ReadablePropertiePipe,
    SafeHtmlPipe,
    DatasetsComponent,
    MapListGenericFiltersComponent,
    ObserversTextComponent,
    DynamicFormComponent,
    MunicipalitiesComponent,
    MultiSelectComponent,
    GenericFormGeneratorComponent,
    GenericFormComponent,
    AreasComponent,
    AcquisitionFrameworksComponent,
    ModalDownloadComponent,
    PeriodComponent,
    AutoCompleteComponent,
    SyntheseSearchComponent,
    TaxonAdvancedModalComponent,
    DumbSelectComponent,
    GeometryFormComponent,
    DisplayMediasComponent,
    MediaComponent,
    MediaDialog,
    MediasComponent,
    MediasTestComponent,
    ConfirmationDialog,
    DatalistComponent,
    PlacesComponent,
    PlacesListComponent,
    TaxaComponent,
  ],
  providers: [
    TranslateService,
    MapService,
    DataFormService,
    MapListService,
    CommonService,
    FormService,
    DynamicFormService,
    NgbDatePeriodParserFormatter,
    SyntheseDataService,
    CruvedStoreService,
    MediaService
  ],
  entryComponents: [TaxonAdvancedModalComponent, ConfirmationDialog, MediaDialog],
  exports: [
    MunicipalitiesComponent,
    BreadcrumbsComponent,
    DynamicFormComponent,
    NomenclatureComponent,
    ObserversComponent,
    DateComponent,
    TaxonomyComponent,
    AreasIntersectedComponent,
    MapComponent,
    MarkerComponent,
    LeafletDrawComponent,
    LeafletFileLayerComponent,
    GeojsonComponent,
    GPSComponent,
    MapOverLaysComponent,
    MapListComponent,
    MapDataComponent,
    DisableControlDirective,
    DisplayMouseOverDirective,
    ReadablePropertiePipe,
    SafeHtmlPipe,
    DatasetsComponent,
    ModalDownloadComponent,
    FormsModule,
    ReactiveFormsModule,
    MatIconModule,
    MatTooltipModule,
    MatSidenavModule,
    MatMenuModule,
    MatCardModule,
    MatListModule,
    MatToolbarModule,
    MatExpansionModule,
    MatPaginatorModule,
    NgxDatatableModule,
    MatStepperModule,
    MatProgressSpinnerModule,
    MatButtonModule,
    MatDialogModule,
    MatBadgeModule,
    MatProgressBarModule,
    MatSlideToggleModule,
    MatFormFieldModule,
    MatAutocompleteModule,
    MatSelectModule,
    MatInputModule,
    MatChipsModule,
    NgxMatSelectSearchModule,
    NgbModule,
    TranslateModule,
    MapListGenericFiltersComponent,
    ObserversTextComponent,
    MultiSelectComponent,
    GenericFormGeneratorComponent,
    GenericFormComponent,
    AreasComponent,
    AcquisitionFrameworksComponent,
    PeriodComponent,
    AutoCompleteComponent,
    SyntheseSearchComponent,
    TaxonAdvancedModalComponent,
    DumbSelectComponent,
    GeometryFormComponent,
    ConfirmationDialog,
    MediasComponent,
    MediaDialog,
    DisplayMediasComponent,
    DatalistComponent,
    PlacesComponent,
    PlacesListComponent,
    MatTabsModule,
    TaxaComponent
  ]
})
export class GN2CommonModule {}
