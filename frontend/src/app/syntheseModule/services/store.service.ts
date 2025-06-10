import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, interval, of } from 'rxjs';
import { map, switchMap, takeWhile } from 'rxjs/operators';
import { HttpClient } from '@angular/common/http';
import { ConfigService } from '@geonature/services/config.service';
import { DataFormService } from '@geonature_common/form/data-form.service';

export interface SyntheseTask {
  uuid: string;
  status: 'PENDING' | 'PROGRESS' | 'SUCCESS' | 'FAILURE' | 'pending' | 'progress' | 'success' | 'failure';
  progress: number;
  result: any;
  message?: {
    taskType?: 'observations' | 'taxons' | 'statuts' | 'metadata' | string;
    format?: string;
    view_name?: string;
    filename?: string;
    [key: string]: any;
  };
  downloadUrl?: string;
}

@Injectable({
  providedIn: 'root',
})
export class SyntheseStoreService {
  public idSyntheseList: Array<number>;
  public gridData: Array<any>;
  public pointData: Array<any>;
  public moduleId: string; // ID du module Synthèse
  
  // Gestion des tâches asynchrones
  private tasks = new BehaviorSubject<SyntheseTask[]>([]);
  // Stockage des métadonnées de tâches pour conserver les informations entre les actualisations
  private taskMetadata: Map<string, any> = new Map();
  
  /**
   * Sauvegarde explicitement les métadonnées d'une tâche pour les préserver entre les actualisations
   * @param taskUuid L'UUID de la tâche
   * @param metadata Les métadonnées à sauvegarder
   */
  public saveTaskMetadata(taskUuid: string, metadata: any): void {
    if (taskUuid && metadata) {
      console.log(`Sauvegarde des métadonnées pour la tâche ${taskUuid}:`, metadata);
      this.taskMetadata.set(taskUuid, { ...metadata });
    }
  }

  constructor(
    private http: HttpClient,
    private config: ConfigService,
    private dataFormService: DataFormService
  ) {}
  
  /**
   * Retourne un observable avec toutes les tâches
   */
  get tasks$(): Observable<SyntheseTask[]> {
    return this.tasks.asObservable();
  }
  
  /**
   * Retourne un observable avec les tâches actives uniquement
   */
  get activeTasks$(): Observable<SyntheseTask[]> {
    return this.tasks$.pipe(
      map(tasks => tasks.filter(task => 
        task.status === 'PENDING' || task.status === 'PROGRESS'
      ))
    );
  }
  
  /**
   * Retourne un observable avec le nombre de tâches actives
   */
  get activeTasksCount$(): Observable<number> {
    return this.activeTasks$.pipe(
      map(tasks => tasks.length)
    );
  }
  
  /**
   * Ajoute une tâche à la liste et commence à la suivre
   * @param task La tâche à ajouter
   */
  addTask(task: SyntheseTask): void {
    const currentTasks = this.tasks.value;
    if (!currentTasks.find(t => t.uuid === task.uuid)) {
      // Stocker les métadonnées de la tâche pour les conserver entre les actualisations
      if (task.message) {
        this.taskMetadata.set(task.uuid, { ...task.message });
      }
      this.tasks.next([...currentTasks, task]);
    }
  }
  
  /**
   * Met à jour une tâche existante
   * @param updatedTask La tâche mise à jour
   */
  updateTask(updatedTask: SyntheseTask): void {
    const taskList = this.tasks.value;
    const index = taskList.findIndex(t => t.uuid === updatedTask.uuid);
    
    if (index !== -1) {
      taskList[index] = updatedTask;
      this.tasks.next([...taskList]);
    }
  }
  
  /**
   * Supprime une tâche de la liste
   * @param taskUuid L'identifiant unique de la tâche à supprimer
   */
  removeTask(taskUuid: string): void {
    const currentTasks = this.tasks.value;
    // Supprimer également les métadonnées stockées pour cette tâche
    this.taskMetadata.delete(taskUuid);
    this.tasks.next(currentTasks.filter(task => task.uuid !== taskUuid));
  }
  
  /**
   * Récupère le statut d'une tâche et met à jour le store
   * @param taskUuid L'identifiant unique de la tâche
   */
  refreshTaskStatus(taskUuid: string): Observable<SyntheseTask> {
    return this.dataFormService.getTask(taskUuid).pipe(
      map(response => {
        return this.processTaskResponse(response, taskUuid);
      })
    );
  }
  
  /**
   * Rafraîchit le statut de toutes les tâches actives en une seule requête
   * @returns Observable contenant un tableau des tâches mises à jour
   */
  refreshActiveTasks(): Observable<SyntheseTask[]> {
    // Récupérer les UUIDs des tâches actives
    const activeTasks = this.tasks.value.filter(task => 
      task.status === 'PENDING' || task.status === 'PROGRESS'
    );
    
    // Si aucune tâche active, retourner un observable vide
    if (activeTasks.length === 0) {
      return of([]);
    }
    
    // Extraire les UUIDs
    const activeTaskUuids = activeTasks.map(task => task.uuid);
    
    // Récupérer les statuts de toutes les tâches actives en une seule requête
    return this.dataFormService.getTasksByUuids(activeTaskUuids).pipe(
      map(responses => {
        const updatedTasks: SyntheseTask[] = [];
        
        // Pour chaque tâche dans la réponse
        responses.forEach(response => {
          // Utiliser l'UUID de la réponse, ou l'UUID stocké dans la réponse
          const taskUuid = response.uuid || (response.uuid_celery ? response.uuid_celery : null);
          if (taskUuid) {
            const updatedTask = this.processTaskResponse(response, taskUuid);
            updatedTasks.push(updatedTask);
          } else {
            console.error("Impossible de déterminer l'UUID de la tâche", response);
          }
        });
        
        return updatedTasks;
      })
    );
  }
  
