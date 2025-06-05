import { Component, Input, OnInit, OnDestroy } from '@angular/core';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { SyntheseStoreService, SyntheseTask } from '../../../services/store.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { ConfigService } from '@geonature/services/config.service';
import { HttpClient } from '@angular/common/http';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Observable, Subscription } from 'rxjs';
import { ThemePalette } from '@angular/material/core';

@Component({
  selector: 'pnx-synthese-modal-download',
  templateUrl: 'modal-download.component.html',
  styleUrls: ['modal-download.component.scss']
})
export class SyntheseModalDownloadComponent implements OnInit, OnDestroy {
  public syntheseConfig = null;
  public moduleCode = 'SYNTHESE'; // Module de synthèse
  public tasks$: Observable<SyntheseTask[]>;
  public bstype: string = 'info';
  private autoRefreshSubscription: Subscription;

  @Input() tooManyObs = false;

  constructor(
    public activeModal: NgbActiveModal,
    public _dataService: SyntheseDataService,
    private _fs: SyntheseFormService,
    private _storeService: SyntheseStoreService,
    public config: ConfigService,
    private http: HttpClient,
    private _dataFormService: DataFormService
  ) {
    this.syntheseConfig = this.config.SYNTHESE;
    
    // Récupérer l'ID du module Synthèse
    this._dataFormService.getModuleByCodeName(this.moduleCode).subscribe(module => {
      if (module && module.id_module) {
        this._storeService.moduleId = module.id_module.toString();
      }
    });
  }

  ngOnInit() {
    // Récupérer la liste des tâches
    this.tasks$ = this._storeService.tasks$;
    
    // Rafraîchir immédiatement les tâches actives
    this._storeService.refreshActiveTasks().subscribe();
    
    // Démarrer le rafraîchissement automatique des tâches actives toutes les 5 secondes
    this.autoRefreshSubscription = this._storeService.startAutoRefresh(5000).subscribe();
  }
  
  ngOnDestroy() {
    // Annuler le rafraîchissement automatique lorsque le composant est détruit
    if (this.autoRefreshSubscription) {
      this.autoRefreshSubscription.unsubscribe();
    }
  }

  downloadObservations(format, view_name) {
    const params = this._fs.formatParams();
    this.http.post<any>(`${this.config.API_ENDPOINT}/synthese/export_observations`, {
      ids: this._storeService.idSyntheseList,
      format: format,
      view_name: view_name,
      params: params
    }).subscribe(taskResponse => {
      // Définir explicitement les métadonnées de la tâche
      const taskInfo = {
        taskType: 'observations',
        format: format,
        view_name: view_name 
      };
      
      // Ajouter la tâche au store du module synthèse
      this._storeService.addTask({
        uuid: taskResponse.uuid_task,
        status: 'PENDING',
        progress: 0,
        result: null,
        downloadUrl: null,
        message: taskInfo
      });
      
      // Forcer l'enregistrement des métadonnées
      this._storeService.saveTaskMetadata(taskResponse.uuid_task, taskInfo);
    });
  }

  downloadTaxons(format, filename) {
    const params = this._fs.formatParams();
    this.http.post<any>(`${this.config.API_ENDPOINT}/synthese/export_taxons`, {
      ids: this._storeService.idSyntheseList,
      format: format,
      params: params
    }).subscribe(taskResponse => {
      // Définir explicitement les métadonnées de la tâche
      const taskInfo = {
        taskType: 'taxons',
        format: format,
        filename: filename
      };
      
      // Ajouter la tâche au store du module synthèse
      this._storeService.addTask({
        uuid: taskResponse.uuid_task,
        status: 'PENDING',
        progress: 0,
        result: null,
        downloadUrl: null,
        message: taskInfo
      });
      
      // Forcer l'enregistrement des métadonnées
      this._storeService.saveTaskMetadata(taskResponse.uuid_task, taskInfo);
    });
  }

