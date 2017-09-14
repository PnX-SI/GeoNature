import { Component, OnInit, ViewChild } from '@angular/core';
import { MarkerComponent } from '../marker/marker.component';
import { MapService } from '../map.service';
import { MapUtils } from '../map.utils';
import {NgbModal, NgbActiveModal} from '@ng-bootstrap/ng-bootstrap';

@Component({
  selector: 'pnx-gps',
  templateUrl: 'gps.component.html'
})

export class GPSComponent extends MarkerComponent implements OnInit  {
  @ViewChild('modalContent') public modalContent: any;
  constructor(public mapService: MapService, private maputils: MapUtils, public modalService: NgbModal) { 
    super(mapService, maputils);
  }

  ngOnInit() { 
    this.map = this.mapservice.map;
    this.enableGps();
  }
  enableGps() {
    const GPSLegend = this.maputils.addCustomLegend('topleft', 'GPSLegend');
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
    super.generateMarker(x,y);
  }
}