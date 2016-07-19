Ext.namespace('mapfish.ux.widgets.print');

mapfish.ux.widgets.print.PrintAction = Ext.extend(mapfish.widgets.print.PrintAction, {

    zpPanel: null,

    /**
     * APIMethod: fillSpec
     * Add the page definitions and set the other parameters. To be implemented
     * by child classes.
     *
     * Parameters:
     * printCommand - {<mapfish.PrintProtocol>} The print definition to fill.
     */
    fillSpec: function(printCommand) {
        var params = printCommand.spec;
        var zp = this.zpPanel.zp.data;
        var extent = this.zpPanel.map.getExtent();
        params.pages.push({
            "mapTitle": 'Zone de prospection de '+zp.taxon_latin+ ' du '+zp.dateobs
            ,"bbox": extent.toBBOX().split(',')
            //"description": Ext.util.Format.stripTags(site.descriptionsite),
            ,observateurs: zp.observateurs
            ,nb_ap: zp.nb_ap
            ,aps: this.getAps()
            //bassins: this.getBassins(site.bassins),
        });
        params.layout = "A4 portrait";
    }
    ,getAps: function() {
        var store = this.zpPanel.apsStore;
        var records = [];
        store.each(function(record) {
            records.push({
                frequence: record.get('frequenceap')
                ,surface: record.get('surface')
                ,phenologie: record.get('phenologie')
                ,objets: record.get('objets')
                ,perturbations: record.get('perturbations')
                ,relue: record.get('validated') ? 'oui' : 'non'
            });
        });

        return  {
            "data": records,
            "columns": ['frequence', 'surface', 'phenologie', 'objets', 'perturbations', 'relue']
        }
    }
/*
    getZones: function(zones) {
      var c = '';
      for (i=0 ; i<zones.length ; i++) {
        c += zones[i].nomzone+', '
      }
      return c.substring(0, c.length-2);
    },

    getCommunes: function(communes) {
      var c = '';
      for (i=0 ; i<communes.length ; i++) {
        c += communes[i].commune+', '
      }
      return c.substring(0, c.length-2);
    },

    getBassins: function(bassins) {
      var c = '';
      for (i=0 ; i<bassins.length ; i++) {
        c += bassins[i].nomsite+', '
      }
      return c.substring(0, c.length-2);
    },

    getSecteurs: function(secteurs) {
      var c = '';
      for (i=0 ; i<secteurs.length ; i++) {
        c += secteurs[i].secteur+', '
      }
      return c.substring(0, c.length-2);
    },

    getElements: function() {
        var store = this.sitePanel.elementsStore;
        var records = [];
        store.each(function(record) {
            records.push({
                nomelement: record.get('nomelement'),
                categorie: record.get('categorie'),
                note: record.get('note'),
                justification: Ext.util.Format.stripTags(record.get('justification')),
                auteur: record.get('auteur'),
                actionencours: Ext.util.Format.stripTags(record.get('actionencours')),
                diffusion: !/Non/.test(record.get('diffusion')) ? 'oui' : 'non',
                validated: record.get('validated') ? 'oui' : 'non'
            });
        });

        return  {
            "data": records,
            "columns": ['nomelement', 'categorie', 'auteur', 'note', 'justification', 'actionencours', 'diffusion', 'validated' ]
        }
    },

    getProjects: function() {
        var store = this.sitePanel.projectsStore;
        var records = [];
        store.each(function(record) {
            records.push({
                intituleprojet: record.get('intituleprojet'),
                maitreouvrage: record.get('maitreouvrage'),
                contact: record.get('contact'),
                datedebut: record.get('datedebut'),
                datefin: record.get('datefin')
            });
        });

        return  {
            "data": records,
            "columns": ['intituleprojet', 'maitreouvrage', 'contact', 'datedebut', 'datefin']
        }
    },

    getLinkedSites: function() {
        var store = this.sitePanel.linksStore;
        var records = [];
        store.each(function(record) {
            records.push({
                nomsite: record.get('nomsite'),
                typelien: record.get('typelien'),
                nb_elem: record.get('nb_elem')
            });
        });

        return  {
            "data": records,
            "columns": ['nomsite', 'typelien', 'nb_elem']
        }
    }
*/

});
