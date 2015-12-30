FileDownloader = {
  load : function(config) {
    var el = Ext.getBody();

    //création de l'url avec d'eventuels paramètres
    var url = config.url + (config.params ? '?' + Ext.urlEncode(config.params) : '');
    var format = config.format || 'pdf';

    return new Promise(function(resolve, reject) {
      //Si le navigateur gère la création d'URL à partir de blob
      if (!Ext.isEmpty(window.URL) && Ext.isFunction(window.URL.createObjectURL) && window.Blob) {
        //Alors on va effectuer une requête ajax
        var xhr = new XMLHttpRequest();
        xhr.open('GET', url, true);
        xhr.responseType = 'blob';

        xhr.onload = function(e) {
          //Et si tout s'est bien passé
          if (this.status == 200) {
            //Alors on construit un blob avec la réponse
            var blob = new Blob([this.response], {
              type : e.currentTarget.response.type
            });

            //On en génère un URL
            var url = window.URL.createObjectURL(blob);

            //Et on va regarder si on a dans les paramètres un nom de fichier
            var fileName = config.filename || 'fichier';

            //Et on peut alors resolve notre promise
            resolve(url);

            //On récupère la bonne extension suivant le format choisi
            if (navigator.msSaveBlob) {
              navigator.msSaveBlob(blob, fileName + "." + format);
            } else {
              //On construit alors une balise <a>, avec l'attribut "download" qui permet de spécifier le nom du fichier qui sera téléchargé
              var a = el.createChild({
                tag : 'a',
                href : url,
                download : fileName + "." + format
              });
              //Et on lance le click sur le lien pour afficher le fenêtre de téléchargement
              a.dom.click();
            }

          } else {
            //Si il y a eu un problème, on reject avec le code erreur
            reject(this.status);
          }
        };

        xhr.send();

      } else {
        resolve(url);
        window.location = url;
      }
    });
  }
};
