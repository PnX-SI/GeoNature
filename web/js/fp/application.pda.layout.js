/**
 * @class application.viewport
 * Singleton to build the viewport (tab)
 *
 * @singleton
 */
application.layout = function() {
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

    /**
     * Method: getViewportNorthItem
     */
    var getViewportNorthItem = function() {
        return {
            region: 'north'
            ,el: 'north'
            ,height: 60
            // ,html:"Flore"
            ,cls: "application-header"
        }
    };

    /**
     * Method: getViewportSouthItem
     */
    var getViewportSouthItem = function() {
        return {
            region:"south"
            ,height:25
            ,bbar: new Ext.Toolbar({           
                items: ['&copy; Parc National des Ecrins', '->',
                application.user.nom+' ('+application.user.status+')',
                {
                    text: 'déconnexion'
                    ,iconCls: 'lock'
                    ,handler: function() {
                        window.location.href = 'deconnexion' 
                    }
                }]
            })
        }
    };

    /**
     * Method: getViewportCenterItem
     */
    var getViewportCenterItem = function() {
        tabPanel = new Ext.TabPanel({
            region: 'center'
            ,xtype:"tabpanel"
            ,activeTab: (application.user.indexzp) ? null : 0  
            ,items: [
                application.search.init()
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

            if (application.user.indexzp) {
                this.loadZp({indexzp: application.user.indexzp});    
            }
        }

        ,loadZp : function(zp){
            var id = 'zp-' + zp.data.indexzp;
            var tab = tabPanel.getComponent(id);
            if(tab){
                tabPanel.setActiveTab(tab);
            }else{
                var p = tabPanel.add(new application.zpPanel({
                    id: id
                    ,zp: zp
                }));
                tabPanel.setActiveTab(p);
            }
        }

        /**
        * Method: loadZp
        *
        * Shortcut method
        */
        ,loadZpTab: function(indexzp) {
          application.layout.loadZp({indexzp: indexzp});
        }

    }
}();
