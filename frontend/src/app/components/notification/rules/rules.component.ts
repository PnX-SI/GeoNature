import { Component, OnInit } from '@angular/core';
import {
  NotificationCategory,
  NotificationMethod,
  NotificationRule,
  NotificationDataService,
} from '@geonature/components/notification/notification-data.service';

@Component({
  selector: 'pnx-rules',
  templateUrl: './rules.component.html',
  styleUrls: ['./rules.component.scss'],
})
export class RulesComponent implements OnInit {
  rulesMethods: NotificationMethod[] = [];
  rulesCategories: NotificationCategory[] = [];
  userRules: NotificationRule[] = [];

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
      this.userRules = response;
    });
  }

  /**
   * get all exisiting methods of notification
   */
  getMethods() {
    this.notificationDataService.getRulesMethods().subscribe((response) => {
      this.rulesMethods = response;
    });
  }

  /**
   * get all exisiting categories of notification
   */
  getCategories() {
    this.notificationDataService.getRulesCategories().subscribe((response) => {
      this.rulesCategories = response;
    });
  }

  /**
   * Create a rule for un user
   * data inclue code_category and code_method
   */
  subscribe(category, method) {
    this.notificationDataService.subscribe(category, method).subscribe((response) => {});
  }

  /**
   * delete one rule with its id
   */
  unsubscribe(category, method) {
    this.notificationDataService.unsubscribe(category, method).subscribe((response) => {});
  }

  /**
   * delete all user rules
   */
  clearSubscriptions() {
    this.notificationDataService.clearSubscriptions().subscribe((response) => {
      // refresh rules values
      //this.getRules();  -- this does not trigger update of checkboxes
      this.ngOnInit();
    });
  }

  /**
   * Action from checkbox to create or delete a rule depending on checkbox value
   *
   * @param category notification code_category
   * @param method notification code_method
   * @param event event to get checkbox
   */
  updateRule(category, method, event) {
    // if checkbox is checked add rule
    if (event.target.checked) {
      this.subscribe(category, method);
    } else {
      this.unsubscribe(category, method);
    }
  }

  /**
   * function to knwo if user has a rule with this categorie and role
   * @param categorie notification code_category
   * @param method notification code_method
   * @returns boolean
   */
  hasUserSubscribed(categorie, method) {
    for (var rule of this.userRules) {
      if (rule.code_category == categorie && rule.code_method == method) {
        return rule.subscribed;
      }
    }
    return false;
  }
}
