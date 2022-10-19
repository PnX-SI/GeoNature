import { Component, OnInit, OnDestroy, ViewChild, ChangeDetectorRef, AfterViewInit } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { AuthService, User } from '@geonature/components/auth/auth.service';
import { NotificationDataService } from '@geonature/components/notification/notification-data.service';
import { NotificationCard } from '@geonature/components/notification/notification-data.service';
import { MatPaginator } from '@angular/material/paginator';
import { Observable } from 'rxjs';
import { MatTableDataSource } from '@angular/material/table';


const NOTIFICATION_DATA_JSON = 
  {
    category: "VALIDATION-1",
    title: 'Modification du statut',
    content: 'Le statut de l\'observation a été modifié ( Invalide )',
    url: 'http://geonature.jdev.fr/geonature/#/validation/occurrence/2'
  };

@Component({
  selector: 'pnx-notification',
  templateUrl: './notification.component.html',
  styleUrls: ['./notification.component.scss']
})
export class NotificationComponent implements OnInit, OnDestroy, AfterViewInit  {

  public currentUser: User;
  
  @ViewChild(MatPaginator) paginator: MatPaginator;
  obs: Observable<any>;
  dataSource: MatTableDataSource<NotificationCard>= new MatTableDataSource<NotificationCard>(); 
  
  constructor(
    public authService: AuthService,
    private notificationDataService : NotificationDataService) {
    
  }

  ngOnInit(): void {

    // check for user information (must be connected for this feature)
    this.currentUser = this.authService.getCurrentUser();
    this.obs = this.dataSource.connect();
    this.getNotifications();
    this.createNotification(NOTIFICATION_DATA_JSON);
  }

  /**
   * get all notifications for current user
   */
   getNotifications() {
      this.notificationDataService.getNotifications().subscribe((response) => {
        console.log(response);
        this.dataSource.data = response;
    });

  }

  updateNotificationStatus(data) {
      this.notificationDataService.updateNotification(data).subscribe((response) => {
    });
  }

  createNotification(data) {
    this.notificationDataService.createNotification(data).subscribe((response) => {
  });
}
  ngOnDestroy() {
    if (this.dataSource) {
      this.dataSource.disconnect();
    }
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
  }

  //function with param item object
  OnMatCardClickEvent(notification:NotificationCard){
    // update status 
    this.updateNotificationStatus(notification)
    // open given url
    window.open(notification.url, '_self');
  }

}



