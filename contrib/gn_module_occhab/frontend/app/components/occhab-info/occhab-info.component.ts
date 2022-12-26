import { Component, OnInit, OnDestroy } from '@angular/core';
import { OccHabDataService } from '../../services/data.service';
import { Subscription } from 'rxjs/Subscription';
import { ActivatedRoute } from '@angular/router';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CommonService } from '@geonature_common/service/common.service';

import { StationFeature } from '../../models';

@Component({
  selector: 'pnx-occhab-info',
  templateUrl: './occhab-info.component.html',
  styleUrls: ['./occhab-info.component.scss', '../responsive-map.scss'],
})
export class OcchabInfoComponent implements OnInit, OnDestroy {
  public station: StationFeature;
  public currentHab;
  public habInfo: Array<any>;
  public modalContent;
  public selectedIndex;

  constructor(
    private _occHabDataService: OccHabDataService,
    private _route: ActivatedRoute,
    private _dataService: DataFormService,
    private modal: NgbModal,
    private _ngbModal: NgbModal,
    private _commonService: CommonService
  ) {}

  ngOnInit() {
    this._route.data.subscribe(({ station }) => {
      this.station = station;
    });
  }

  setCurrentHab(index) {
    this.currentHab = this.station.properties.habitats[index];
    this.selectedIndex = index;
  }

  getHabInfo(cd_hab) {
    this._dataService.getHabitatInfo(cd_hab).subscribe(
      (data) => {
        this.habInfo = data;
      },
      () => {
        this.habInfo = null;
      }
    );
  }

  openModalContent(modal, content) {
    this.modal.open(modal);
    this.modalContent = content;
  }

  openModal(modal) {
    this.modal.open(modal, { size: 'lg' });
  }

  openDeleteModal(modalDelete) {
    this._ngbModal.open(modalDelete);
  }

  ngOnDestroy() {}
}
