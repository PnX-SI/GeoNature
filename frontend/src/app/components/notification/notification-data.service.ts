
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

@Injectable()
export class NotificationDataService {

    constructor(private _api: HttpClient) {
    }

    // returns notifications content for this user
    getNotifications() {
        return this._api.get(`${AppConfig.API_ENDPOINT}/notifications`);
    }

    // returns number of notification for this user
    getNotificationsNumber():number {
        console.log(this._api.get(`${AppConfig.API_ENDPOINT}/notificationsNumber`));
        return 2; //this._api.get(`${AppConfig.API_ENDPOINT}/notificationsNumber`);
    }

}

