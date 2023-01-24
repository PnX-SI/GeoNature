import { Injectable } from '@angular/core';
import {
  HttpClient,
  HttpHeaders,
} from '@angular/common/http';

import { Observable } from 'rxjs';
import { ConfigService } from '@geonature/services/config.service';

/** Interface to display notifications */
export interface NotificationCard {
  id_notification: string;
  title: string;
  content: string;
  url: string;
  code_status: string;
  creation_date: string;
}

/** Interface to serialise method rules */
export interface NotificationMethod {
  code: string;
  label: string;
  description: string;
}

/** Interface to serialise categorie rules */
export interface NotificationCategory {
  code: string;
  label: string;
  description: string;
}

/** Interface to serialise categorie rules */
export interface NotificationRule {
  id: number;
  code_category: string;
  code_method: string;
  method?: NotificationMethod;
  category?: NotificationCategory;
}

@Injectable()
export class NotificationDataService {
  constructor(private _api: HttpClient,
    public cs: ConfigService
    ) {}

  // returns notifications content for this user
  getNotifications(): Observable<NotificationCard[]> {
    return this._api.get<NotificationCard[]>(
      `${this.cs.API_ENDPOINT}/notifications/notifications`
    );
  }

  // returns number of notification for this user
  getNotificationsNumber(): any {
    return this._api.get<any>(`${this.cs.API_ENDPOINT}/notifications/count`);
  }

  deleteNotifications() {
    return this._api.delete<any>(`${this.cs.API_ENDPOINT}/notifications/notifications`);
  }

  // update notification status
  updateNotification(idNotification) {
    return this._api.post(
      `${this.cs.API_ENDPOINT}/notifications/notifications/${idNotification}`,
      {
        headers: new HttpHeaders().set('Content-Type', 'application/json'),
      }
    );
  }

  // Create rules
  createRule(data) {
    return this._api.put(`${this.cs.API_ENDPOINT}/notifications/rules`, data, {
      headers: new HttpHeaders().set('Content-Type', 'application/json'),
    });
  }

  // returns all rules for current user
  getRules() {
    return this._api.get<NotificationRule[]>(`${this.cs.API_ENDPOINT}/notifications/rules`);
  }

  // returns notifications content for this user
  getRulesCategories() {
    return this._api.get<NotificationCategory[]>(
      `${this.cs.API_ENDPOINT}/notifications/categories`
    );
  }

  // returns notifications content for this user
  getRulesMethods() {
    return this._api.get<NotificationMethod[]>(`${this.cs.API_ENDPOINT}/notifications/methods`);
  }

  deleteRules() {
    return this._api.delete<{}>(`${this.cs.API_ENDPOINT}/notifications/rules`);
  }

  deleteRule(id: number) {
    return this._api.delete<{}>(`${this.cs.API_ENDPOINT}/notifications/rules/${id}`);
  }
}
