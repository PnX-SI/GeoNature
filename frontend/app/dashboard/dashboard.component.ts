import { Component, OnInit } from "@angular/core";
import { Title } from "@angular/platform-browser";
// Services
import { DataService } from "./services/data.services";

@Component({
  selector: "dashboard",
  templateUrl: "dashboard.component.html",
  styleUrls: ['./dashboard.component.scss']
})

export class DashboardComponent implements OnInit {

  public regnes = [];
  public phylum = [];
  public classes = [];
  public ordres = [];
  public familles = [];
  public group1INPN = [];
  public group2INPN = [];
  public taxonomies: { [taxLevel: string]: any } = { };
  public years: any;
  public taxLevel: { [taxLevel: string]: any } = { };

  constructor(title: Title, public dataService: DataService) {
    title.setTitle("GeoNature - Dashboard")
  }

  ngOnInit() {
    // Accès aux noms des différents règnes de la BDD GeoNature
    this.taxLevel["taxLevel"] = "Règne";
    this.dataService.getTaxonomie(this.taxLevel).subscribe(
      (data) => {
        data.forEach(
          (elt) => {
            this.regnes.push(elt[0]);
          }
        );
      }
    );
    this.taxonomies["Règne"] = this.regnes;
    // Accès aux noms des différents phylum de la BDD GeoNature
    this.taxLevel["taxLevel"] = "Phylum";
    this.dataService.getTaxonomie(this.taxLevel).subscribe(
      (data) => {
        data.forEach(
          (elt) => {
            this.phylum.push(elt[0]);
          }
        );
      }
    );
    this.taxonomies["Phylum"] = this.phylum;
    // Accès aux noms des différentes classes de la BDD GeoNature
    this.taxLevel["taxLevel"] = "Classe";
    this.dataService.getTaxonomie(this.taxLevel).subscribe(
      (data) => {
        data.forEach(
          (elt) => {
            this.classes.push(elt[0]);
          }
        );
      }
    );
    this.taxonomies["Classe"] = this.classes;
    // Accès aux noms des différents ordres de la BDD GeoNature
    this.taxLevel["taxLevel"] = "Ordre";
    this.dataService.getTaxonomie(this.taxLevel).subscribe(
      (data) => {
        data.forEach(
          (elt) => {
            this.ordres.push(elt[0]);
          }
        );
      }
    );
    this.taxonomies["Ordre"] = this.ordres;
    // Accès aux noms des différentes familles de la BDD GeoNature
    this.taxLevel["taxLevel"] = "Famille";
    this.dataService.getTaxonomie(this.taxLevel).subscribe(
      (data) => {
        data.forEach(
          (elt) => {
            this.familles.push(elt[0]);
          }
        );
      }
    );
    this.taxonomies["Famille"] = this.familles;
    // Accès aux noms des différents groupes INPN de la BDD GeoNature
    this.taxLevel["taxLevel"] = "Groupe INPN 1";
    this.dataService.getTaxonomie(this.taxLevel).subscribe(
      (data) => {
        data.forEach(
          (elt) => {
            this.group1INPN.push(elt[0]);
          }
        );
      }
    );
    this.taxonomies["Groupe INPN 1"] = this.group1INPN;
    this.taxLevel["taxLevel"] = "Groupe INPN 2";
    this.dataService.getTaxonomie(this.taxLevel).subscribe(
      (data) => {
        data.forEach(
          (elt) => {
            this.group2INPN.push(elt[0]);
          }
        );
      }
    );
    this.taxonomies["Groupe INPN 2"] = this.group2INPN;
    // Accès aux années extrêmes de la BDD
    this.dataService.getYears().subscribe(
      (data) => {
        this.years = data[0];
      }
    );
    // console.log(this.taxonomies);
  }

}
