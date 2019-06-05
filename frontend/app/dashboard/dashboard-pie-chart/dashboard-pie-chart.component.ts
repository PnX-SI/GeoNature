import { Component, OnInit, ViewChild, Input } from "@angular/core";
import { FormBuilder, FormGroup } from "@angular/forms";
import { BaseChartDirective } from 'ng2-charts/ng2-charts';
// Services
import { DataService } from "../services/data.services";

@Component({
  selector: "dashboard-pie-chart",
  templateUrl: "dashboard-pie-chart.component.html",
  styleUrls: ['./dashboard-pie-chart.component.scss']
})

export class DashboardPieChartComponent implements OnInit {

  @ViewChild(BaseChartDirective) chart: BaseChartDirective;
  
  public myDataRegne: Array<any>;
  public pieChartLabels = [];
  public pieChartType = 'doughnut';
  public pieChartData = [];
  public pieChartColors = [
    { backgroundColor: ["rgba(231,127,29,0.8)", "rgba(96,171,0,0.7)", "rgba(14,145,211,0.7)", "rgba(186,0,0,0.7)", "rgba(109,38,211,0.7)", "rgba(231,195,49,0.9)", "rgba(19, 155, 116, 0.8)", "rgba(159, 5, 63, 0.8)", "rgba(12,54,164,0.8)", "rgba(230,114,197,0.8)", "rgba(117,62,0,0.8)", "rgba(3,101,0,0.8)", "rgba(94,92,89,0.8)", "rgba(200,51,0,0.8)"] } 
  ];
  public adjustedData: any;

  pieChartForm: FormGroup;
  // public formerSelectedFilter: any;
  @Input() taxonomies: any;
  @Input() years: any;
  public yearRange = [1980,2019];

  constructor(public dataService: DataService, public fb: FormBuilder) {
    // Déclaration du formulaire contenant les filtres du pie chart
    this.pieChartForm = fb.group({
      selectedYearRange: fb.control([1980,2019]),
      selectedFilter: fb.control(null)
    }); 
  }

  ngOnInit() {
    // Initialisation de l'array des labels, paramètre du pie chart
    this.pieChartLabels = this.taxonomies["Règne"];
    // this.pieChartLabels.push("Non défini");
    // console.log(this.pieChartLabels);
    // Accès aux données de synthèse la BDD GeoNature (par défaut, le pie chart s'affiche au niveau du règne)
    this.dataService.getDataRegne().subscribe(
      (data) => {
        // console.log(data);
        //Remplissage de l'array des données, paramètre du pie chart
        data.forEach(
          (elt) => {
            this.pieChartData.push(elt[1]);
          }
        );
        this.chart.chart.update();
      }
    );
  }

  ngOnChanges(change) {
    if(change.years && change.years.currentValue != undefined) {
      this.yearRange = change.years.currentValue;
    }    
  }

