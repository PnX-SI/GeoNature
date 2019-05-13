import { Component, OnInit } from "@angular/core";
import { Title } from "@angular/platform-browser"

@Component({
  selector: "dashboard",
  templateUrl: "dashboard.component.html",
  styleUrls: ['./dashboard.component.scss']
})
export class DashboardComponent implements OnInit {

  constructor(title: Title) {
    title.setTitle("GeoNature - Dashboard")
  }

  ngOnInit() {
    
  }

}
