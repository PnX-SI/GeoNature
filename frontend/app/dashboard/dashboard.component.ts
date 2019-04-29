import { Component, OnInit } from "@angular/core";
import { FormControl } from "@angular/forms";
// Services
import { DataService } from "./services/data.services";

@Component({
  selector: "dashboard",
  templateUrl: "dashboard.component.html",
})
export class DashboardComponent implements OnInit {
  public myCommunes: Array<any>;
  public taxonControl = new FormControl();
  constructor(public dataService: DataService) {}

  ngOnInit() {
    this.dataService.getCommunes().subscribe((data) =>{
      console.log(data);
      this.myCommunes=data;
    }
  }

  changeMap() {
    console.log('click');
    
    this.myCommunes = Object.assign({}, this.myCommunes);
    this.showData = this.onEachFeatureNbTax;
  }

  showData(feature, layer) {
    layer.bindPopup("<h4>"+feature.properties.area_name+"</h4><b>Nombre d'observations :</b> "+feature.properties.nb_obs);
    if (feature.properties.nb_obs <= 1000) {
      layer.setStyle({fillColor: "rgb(232, 229, 202)", fillOpacity: 0.9});
    }
    else if (feature.properties.nb_obs <= 2000) {
      layer.setStyle({fillColor: "rgb(236, 212, 123)", fillOpacity: 0.9});
    }
    else if (feature.properties.nb_obs <= 3000) {
      layer.setStyle({fillColor: "rgb(233, 164, 27)", fillOpacity: 0.9});
    }
    else if (feature.properties.nb_obs <= 4000) {
      layer.setStyle({fillColor: "rgb(221, 102, 8)", fillOpacity: 0.9});
    }
    else if (feature.properties.nb_obs <= 5000) {
      layer.setStyle({fillColor: "rgb(218, 11, 45)", fillOpacity: 0.9});
    }
    else if (feature.properties.nb_obs <= 10000) {
      layer.setStyle({fillColor: "rgb(107, 3, 41)", fillOpacity: 0.9});
    }
    else {
      layer.setStyle({fillColor: "rgb(48, 2, 18)", fillOpacity: 0.9});
    }
  };

  onEachFeatureNbTax(feature, layer) {
    layer.bindPopup("<h4>"+feature.properties.area_name+"</h4><b>Nombre d'observations :</b> "+feature.properties.nb_taxon);
    if (feature.properties.nb_taxon <= 1000) {
      layer.setStyle({fillColor: "rgb(232, 229, 202)", fillOpacity: 0.9});
    }
    else if (feature.properties.nb_taxon <= 2000) {
      layer.setStyle({fillColor: "rgb(236, 212, 123)", fillOpacity: 0.9});
    }
    else if (feature.properties.nb_taxon <= 3000) {
      layer.setStyle({fillColor: "rgb(233, 164, 27)", fillOpacity: 0.9});
    }
    else if (feature.properties.nb_taxon <= 4000) {
      layer.setStyle({fillColor: "rgb(221, 102, 8)", fillOpacity: 0.9});
    }
    else if (feature.properties.nb_taxon <= 5000) {
      layer.setStyle({fillColor: "rgb(218, 11, 45)", fillOpacity: 0.9});
    }
    else if (feature.properties.nb_taxon <= 10000) {
      layer.setStyle({fillColor: "rgb(107, 3, 41)", fillOpacity: 0.9});
    }
    else {
      layer.setStyle({fillColor: "rgb(48, 2, 18)", fillOpacity: 0.9});
    }
  };


}
