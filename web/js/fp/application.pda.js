// reference local blank image
Ext.BLANK_IMAGE_URL = 'js/client/mfbase/ext-3.3.1/resources/images/default/s.gif';

Ext.namespace("application");

application = function() {

    return {
          
        /**
         * APIProperty: user
         * Current user
         */
        user: {
            nom: null
            ,status: null
            ,id_organisme: null
        }

        ,checklog:function(){
            Ext.getCmp('zp_list_grid').loadMask.hide();
            if(Ext.getCmp('ap_list_grid')){
                Ext.getCmp('ap_list_grid').loadMask.hide();
            }
            Ext.Msg.show({
                title:'Attention'
                ,msg:'Votre session a expiré, vous devez vous reconnecter.<br/>Si vous venez d\'effectuer une action, elle n\'a pas été réalisée.'
                ,buttons:Ext.Msg.OK
                ,fn:function(btn){
                    if(btn=='ok'){window.location.reload();}
                }
            });
        }
        ,ziva: function() {
            OpenLayers.Lang.setCode('fr');
            //get current user status
            Ext.Ajax.request({
                url: 'getstatus'
                ,success: function(request) {
                    this.user = Ext.decode(request.responseText);
                    // init the layout only when we get the user status
                    this.layout.init();
                }
                ,failure: function() {
                    Ext.Msg.alert('Attention',"Un problème à été rencontré.");
                }
                ,scope: this
                ,synchronous: true
            });
        }
        ,init:function(){
            // on attend que les classes soient chargées
             if (typeof(OpenLayers)==='undefined' || typeof(Geoportal)==='undefined') {
                setTimeout('application.init();',300);
                return;
            }
            // on charge la configuration de la clef API, puis on charge l'application
            Geoportal.GeoRMHandler.getConfig([ign_api_key], null,null, {
                onContractsComplete: this.ziva()
            });
        }
        ,initDesktop: function() {
            OpenLayers.Lang.setCode('fr');
            //get current user status
            Ext.Ajax.request({
                url: 'getStatus'
                ,success: function(request) {
                    this.user = Ext.decode(request.responseText);
                    // init the layout only when we get the user status
                    this.layout.getViewportCenterItem();
                }
                ,failure: function() {
                    Ext.Msg.alert('Attention',"Un problème à été rencontré.");
                }
                ,scope: this
                ,synchronous: true
            });
        }

        ,auteursStore: new Ext.data.JsonStore({
            url: 'bibs/observateurs'
            ,fields: [
                'id_role'
                ,'auteur'
            ],
            sortInfo: {
                field: 'auteur',
                direction: 'ASC'
            }
            ,autoLoad: true
        })
        
        ,auteursStorePda: new Ext.data.JsonStore({
            url: 'bibs/filtreobservateurspda'
            ,fields: [
                'id_role'
                ,'auteur'
            ],
            sortInfo: {
                field: 'auteur',
                direction: 'ASC'
            }
            ,autoLoad: true
        })

        ,taxonsLStore: new Ext.data.JsonStore({
            url: 'bibs/listlpda'
            ,fields: [
                'cd_nom'
                ,'latin'
            ],
            sortInfo: {
                field: 'latin',
                direction: 'ASC'
            }
            ,autoLoad: true
        })       

        ,taxonsFStore: new Ext.data.JsonStore({
            url: 'bibs/listfpda'
            ,fields: [
                'cd_nom'
                ,'francais'
            ],
            sortInfo: {
                field: 'francais',
                direction: 'ASC'
            }
            ,autoLoad: true
        }) 
        
        ,anneeStore: new Ext.data.JsonStore({
            url: 'bibs/listannee'
            ,fields: [
                'annee'
            ],
            sortInfo: {
                field: 'annee',
                direction: 'ASC'
            }
            ,autoLoad: true
        })
        ,secteurCbnaStore: new Ext.data.JsonStore({
            url: 'bibs/secteurscbna'
            ,fields: [
                'id_secteur'
                ,'nom_secteur'
                ,'extent'
            ]
            ,sortInfo: {
                field: 'nom_secteur'
                ,direction: 'ASC'
            }
            ,autoLoad: true
        })
        ,organismeStore: new Ext.data.JsonStore({
            url: 'bibs/organismes'
            ,fields: [
                'id_organisme'
                ,'nom_organisme'
            ]
            ,sortInfo: {
                field: 'nom_organisme'
                ,direction: 'ASC'
            }
            ,autoLoad: true
        })
        ,communeCbnaStore: new Ext.data.JsonStore({
            url:'bibs/communescbna'
            ,sortInfo: {
                field: 'nomcommune'
                ,direction: 'ASC'
            }
            ,fields: [
                'insee'
                ,'nomcommune'
                ,'extent'
            ]
            ,autoLoad: true
        })


        /**
         * APIMethod:
         * Helper to create a map since all the map have many layers and option in common
         * It will be easier to configure in one place only
         */
        ,createMap: function() {
            var map;
            // var epsg4171= new OpenLayers.Projection("EPSG:4171");
            // var ignfxx= new OpenLayers.Projection("IGNF:GEOPORTALFXX");
            // var epsg310024001= new OpenLayers.Projection("EPSG:310024001");

             /**
             * Function: setGeoRM
             * Assign Geoportal's GeoRM token to an Object.
             *
             * Returns:
             * {Object} the rightsManagement key
             */
            function setGeoRM() {
                return Geoportal.GeoRMHandler.addKey(
                    gGEOPORTALRIGHTSMANAGEMENT.apiKey,
                    gGEOPORTALRIGHTSMANAGEMENT[gGEOPORTALRIGHTSMANAGEMENT.apiKey[0]].tokenServer.url,
                    gGEOPORTALRIGHTSMANAGEMENT[gGEOPORTALRIGHTSMANAGEMENT.apiKey[0]].tokenServer.ttl,
                    map);
            }
            function createIgnLayer(couche,opacite,LayerBase,extentMax){
                couche.options.opacity = opacite;
                couche.options.isBaseLayer = LayerBase;
                couche.options.maxExtent = extentMax;
                // couche.options.projection = epsg310024001;
                couche.options["GeoRM"] = setGeoRM();
                couche.transitionEffect= 'resize';
                var ignLayer = new couche.classLayer(
                    OpenLayers.i18n(couche.options.name),
                    couche.url,
                    couche.params,
                    couche.options);
                return ignLayer
            };
            
            var id = Ext.id();
            Ext.DomHelper.append(Ext.getBody(), {tag: 'div', cn: {tag: 'div', id: id}, style:'visibility: hidden'});
            map = new OpenLayers.Map(id 
                ,OpenLayers.Util.extend({
                    maxResolution: resolution_max
                    ,numZoomLevels: num_zoom_levels
                    ,projection: 'EPSG:310024001'
                    // ,displayProjection:epsg4171
                    ,units: 'meters'
                    ,maxExtent: extent_max
                    ,controls:[
                        new Geoportal.Control.TermsOfService()
                        ,new Geoportal.Control.PermanentLogo()
                        ,new OpenLayers.Control.ScaleLine()
                        ,new OpenLayers.Control.MousePosition({
                            prefix: "Lambert 93 : x = "
                            ,suffix: " m"
                            ,separator: " m, y = "
                            ,displayProjection: new OpenLayers.Projection("IGNF:LAMB93")
                            ,numDigits: 0
                            ,emptyString: ''
                        })
                        ,new OpenLayers.Control.KeyboardDefaults()
                        ,new OpenLayers.Control.Attribution()
                        ,new OpenLayers.Control.Navigation()
                    ]
                }
                ,gGEOPORTALRIGHTSMANAGEMENT)
            );
            maMap = map;//debug
            // get IGNF's catalogue :
            var cat = new Geoportal.Catalogue(map,gGEOPORTALRIGHTSMANAGEMENT);
            var zon = cat.getTerritory('EUE');
            // get Geoportail layer's parameters :
            var scanOpts= cat.getLayerParameters(zon, 'GEOGRAPHICALGRIDSYSTEMS.MAPS:WMSC');
            var orthoOpts= cat.getLayerParameters(zon, 'ORTHOIMAGERY.ORTHOPHOTOS:WMSC');
            var cadastreOpts= cat.getLayerParameters(zon, 'CADASTRALPARCELS.PARCELS:WMSC');
            var etatmajorOpts= cat.getLayerParameters(zon, 'GEOGRAPHICALGRIDSYSTEMS.ETATMAJOR40:WMSC');
            //create layers
            var scan = createIgnLayer(scanOpts,1.0,true,extent_max);
            var ortho = createIgnLayer(orthoOpts,1.0,false,extent_max);
            var cadastre = createIgnLayer(cadastreOpts,null,false,extent_max);
            var etatmajor = createIgnLayer(etatmajorOpts,1.0,false,extent_max);
            // scanOpts.options.projection = new OpenLayers.Projection("EPSG:310024001");
            // reproject maxExtent (Geoportal's API standard and extended do it automagically :
            // scanOpts.options.maxExtent.transform(scanOpts.options.projection, map.getProjection(), true);
            // add it to the map :
            map.addLayers([scan,ortho,cadastre,etatmajor]);
 
            var overlay = new OpenLayers.Layer.WMS("overlay"
                ,wms_uri
                ,{
                    layers: [
                      'zones2', 'zones3', 'zones4', 'zones5',
                      'zones6', 'zones8', 'zones9',
                      'zones10', 'zones11', 'zones12',
                      'ap', 'zp_pasrelue', 'zp_relue', 'secteurs', 'communescbna', 'zp_Selected'
                    ]
                    ,transparent: true
                    ,projection:'EPSG:310024001'
                    ,units: 'meters'
                    ,maxResolution: resolution_max
                    ,maxExtent: extent_max
                    // ,version: '1.3.0'
                    ,statuscode: application.user.statuscode
                    ,indexzp: 0
                }
                ,{singleTile: true}
            );
            map.addLayers([overlay]);
            
            return map;
        }
    }
}();
//correction d'un bug sur le destroy() des onglets des stations ; à cause des rowaction dans les grilles...
Ext.namespace("application.utils");
Ext.override(Ext.ux.grid.RowActions, {
  destroy: Ext.emptyFn
});
//fonction permettant de masquer un champ avec son label.
Ext.override(Ext.form.Field, {
    hideItem: function(){
            this.hide();
            if(this.label){
                this.label.setDisplayed(false);
            }
    }
    ,showItem: function(){
            this.show();
            if(this.label){
                this.label.setDisplayed(true);
            }
    }
    ,setFieldLabel: function(text) {
        if (this.getForm(this)) {
            var label = this.getForm(this).first('label.x-form-item-label');
            label.update(text);
        }
    }
    ,getForm: function() {
        return this.el.findParent('.x-form-item', 3, true);
    }
});
// Ext.namespace("application.utils");
/**
 * Method: manageDisplayField
 * show or hide item and field and disable it
 */
application.utils.manageDisplayField = function(id,mode){
    if(mode=='hide'){
        Ext.getCmp(id).hide();
        Ext.getCmp(id).hideItem();
        Ext.getCmp(id).disable();
    }
    if(mode=='show'){
        Ext.getCmp(id).show();
        Ext.getCmp(id).showItem();
        Ext.getCmp(id).enable();
    }
};
/**
 * Method: addSeparator
 * toolbar seperator creator helper
 */
application.utils.addSeparator = function(toolbar) {
    toolbar.add(new Ext.Toolbar.Spacer());
    toolbar.add(new Ext.Toolbar.Separator());
    toolbar.add(new Ext.Toolbar.Spacer());
};
