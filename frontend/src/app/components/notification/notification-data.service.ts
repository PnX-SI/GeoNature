import { Injectable } from '@angular/core';
import {
  HttpClient,
  HttpParams,
  HttpHeaders,
  HttpEventType,
  HttpErrorResponse,
  HttpEvent,
} from '@angular/common/http';

import { AppConfig } from '../../../conf/app.config';
import * as internal from 'stream';

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
export interface MethodRules {
  code: string;
  label: string;
  description: string;
}

/** Interface to serialise categorie rules */
export interface CategoriesRules {
  code: string;
  label: string;
  description: string;
}

/** Interface to serialise categorie rules */
export interface Rules {
  id_notification_rules: number;
  code_category: string;
  code_method: string;
}

@Injectable()
export class NotificationDataService {
  constructor(private _api: HttpClient) {}

  // Create notification via API
  // Could be used for notification on frond environnement
  createNotification(data) {
    return this._api.put(`${AppConfig.API_ENDPOINT}/notifications/notification`, data, {
      headers: new HttpHeaders().set('Content-Type', 'application/json'),
    });
  }

  // returns notifications content for this user
  getNotifications() {
    return this._api.get<NotificationCard[]>(
      `${AppConfig.API_ENDPOINT}/notifications/notifications`
    );
  }

  // returns number of notification for this user
  getNotificationsNumber(): any {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/notifications/count`);
  }

  deleteNotifications() {
    return this._api.delete<any>(`${AppConfig.API_ENDPOINT}/notifications/notifications`);
  }

  // update notification status
  updateNotification(idNotification) {
    return this._api.post(
      `${AppConfig.API_ENDPOINT}/notifications/notifications/${idNotification}`,
      {
        headers: new HttpHeaders().set('Content-Type', 'application/json'),
      }
    );
  }

  // Create rules
  createRule(data) {
    return this._api.put(`${AppConfig.API_ENDPOINT}/notifications/rules`, data, {
      headers: new HttpHeaders().set('Content-Type', 'application/json'),
    });
  }

  // returns all rules for current user
  getRules() {
    return this._api.get<Rules[]>(`${AppConfig.API_ENDPOINT}/notifications/rules`);
  }

  // returns notifications content for this user
  getRulesCategories() {
    return this._api.get<CategoriesRules[]>(`${AppConfig.API_ENDPOINT}/notifications/categories`);
  }

  // returns notifications content for this user
  getRulesMethods() {
    return this._api.get<MethodRules[]>(`${AppConfig.API_ENDPOINT}/notifications/methods`);
  }

  deleteRules() {
    return this._api.delete<any>(`${AppConfig.API_ENDPOINT}/notifications/rules`);
  }

  deleteRule(id_notification_rules) {
    return this._api.delete<any>(
      `${AppConfig.API_ENDPOINT}/notifications/rules/${id_notification_rules}`
    );
  }
}
