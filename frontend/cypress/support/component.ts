import { CommonModule } from '@angular/common';
import { Type } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { MatAutocompleteModule } from '@angular/material/autocomplete';
import { MatBadgeModule } from '@angular/material/badge';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips';
import { MatDialogModule } from '@angular/material/dialog';
import { MatExpansionModule } from '@angular/material/expansion';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule, MatIconRegistry } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatListModule } from '@angular/material/list';
import { MatMenuModule } from '@angular/material/menu';
import { MatPaginatorModule } from '@angular/material/paginator';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';
import { MatSidenavModule } from '@angular/material/sidenav';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatStepperModule } from '@angular/material/stepper';
import { MatTabsModule } from '@angular/material/tabs';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatTooltipModule } from '@angular/material/tooltip';
import { RouterModule } from '@angular/router';
import { TreeModule } from '@circlon/angular-tree-component';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { NgSelectModule } from '@ng-select/ng-select';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';
import { mount, MountConfig } from 'cypress/angular';
import { NgxMatSelectSearchModule } from 'ngx-mat-select-search';

import { HttpClientModule } from '@angular/common/http';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { ConfigService } from '@geonature/services/config.service';
import { DisplayMouseOverDirective } from '@geonature_common/directive/display-mouse-over.directive';
import { AcquisitionFrameworksComponent } from '@geonature_common/form/acquisition-frameworks/acquisition-frameworks.component';
import { AreasIntersectedComponent } from '@geonature_common/form/areas-intersected/areas-intersected-modal.component';
import { AreasComponent } from '@geonature_common/form/areas/areas.component';
import { AutoCompleteComponent } from '@geonature_common/form/autocomplete/autocomplete.component';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { DatalistComponent } from '@geonature_common/form/datalist/datalist.component';
import { DatasetsComponent } from '@geonature_common/form/datasets/datasets.component';
import { DateComponent } from '@geonature_common/form/date/date.component';
import { NgbDatePeriodParserFormatter } from '@geonature_common/form/date/ngb-date-custom-parser-formatter';
import { PeriodComponent } from '@geonature_common/form/date/period.component';
import { DisableControlDirective } from '@geonature_common/form/disable-control.directive';
import { DumbSelectComponent } from '@geonature_common/form/dumb-select/dumb-select.component';
import { GenericFormGeneratorComponent } from '@geonature_common/form/dynamic-form-generator/dynamic-form-generator.component';
import { DynamicFormService } from '@geonature_common/form/dynamic-form-generator/dynamic-form.service';
import { DynamicFormComponent } from '@geonature_common/form/dynamic-form/dynamic-form.component';
import { FormService } from '@geonature_common/form/form.service';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { GeometryFormComponent } from '@geonature_common/form/geometry-form/geometry-form.component';
import { DisplayMediasComponent } from '@geonature_common/form/media/display-medias.component';
import { MediaDialog } from '@geonature_common/form/media/media-dialog.component';
import { MediaComponent } from '@geonature_common/form/media/media.component';
import { MediasTestComponent } from '@geonature_common/form/media/medias-test.component';
import { MediasComponent } from '@geonature_common/form/media/medias.component';
import { MultiSelectComponent } from '@geonature_common/form/multiselect/multiselect.component';
import { MunicipalitiesComponent } from '@geonature_common/form/municipalities/municipalities.component';
import { NomenclatureComponent } from '@geonature_common/form/nomenclature/nomenclature.component';
import { ObserversTextComponent } from '@geonature_common/form/observers-text/observers-text.component';
import { ObserversComponent } from '@geonature_common/form/observers/observers.component';
import { TaxonAdvancedModalComponent } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-component';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { TaxaComponent } from '@geonature_common/form/taxa/taxa.component';
import { TaxonTreeComponent } from '@geonature_common/form/taxon-tree/taxon-tree.component';
import { TaxonomyComponent } from '@geonature_common/form/taxonomy/taxonomy.component';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { GPSComponent } from '@geonature_common/map/gps/gps.component';
import { LeafletDrawComponent } from '@geonature_common/map/leaflet-draw/leaflet-draw.component';
import { MapService } from '@geonature_common/map/map.service';
import { MarkerComponent } from '@geonature_common/map/marker/marker.component';
import { MapOverLaysComponent } from '@geonature_common/map/overlays/overlays.component';
import { PlacesComponent } from '@geonature_common/map/places/places.component';
import { PlacesListComponent } from '@geonature_common/map/placesList/placesList.component';
import { BreadcrumbsComponent } from '@geonature_common/others/breadcrumbs/breadcrumbs.component';
import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { ModalDownloadComponent } from '@geonature_common/others/modal-download/modal-download.component';
import { ReadablePropertiePipe } from '@geonature_common/pipe/readable-propertie.pipe';
import { SafeHtmlPipe } from '@geonature_common/pipe/sanitizer.pipe';
import { SafeStripHtmlPipe, StripHtmlPipe } from '@geonature_common/pipe/strip-html.pipe';
import { CommonService } from '@geonature_common/service/common.service';
import { MediaService } from '@geonature_common/service/media.service';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { NgChartsModule } from 'ng2-charts';
import { ToastrModule } from 'ngx-toastr';
declare global {
  namespace Cypress {
    interface Chainable {
      mount: typeof customMount
    }
  }
}


