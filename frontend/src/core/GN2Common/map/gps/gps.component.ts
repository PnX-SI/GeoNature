import { Component, OnInit, ViewChild } from '@angular/core';
import { MarkerComponent } from '../marker/marker.component';
import { MapService } from '../map.service';
import {NgbModal, NgbActiveModal} from '@ng-bootstrap/ng-bootstrap';
import { CommonService } from '../../service/common.service';
import * as L from 'leaflet';

@Component({
  selector: 'pnx-gps',
  templateUrl: 'gps.component.html'
})

export class GPSComponent extends MarkerComponent implements OnInit  {
  @ViewChild('modalContent') public modalContent: any;
  constructor(public mapService: MapService, public modalService: NgbModal, public commonService: CommonService) {
    super(mapService, commonService );
  }

  ngOnInit() {
    this.map = this.mapservice.map;
    this.enableGps();
  }
  enableGps() {
    const GPSLegend = this.mapService.addCustomLegend('topleft', 'GPSLegend');
    this.map.addControl(new GPSLegend());
    const gpsElement: HTMLElement = document.getElementById('GPSLegend');
    L.DomEvent.disableClickPropagation(gpsElement);
    gpsElement.innerHTML = '<span> <b> GPS </span> <b>';
    gpsElement.style.paddingLeft = '3px';
    gpsElement.onclick = () => {
      this.modalService.open(this.modalContent);
    };
  }

  setMarkerFromGps(x, y) {
    super.generateMarkerAndEvent(x,y);
  }
}