  // Rafraichissement des données en fonction des filtres renseignés par l'utilisateur
  refreshData() {
    console.log(this.pieChartForm.value);

    if (this.pieChartForm.value.selectedFilter == null || this.pieChartForm.value.selectedFilter == "Règne") {
      // Réinitialisation de l'array des labels, paramètre du pie chart
      this.pieChartLabels = this.taxonomies["Règne"];
      if (this.pieChartLabels[this.pieChartLabels.length-1] != "Non défini") {
        this.pieChartLabels.push("Non défini");
      }
      console.log(this.pieChartLabels);
      // Accès aux données de synthèse la BDD GeoNature (phylum)
      this.dataService.getDataRegne(this.pieChartForm.value).subscribe(
        (data) => {
          // console.log(data);
          this.adjustedData = data;
          // Modification des données pour un nom de taxon null
          const dataLength = this.adjustedData.length;
          if (this.adjustedData[dataLength-1][0] == null) {
            this.adjustedData[dataLength-1][0] = "Non défini";
          }
          console.log(this.adjustedData);
          // Réinitialisation de l'array des données, paramètre du pie chart
          this.pieChartData = [];
          console.log(this.pieChartData);
          // Remplissage de l'array des données, en tenant compte du fait qu'il ne peut y avoir aucune observation pour certains taxons
          var start = 0;
          this.pieChartLabels.forEach(
            (taxon) => {
              var i = start;
              var keepGoing = true;
              while ((i < dataLength) && (keepGoing == true)) {
                if (taxon == this.adjustedData[i][0]) {
                  this.pieChartData.push(this.adjustedData[i][1]);
                  keepGoing = false;
                  start = i+1;
                }
                i += 1;
              }
              if (keepGoing == true) {
                this.pieChartData.push(undefined);
              }
            }
          );
          this.chart.chart.update();
        }
      ); 
    }

    if (this.pieChartForm.value.selectedFilter == "Phylum") {
      // Réinitialisation de l'array des labels, paramètre du pie chart
      this.pieChartLabels = this.taxonomies["Phylum"];
      if (this.pieChartLabels[this.pieChartLabels.length-1] != "Non défini") {
        this.pieChartLabels.push("Non défini");
      }
      console.log(this.pieChartLabels);
      // Accès aux données de synthèse la BDD GeoNature (phylum)
      this.dataService.getDataPhylum(this.pieChartForm.value).subscribe(
        (data) => {
          // console.log(data);
          this.adjustedData = data;
          // Modification des données pour un nom de taxon null
          const dataLength = this.adjustedData.length;
          if (this.adjustedData[dataLength-1][0] == null) {
            this.adjustedData[dataLength-1][0] = "Non défini";
          }
          console.log(this.adjustedData);
          // Réinitialisation de l'array des données, paramètre du pie chart
          this.pieChartData = [];
          console.log(this.pieChartData);
          // Remplissage de l'array des données, en tenant compte du fait qu'il ne peut y avoir aucune observation pour certains taxons
          var start = 0;
          this.pieChartLabels.forEach(
            (taxon) => {
              var i = start;
              var keepGoing = true;
              while ((i < dataLength) && (keepGoing == true)) {
                if (taxon == this.adjustedData[i][0]) {
                  this.pieChartData.push(this.adjustedData[i][1]);
                  keepGoing = false;
                  start = i+1;
                }
                i += 1;
              }
              if (keepGoing == true) {
                this.pieChartData.push(undefined);
              }
            }
          );
          this.chart.chart.update();
        }
      ); 
    }

    if (this.pieChartForm.value.selectedFilter == "Classe") {
      // Réinitialisation de l'array des labels, paramètre du pie chart
      this.pieChartLabels = this.taxonomies["Classe"];
      if (this.pieChartLabels[this.pieChartLabels.length-1] != "Non défini") {
        this.pieChartLabels.push("Non défini");
      }
      console.log(this.pieChartLabels);
      // Accès aux données de synthèse la BDD GeoNature (phylum)
      this.dataService.getDataClasse(this.pieChartForm.value).subscribe(
        (data) => {
          // console.log(data);
          this.adjustedData = data;
          // Modification des données pour un nom de taxon null
          const dataLength = this.adjustedData.length;
          if (this.adjustedData[dataLength-1][0] == null) {
            this.adjustedData[dataLength-1][0] = "Non défini";
          }
          console.log(this.adjustedData);
          // Réinitialisation de l'array des données, paramètre du pie chart
          this.pieChartData = [];
          console.log(this.pieChartData);
          // Remplissage de l'array des données, en tenant compte du fait qu'il ne peut y avoir aucune observation pour certains taxons
          var start = 0;
          this.pieChartLabels.forEach(
            (taxon) => {
              var i = start;
              var keepGoing = true;
              while ((i < dataLength) && (keepGoing == true)) {
                if (taxon == this.adjustedData[i][0]) {
                  this.pieChartData.push(this.adjustedData[i][1]);
                  keepGoing = false;
                  start = i+1;
                }
                i += 1;
              }
              if (keepGoing == true) {
                this.pieChartData.push(undefined);
              }
            }
          );
          this.chart.chart.update();
        }
      ); 
    }

    if (this.pieChartForm.value.selectedFilter == "Groupe INPN 1") {
      // Réinitialisation de l'array des labels, paramètre du pie chart
      this.pieChartLabels = this.taxonomies["Groupe INPN 1"];
      if (this.pieChartLabels[this.pieChartLabels.length-1] != "Non défini") {
        this.pieChartLabels.push("Non défini");
      }
      console.log(this.pieChartLabels);
      // Accès aux données de synthèse la BDD GeoNature (phylum)
      this.dataService.getDataGroup1INPN(this.pieChartForm.value).subscribe(
        (data) => {
          // console.log(data);
          this.adjustedData = data;
          // Modification des données pour un nom de taxon null
          const dataLength = this.adjustedData.length;
          if (this.adjustedData[dataLength-1][0] == null) {
            this.adjustedData[dataLength-1][0] = "Non défini";
          }
          console.log(this.adjustedData);
          // Réinitialisation de l'array des données, paramètre du pie chart
          this.pieChartData = [];
          console.log(this.pieChartData);
          // Remplissage de l'array des données, en tenant compte du fait qu'il ne peut y avoir aucune observation pour certains taxons
          var start = 0;
          this.pieChartLabels.forEach(
            (taxon) => {
              var i = start;
              var keepGoing = true;
              while ((i < dataLength) && (keepGoing == true)) {
                if (taxon == this.adjustedData[i][0]) {
                  this.pieChartData.push(this.adjustedData[i][1]);
                  keepGoing = false;
                  start = i+1;
                }
                i += 1;
              }
              if (keepGoing == true) {
                this.pieChartData.push(undefined);
              }
            }
          );
          this.chart.chart.update();
        }
      ); 
    }

    if (this.pieChartForm.value.selectedFilter == "Groupe INPN 2") {
      // Réinitialisation de l'array des labels, paramètre du pie chart
      this.pieChartLabels = this.taxonomies["Groupe INPN 2"];
      if (this.pieChartLabels[this.pieChartLabels.length-1] != "Non défini") {
        this.pieChartLabels.push("Non défini");
      }
      console.log(this.pieChartLabels);
      // Accès aux données de synthèse la BDD GeoNature (phylum)
      this.dataService.getDataGroup2INPN(this.pieChartForm.value).subscribe(
        (data) => {
          // console.log(data);
          this.adjustedData = data;
          // Modification des données pour un nom de taxon null
          const dataLength = this.adjustedData.length;
          if (this.adjustedData[dataLength-1][0] == null) {
            this.adjustedData[dataLength-1][0] = "Non défini";
          }
          console.log(this.adjustedData);
          // Réinitialisation de l'array des données, paramètre du pie chart
          this.pieChartData = [];
          console.log(this.pieChartData);
          // Remplissage de l'array des données, en tenant compte du fait qu'il ne peut y avoir aucune observation pour certains taxons
          var start = 0;
          this.pieChartLabels.forEach(
            (taxon) => {
              var i = start;
              var keepGoing = true;
              while ((i < dataLength) && (keepGoing == true)) {
                if (taxon == this.adjustedData[i][0]) {
                  this.pieChartData.push(this.adjustedData[i][1]);
                  keepGoing = false;
                  start = i+1;
                }
                i += 1;
              }
              if (keepGoing == true) {
                this.pieChartData.push(undefined);
              }
            }
          );
          this.chart.chart.update();
        }
      ); 
    }
  }

}
