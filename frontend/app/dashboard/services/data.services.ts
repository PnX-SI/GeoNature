import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable()
export class DataService {
    constructor(private httpClient: HttpClient) { }
    
    getCommunes() {
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/communes")
    }
}