  /**
   * Traite la réponse d'une tâche et la met à jour dans le store
   * @param response La réponse de l'API pour une tâche
   * @param taskUuid L'UUID de la tâche (utilisé si la réponse est null)
   * @returns La tâche mise à jour
   */
  private processTaskResponse(response: any, taskUuid: string): SyntheseTask {
    if (!response) {
      return {
        uuid: taskUuid,
        status: 'FAILURE',
        progress: 0,
        result: { error: "Tâche non trouvée" },
        downloadUrl: null
      };
    }
    
    // Utiliser le service DataFormService pour analyser le message JSON
    const messageObj = this.dataFormService.parseJsonMessage(response.message);

    // Normaliser le statut (convertir tout en majuscules pour correspondre à notre enum)
    const normalizedStatus = response.status ? response.status.toUpperCase() : 'FAILURE';
    
    // Récupérer les métadonnées stockées pour cette tâche (pour conserver le type d'export)
    const storedMetadata = this.taskMetadata.get(taskUuid);
    
    if (storedMetadata) {
      console.log(`Restauration des métadonnées pour la tâche ${taskUuid}:`, storedMetadata);
    }
    
    // Construire un objet SyntheseTask à partir de la réponse
    const updatedTask: SyntheseTask = {
      uuid: response.uuid_celery || response.uuid,
      status: normalizedStatus,
      progress: response.progress || 0,
      result: messageObj || response.message,
      downloadUrl: null,
      // Utiliser prioritairement les métadonnées stockées
      message: storedMetadata || (messageObj ? { ...messageObj } : undefined)
    };
    
    // Si la tâche est terminée et contient un lien vers un fichier, utiliser ce lien
    if (normalizedStatus === 'SUCCESS') {
      if (messageObj && messageObj.file_path) {
        // Utiliser le service DataFormService pour construire l'URL de téléchargement
        updatedTask.downloadUrl = this.dataFormService.getFileDownloadUrl(messageObj.file_path);
      } else if (messageObj && messageObj.url) {
        updatedTask.downloadUrl = messageObj.url;
      } else if (response.url) {
        // Utiliser directement l'URL de la réponse si disponible
        updatedTask.downloadUrl = response.url;
      }
    }
    
    // Mettre à jour la tâche dans le store
    this.updateTask(updatedTask);
    return updatedTask;
  }
  
  /**
   * Met en place un polling pour surveiller l'état d'une tâche jusqu'à ce qu'elle soit terminée
   * @param taskUuid L'identifiant unique de la tâche à surveiller
   * @param pollInterval Intervalle de temps entre chaque vérification (en ms)
   */
  pollTaskStatus(taskUuid: string, pollInterval: number = 3000): Observable<SyntheseTask> {
    return interval(pollInterval).pipe(
      switchMap(() => this.refreshTaskStatus(taskUuid)),
      takeWhile(task => 
        task.status === 'PENDING' || task.status === 'PROGRESS', 
        true // Inclut la dernière valeur qui a fait échouer le prédicat
      )
    );
  }
  
  /**
   * Configure un rafraîchissement automatique des tâches actives
   * @param pollInterval Intervalle de temps entre chaque vérification (en ms)
   * @returns Un Observable qui émet la liste des tâches actives mises à jour
   */
  startAutoRefresh(pollInterval: number = 5000): Observable<SyntheseTask[]> {
    return interval(pollInterval).pipe(
      switchMap(() => {
        const activeTasks = this.tasks.value.filter(task => 
          task.status === 'PENDING' || task.status === 'PROGRESS'
        );
        
        // Si aucune tâche active, émettre un tableau vide
        if (activeTasks.length === 0) {
          return of([]);
        }
        
        // Sinon, rafraîchir les tâches actives
        return this.refreshActiveTasks();
      })
    );
  }
  
  /**
   * Télécharge le résultat d'une tâche terminée avec succès
   * @param taskUuid L'identifiant unique de la tâche
   */
  downloadTaskResult(taskUuid: string): Observable<any> {
    // Récupérer la tâche dans le store local si elle existe
    const task = this.tasks.value.find(t => t.uuid === taskUuid);
    
    if (task && task.status?.toUpperCase() === 'SUCCESS' && task.downloadUrl) {
      // La tâche est déjà dans le store et prête pour le téléchargement
      this.dataFormService.triggerFileDownload(task.downloadUrl);
      return of({ success: true, url: task.downloadUrl });
    } else {
      // Sinon, rafraîchir le statut et télécharger si prêt
      return this.refreshTaskStatus(taskUuid).pipe(
        map(updatedTask => {
          const isSuccess = updatedTask.status?.toUpperCase() === 'SUCCESS';
          if (!isSuccess) {
            throw new Error("La tâche n'est pas terminée avec succès");
          }
          
          if (!updatedTask.downloadUrl) {
            throw new Error("Aucun lien de téléchargement trouvé pour cette tâche");
          }
          
          // Déclencher le téléchargement via le service DataFormService
          this.dataFormService.triggerFileDownload(updatedTask.downloadUrl);
          
          return { success: true, url: updatedTask.downloadUrl };
        })
      );
    }
  }
}
