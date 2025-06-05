import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { BehaviorSubject, Observable, interval, of } from 'rxjs';
import { map, switchMap, takeWhile } from 'rxjs/operators';

export interface SyntheseTask {
  uuid: string;
  status: 'pending' | 'success' | 'error';
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
  Synthèse;

  // Gestion des tâches asynchrones
  private tasks = new BehaviorSubject<SyntheseTask[]>([]);
  // Stockage des métadonnées de tâches pour conserver les informations entre les actualisations
  private taskMetadata: Map<string, any> = new Map();

  /**
   * Sauvegarde les métadonnées d'une tâche
   * @param taskUuid L'UUID de la tâche
   * @param metadata Les métadonnées à sauvegarder
   */
  public saveTaskMetadata(taskUuid: string, metadata: any): void {
    if (taskUuid && metadata) {
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
    return this.tasks$.pipe(map((tasks) => tasks.filter((task) => task.status === 'pending')));
  }

  /**
   * Retourne un observable avec le nombre de tâches actives
   */
  get activeTasksCount$(): Observable<number> {
    return this.activeTasks$.pipe(map((tasks) => tasks.length));
  }

  /**
   * Ajoute une tâche à la liste
   * @param task La tâche à ajouter
   */
  addTask(task: SyntheseTask): void {
    if (task.message) {
      this.taskMetadata.set(task.uuid, { ...task.message });
    }
    this.tasks.next([...this.tasks.value, task]);
  }

  /**
   * Met à jour une tâche existante
   * @param updatedTask La tâche mise à jour
   */
  updateTask(updatedTask: SyntheseTask): void {
    const taskList = this.tasks.value;
    const index = taskList.findIndex((t) => t.uuid === updatedTask.uuid);

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
    this.taskMetadata.delete(taskUuid);
    this.tasks.next(currentTasks.filter((task) => task.uuid !== taskUuid));
  }

  /**
   * Récupère le statut d'une tâche et met à jour le store
   * @param taskUuid L'identifiant unique de la tâche
   */
  refreshTaskStatus(taskUuid: string): Observable<SyntheseTask> {
    return this.dataFormService
      .getTask(taskUuid)
      .pipe(map((response) => {
        // Si la réponse est un tableau, prendre le premier élément
        if (Array.isArray(response) && response.length > 0) {
          return this.processTaskResponse(response[0], taskUuid);
        }
        return this.processTaskResponse(response, taskUuid);
      }));
  }

  /**
   * Rafraîchit le statut de toutes les tâches actives en une seule requête
   * @returns Observable contenant un tableau des tâches mises à jour
   */
  refreshActiveTasks(): Observable<SyntheseTask[]> {
    const activeTasks = this.tasks.value.filter((task) => task.status === 'pending');

    if (activeTasks.length === 0) {
      return of([]);
    }

    const activeTaskUuids = activeTasks.map((task) => task.uuid);

    return this.dataFormService.getTasksByUuids(activeTaskUuids).pipe(
      map((responses) => {
        const updatedTasks: SyntheseTask[] = [];
        
        // L'API retourne toujours un tableau de tâches
        const taskResponses = Array.isArray(responses) ? responses : [responses];
        
        // Traiter chaque réponse
        taskResponses.forEach((response) => {
          if (!response) return;
          
          const taskUuid = response.uuid_celery || response.uuid;
          if (taskUuid) {
            updatedTasks.push(this.processTaskResponse(response, taskUuid));
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
        status: 'error',
        result: { error: 'Tâche non trouvée' },
        downloadUrl: null,
      };
    }

    // Normaliser le statut en minuscules pour correspondre à nos vérifications
    let status = (response.status || 'error').toLowerCase();
    
    // Mapper les statuts potentiels du backend vers nos trois statuts simplifiés
    if (status === 'success' || status === 'done') {
      status = 'success';
    } else if (status === 'pending' || status === 'progress') {
      status = 'pending';
    } else {
      status = 'error';
    }
    const storedMetadata = this.taskMetadata.get(taskUuid);

    // Le message est toujours présent dans la réponse
    const resultData = response.message;

    const updatedTask: SyntheseTask = {
      uuid: response.uuid_celery || response.uuid,
      status: status,
      result: resultData,
      downloadUrl: null,
      message: storedMetadata,
    };

    if (status === 'success') {
      // Vérifier toutes les propriétés possibles pour l'URL de téléchargement
      if (response.url) {
        updatedTask.downloadUrl = response.url;
      } 
      else if (response.file_name) {
        updatedTask.downloadUrl = this.dataFormService.getFileDownloadUrl(response.file_name);
      }
      else if (response.download_url) {
        updatedTask.downloadUrl = response.download_url;
      }
      // Si on a un file_path, on peut aussi essayer de créer une URL
      else if (resultData && resultData.file_path) {
        const fileName = resultData.file_path.split('/').pop();
        if (fileName) {
          updatedTask.downloadUrl = this.dataFormService.getFileDownloadUrl(fileName);
        }
      }
    }

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
      takeWhile((task) => task.status === 'pending', true)
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
        const activeTasks = this.tasks.value.filter((task) => task.status === 'pending');

        if (activeTasks.length === 0) {
          return of([]);
        }

        return this.refreshActiveTasks();
      })
    );
  }

  /**
   * Télécharge le résultat d'une tâche terminée avec succès
   * @param taskUuid L'identifiant unique de la tâche
   */
  downloadTaskResult(taskUuid: string): Observable<any> {
    const task = this.tasks.value.find((t) => t.uuid === taskUuid);

    if (task?.status === 'success' && task.downloadUrl) {
      this.dataFormService.triggerFileDownload(task.downloadUrl);
      return of({ success: true, url: task.downloadUrl });
    }

    return this.refreshTaskStatus(taskUuid).pipe(
      map((updatedTask) => {
        if (updatedTask.status !== 'success') {
          throw new Error("La tâche n'est pas terminée avec succès");
        }

        if (!updatedTask.downloadUrl) {
          throw new Error('Aucun lien de téléchargement trouvé pour cette tâche');
        }

        this.dataFormService.triggerFileDownload(updatedTask.downloadUrl);
        return { success: true, url: updatedTask.downloadUrl };
      })
    );
  }
}
