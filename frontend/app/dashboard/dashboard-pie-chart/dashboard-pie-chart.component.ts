import { Component, OnInit, ViewChild } from "@angular/core";
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
  public pieChartLabelsTest = [];
  public pieChartType = 'doughnut';
  public pieChartData = [];
  public pieChartDataTest = [];
  public pieChartColors = [
    { backgroundColor: ["#ff9800", "#8bc34a"] } 
  ];
  pieChartForm: FormGroup;

  constructor(public dataService: DataService, public fb: FormBuilder) {
    // Déclaration du formulaire contenant les filtres du pie chart
    this.pieChartForm = fb.group({
      yearMin: fb.control(null),
      yearMax: fb.control(null)
    }); 
  }

  ngOnInit() {
    // Accès aux données de la BDD GeoNature 
    this.dataService.getDataRegne().subscribe(
      (data) => {
        console.log(data);
        //Création des variables qui seront paramètres du bar chart
        data.forEach(
          (elt) => {
            this.pieChartLabels.push(elt[0]);
            this.pieChartData.push(elt[1]);
          }
        );
        this.chart.chart.update();
      }
    );
    console.log(this.pieChartLabels);
    console.log(this.pieChartData);
  }

  // Rafraichissement des données en fonction des filtres renseignés par l'utilisateur
  refreshData() {
    this.dataService.getDataRegne(this.pieChartForm.value).subscribe(
      (data) => {
        console.log(data);
        this.pieChartLabels = [];
        this.pieChartData = [];
        //Re-création des variables qui seront paramètres du bar chart
        data.forEach(
          (elt) => {
            this.pieChartLabels.push(elt[0]);
            this.pieChartData.push(elt[1]);
          }
        );
        this.chart.chart.update();
      }
    );
    console.log(this.pieChartLabels);
    console.log(this.pieChartData);
  }

}
