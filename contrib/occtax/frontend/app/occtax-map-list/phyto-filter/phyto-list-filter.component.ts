import { Component } from '@angular/core';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { OcctaxMapListService } from '../occtax-map-list.service';
import { ModuleService } from '@geonature/services/module.service';
import { OcctaxConfigService } from '../../services/occtax-config.service';
import { OcctaxMapListFilterComponent } from '../filter/occtax-map-list-filter.component';

@Component({
  selector: 'pnx-phyto-list-filter',
  templateUrl: 'phyto-list-filter.component.html',
  styleUrls: ['../filter/occtax-map-list-filter.component.scss'],
})
export class PhytoListFilterComponent extends OcctaxMapListFilterComponent {

  constructor(
    mapListService: MapListService,
    _dateParser: NgbDateParserFormatter,
    occtaxMapListService: OcctaxMapListService,
    moduleService: ModuleService,
    occtaxConfig: OcctaxConfigService
  ) {
    super(
      mapListService,
      _dateParser,
      occtaxMapListService,
      moduleService,
      occtaxConfig
    )
  }

}
