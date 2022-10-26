import { Component, OnInit } from '@angular/core';
import {
  CategoriesRules,
  MethodRules,
  NotificationDataService,
  Rules,
} from '@geonature/components/notification/notification-data.service';

@Component({
  selector: 'pnx-rules',
  templateUrl: './rules.component.html',
  styleUrls: ['./rules.component.scss'],
})
export class RulesComponent implements OnInit {
  rulesMethods: MethodRules[];
  rulesCategories: CategoriesRules[];
  userRules: Rules[];

  constructor(private notificationDataService: NotificationDataService) {}

  ngOnInit(): void {
    this.getMethods();
    this.getCategories();
    this.getRules();
  }

  /**
   * get all rules for current user
   */
  getRules() {
    this.notificationDataService.getRules().subscribe((response) => {
      //console.log(response);
      this.userRules = response;
    });
  }

  /**
   * get all rules for current user
   */
  getMethods() {
    this.notificationDataService.getRulesMethods().subscribe((response) => {
      this.rulesMethods = response;
    });
  }

  /**
   * get all rules for current user
   */
  getCategories() {
    this.notificationDataService.getRulesCategories().subscribe((response) => {
      this.rulesCategories = response;
    });
  }

  /**
   * get all rules for current user
   */
  createRule(data) {
    this.notificationDataService.createRule(data).subscribe((response) => {});
  }

  /**
   * delete one rule
   */
  deleteRule(data) {
    this.notificationDataService.deleteRule(data).subscribe((response) => {});
  }

  /**
   * delete all rules
   */
  deleteRules() {
    this.notificationDataService.deleteRules().subscribe((response) => {
      // refresh rules values
      this.ngOnInit();
    });
  }

  updateRule(categorie, method, event) {
    // if checkbox is checked add rule
    if (event.target.checked) {
      this.createRule({ code_method: method, code_category: categorie });
    } else {
      // if checkbox not checked remove rule
      this.deleteRule({ code_method: method, code_category: categorie });
    }
  }

  hasUserSubscribed(categorie, method) {
    let checked: boolean = false;
    for (var rule of this.userRules) {
      if (rule.code_category == categorie && rule.code_method == method) {
        checked = true;
      }
    }
    return checked;
  }
}
