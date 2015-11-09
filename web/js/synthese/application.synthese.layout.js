/**
 * @class application.synthese.viewport
 * Singleton to build the viewport (tab)
 *
 * @singleton
 */
application.synthese.layout = function() {
    // private variables
    var tabPanel = null;
    // private functions


    /**
     * Method: initViewport
     */
    var initViewport = function() {
        var viewport = new Ext.Viewport({
            layout: 'border'
            ,defaults: {
                border: false
            }
            ,items:[
                getViewportNorthItem()
                ,getViewportSouthItem()
                ,getViewportCenterItem()
            ]
        });
    };
    // var accueilBoutonPanel = new Ext.Panel({ 
		// id: 'bouton-bandeau-panel'
		// ,region:'east'
		// ,bodyStyle: 'background: transparent'
		// ,border:false
		// ,layout : 'fit'
		// ,width:150
       // ,html	:'<div class="btbandeau"><a class="btbandeau" href="deconnexion" title="Se déconnecter et retourner au formulaire d\'identification"><img src="images/deconnexion.png" border=no></a><a class="btbandeau" href="/"+app_uri+"" title="Retourner à la page d\'accueil"><img src="images/home.png" border=no></a></div>'
	// });
    var titleAppliPanel = new Ext.Panel({
		region : 'center'
		,bodyStyle: 'background: transparent'
        ,layout : 'fit'
		,border:false
		,height: 60
    });
    
    /**
     * Method: getViewportNorthItem
     */
    var getViewportNorthItem = function() {
        return {
            region: 'north'
            ,el: 'north'
            ,height: 60
            ,layout : 'border'
            ,bodyCssClass: 'application-cf-header'
            ,items:[titleAppliPanel]
            // ,items:[accueilBoutonPanel,titleAppliPanel]
        };
    };
    
    /**
     * Method: getViewportSouthItem
     */
    var getViewportSouthItem = function() {
        return {
            region:"south"
            ,height:25
            ,bbar: new Ext.Toolbar({           
                items: ['&copy; <a href="https://github.com/PnEcrins/GeoNature/" target="_blank">GeoNature</a>, développé par le <a href="http://www.ecrins-parcnational.fr" target="_blank">Parc national des Ecrins</a>', '->',
                application.synthese.user.nom+' ('+application.synthese.user.status+')',
                {
                    text: 'Déconnexion'
                    ,iconCls: 'logout'
                    ,handler: function() {
                        window.location.href = 'deconnexion';
                    }
                },{
                    text: 'Accueil'
                    ,iconCls: 'home_mini'
                    ,handler: function() {
                        window.location.href = '/'+app_uri;
                    }
                }]
            })
        };
    };

    /**
     * Method: getViewportCenterItem
     */
    // var getViewportCenterItem = function() {
        // panel = new Ext.Panel({
            // region: 'center'
            // ,xtype:"panel"
            // ,defaults: {
                // border: false
            // } 
            // ,items: [
                // application.synthese.search.init()
            // ]
        // });
        // return panel;
    // };
    var getViewportCenterItem = function() {
        tabPanel = new Ext.TabPanel({
            region: 'center'
            ,xtype:"tabpanel"
            ,activeTab: 0  
            ,items: [
                application.synthese.search.init()
            ]
        });
        return tabPanel;
    };

    // public space
    return {
        tabPanel: null

        ,init: function() {
            initViewport();
            this.tabPanel = tabPanel;
        }
    };
}();