  downloadStatusOrMetadata(url, filename) {
    const params = this._fs.formatParams();
    // Ne pas changer le nom de l'endpoint car le backend utilise déjà export_
    this.http.post<any>(`${this.config.API_ENDPOINT}/${url}`, params).subscribe(taskResponse => {
      // Définir explicitement les métadonnées de la tâche
      const taskInfo = {
        taskType: url.includes('statuts') ? 'statuts' : 'metadata',
        filename: filename
      };
      
      // Ajouter la tâche au store du module synthèse
      this._storeService.addTask({
        uuid: taskResponse.uuid_task,
        status: 'PENDING',
        progress: 0,
        result: null,
        downloadUrl: null,
        message: taskInfo
      });
      
      // Forcer l'enregistrement des métadonnées
      this._storeService.saveTaskMetadata(taskResponse.uuid_task, taskInfo);
    });
  }

  /**
   * Télécharger le résultat d'une tâche
   */
  downloadTaskResult(task: SyntheseTask) {
    const isSuccess = task.status?.toUpperCase() === 'SUCCESS';
    if (isSuccess) {
      if (task.downloadUrl) {
        // Si un lien de téléchargement direct est disponible, l'utiliser
        this._storeService.downloadTaskResult(task.uuid).subscribe(
          result => {
            console.log('Téléchargement démarré:', result);
          },
          error => {
            console.error('Erreur lors du téléchargement:', error);
            // Afficher un message d'erreur à l'utilisateur
            alert("Erreur lors du téléchargement: " + error.message);
          }
        );
      } else if (task.result) {
        // Si la tâche a un résultat mais pas de lien de téléchargement,
        // afficher un message d'information
        alert("Le résultat de cette tâche ne peut pas être téléchargé directement.");
      } else {
        alert("Aucun résultat disponible pour cette tâche.");
      }
    }
  }

  /**
   * Rafraîchir manuellement le statut de toutes les tâches actives
   * (cette méthode est principalement pour avoir un bouton de rafraîchissement manuel en plus du rafraîchissement automatique)
   */
  refreshTaskStatus(task: SyntheseTask) {
    this._storeService.refreshActiveTasks().subscribe();
  }

  /**
   * Supprimer une tâche de la liste
   */
  removeTask(task: SyntheseTask) {
    this._storeService.removeTask(task.uuid);
  }

  /**
   * Formater le statut d'une tâche pour l'affichage
   */
  getStatusLabel(status: string): string {
    const statusUpper = status ? status.toUpperCase() : '';
    switch (statusUpper) {
      case 'PENDING':
        return 'En attente';
      case 'PROGRESS':
        return 'En cours';
      case 'SUCCESS':
        return 'Terminée';
      case 'FAILURE':
        return 'Échouée';
      default:
        return status;
    }
  }

  /**
   * Déterminer la classe CSS à appliquer en fonction du statut
   */
  getStatusClass(status: string): string {
    const statusUpper = status ? status.toUpperCase() : '';
    switch (statusUpper) {
      case 'PENDING':
        return 'status-pending';
      case 'PROGRESS':
        return 'status-progress';
      case 'SUCCESS':
        return 'status-success';
      case 'FAILURE':
        return 'status-failure';
      default:
        return '';
    }
  }
  
  /**
   * Ces méthodes ont été supprimées car nous n'utilisons plus d'icônes d'état
   */
  
  /**
   * Récupérer une description de la tâche en fonction du type d'export
   */
  getTaskDescription(task: SyntheseTask): string {
    if (!task || !task.uuid) {
      return 'Export de données';
    }
    
    // Récupérer les métadonnées du message
    const message = task.message || {};
    
    // Récupérer le type de tâche ou utiliser une valeur par défaut
    const taskType = message.taskType || '';
    const format = message.format || 'CSV';
    
    console.log(`Génération du titre pour la tâche ${task.uuid}, type: ${taskType}`, message);
    
    switch (taskType) {
      case 'observations':
        return `Export des observations au format ${format}`;
      case 'taxons':
        return `Export des taxons`;
      case 'statuts':
        return `Export des statuts de protection`;
      case 'metadata':
        return `Export des métadonnées`;
      default:
        // En cas d'absence de type de tâche, vérifier s'il y a d'autres indices dans le message
        if (message.format && message.view_name) {
          return `Export des observations au format ${message.format}`;
        } else if (message.filename && message.filename.includes('taxon')) {
          return `Export des taxons`;
        } else if (message.filename && message.filename.includes('statut')) {
          return `Export des statuts de protection`;
        } else if (message.filename && message.filename.includes('meta')) {
          return `Export des métadonnées`;
        }
        
        return `Export de données`;
    }
  }
}
