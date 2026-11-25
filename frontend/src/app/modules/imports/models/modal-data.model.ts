export interface ModalData {
  title: string; // Titre de la modal
  bodyMessage: string; // Message principal de la modal
  additionalMessage?: string; // Message supplémentaire (optionnel)
  cancelButtonText?: string; // Texte du bouton Annuler (optionnel)
  confirmButtonText?: string; // Texte du bouton Confirmer (optionnel)
  confirmButtonColor?: 'primary' | 'accent' | 'warn'; // Couleur du bouton Confirmer (optionnel)
  headerDataQa?: string; // Attribut `data-qa` pour le header de la modal (optionnel)
  confirmButtonDataQa?: string; // Attribut `data-qa` pour le bouton Confirmer (optionnel)
  params?: Object; // Paramètres d'interpolation des clés de traduction (optionnel)
}