// Source : https://docs.cypress.io/guides/component-testing/angular/examples#Default-Declarations-Providers-or-Imports

const declarations = [
  AcquisitionFrameworksComponent,
  AreasComponent,
  NomenclatureComponent,
  ObserversComponent,
  BreadcrumbsComponent,
  DateComponent,
  TaxonomyComponent,
  AreasIntersectedComponent,
  AutoCompleteComponent,
  ConfirmationDialog,
  DatalistComponent,
  DatasetsComponent,
  DateComponent,
  DisableControlDirective,
  DisplayMediasComponent,
  DisplayMouseOverDirective,
  DumbSelectComponent,
  DynamicFormComponent,
  GenericFormComponent,
  GenericFormGeneratorComponent,
  // GeojsonComponent,
  GeometryFormComponent,
  GPSComponent,
  LeafletDrawComponent,
  // LeafletFileLayerComponent,
  // MapComponent,
  // MapDataComponent,
  // MapListComponent,
  // MapListGenericFiltersComponent,
  MapOverLaysComponent,
  MarkerComponent,
  MediaComponent,
  MediaDialog,
  MediasComponent,
  MediasTestComponent,
  ModalDownloadComponent,
  MultiSelectComponent,
  MunicipalitiesComponent,
  NomenclatureComponent,
  ObserversComponent,
  ObserversTextComponent,
  PeriodComponent,
  PlacesComponent,
  PlacesListComponent,
  ReadablePropertiePipe,
  SafeHtmlPipe,
  // SyntheseSearchComponent,
  SafeStripHtmlPipe,
  StripHtmlPipe,
  TaxaComponent,
  TaxonAdvancedModalComponent,
  TaxonomyComponent,
  TaxonTreeComponent,
]
const imports = [
  CommonModule,
  FormsModule,
  MatAutocompleteModule,
  MatBadgeModule,
  MatButtonModule,
  MatCardModule,
  MatChipsModule,
  MatDialogModule,
  MatExpansionModule,
  MatFormFieldModule,
  MatIconModule,
  MatInputModule,
  MatListModule,
  MatMenuModule,
  MatPaginatorModule,
  MatProgressBarModule,
  MatProgressSpinnerModule,
  MatSelectModule,
  MatSidenavModule,
  MatSlideToggleModule,
  MatStepperModule,
  MatTabsModule,
  MatToolbarModule,
  MatTooltipModule,
  NgbModule,
  NgxDatatableModule,
  NgxMatSelectSearchModule,
  ReactiveFormsModule,
  NgxDatatableModule,
  NgSelectModule,
  RouterModule,
  TranslateModule.forChild(),
  TreeModule,
  BrowserModule,
  HttpClientModule,
  BrowserAnimationsModule,
  NgChartsModule,
  ToastrModule.forRoot({
    positionClass: 'toast-top-center',
    tapToDismiss: true,
    timeOut: 3000,
  }),]

const providers = [
  CommonService,
  DataFormService,
  DynamicFormService,
  ConfigService,
  FormService,
  MapListService,
  MapService,
  MatIconRegistry,
  MediaService,
  NgbDatePeriodParserFormatter,
  SyntheseDataService,
  TranslateService
]

/**
 * Mounts a component with the given configuration including default declarations, imports and providers
 *
 * @param {string | Type<T>} component - The component to mount
 * @param {MountConfig<T>} config - The configuration for mounting the component
 * @return {T} The mounted component
 */
function customMount<T>(component: string | Type<T>, config?: MountConfig<T>) {
  console.log(providers)
  if (!config) {
    config = { declarations, imports, providers }
  } else {

    config.declarations = [...(config?.declarations || []), ...declarations]
    config.imports = [...(config?.imports || []), ...imports]
    config.providers = [...(config?.providers || []), ...providers]
  }
  return mount<T>(component, config)
}

Cypress.Commands.add('mount', customMount)
