// Ext.Compat.showErrors = true;
// reference local blank image
Ext.BLANK_IMAGE_URL = 'js/client/mfbase/ext-3.4.0/resources/images/default/s.gif';
Ext.namespace("application.cf");
if (window.__Geoportal$timer===undefined) {
    var __Geoportal$timer= null;
}
/**
 * Function: checkApiLoading
 * Assess that needed classes have been loaded.
 *
 * Parameters:
 * retryClbk - {Function} function to call if any of the expected classes
 * is missing.
 * clss - {Array({String})} list of classes to check.
 *
 * Returns:
 * {Boolean} true when all needed classes have been loaded, false otherwise.
 */
function checkApiLoading(retryClbk,clss) {
    if (__Geoportal$timer!=null) {
        //clearTimeout: annule le minuteur "__Geoportal$timer" avant sa fin
        window.clearTimeout(__Geoportal$timer);
         __Geoportal$timer= null;
    }
    /**
    * Il se peut que l'init soit exécuté avant que l'API ne soit chargée
    * Ajout d'un code temporisateur qui attend 300 ms avant de relancer l'init
    */
    var f;
    for (var i=0, l= clss.length; i<l; i++) {
        try {f= eval(clss[i]);} 
        catch (e) {f= undefined;}
        if (typeof(f)==='undefined') {
             __Geoportal$timer= window.setTimeout(retryClbk, 300);
            return false;
        }
    }
    return true;
}
/**
  * tester la disponibilité des layers de la map
*/
var layerTester = new Ext.util.Observable();
var firstMapLoad = true;

application.cf = function() {
    /**
    * Property: formatWKT
    */
    var formatWKT = new OpenLayers.Format.WKT();
    
    /**
    * Property: map
    */
    var map = null;
    return {

        /**
         * APIProperty: user
         * Current user
         */
        user: {
            nom: null
            ,id_utilisateur:null
            ,status: null
            ,statuscode:null
            ,id_secteur:null
            ,nom_secteur:null
            ,email:null
        }
        /*,checklog:function(){
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
        }*/
        ,ziva: function(monprotocole) {
            OpenLayers.Lang.setCode('fr');
            //get current user status
            Ext.Ajax.request({
                url: 'getstatus'
                ,success: function(request) {
                    this.user = Ext.decode(request.responseText);
                    // init the layout only when we get the user status
                    if(monprotocole=='cf'){application.cf.editFiche.loadFiche(null,'add',null);}
                    if(monprotocole=='mortalite'){application.cf.editFicheMortalite.loadFiche(null,'add',null);}
                }
                ,failure: function() {
                    Ext.Msg.alert('Attention',"Un problème à été rencontré.");
                }
                ,scope: this
                ,synchronous: true
            });
        }
        ,init:function(monprotocole){
            // on attend que les classes soient chargées
            if (checkApiLoading('application.cf.init('+monprotocole+');',['OpenLayers','Geoportal','Geoportal.Catalogue'])===false) {
                return;
            }
            // on charge la configuration de la clef API, puis on charge l'application
            Geoportal.GeoRMHandler.getConfig([ign_api_key], null,null, {
                onContractsComplete: this.ziva(monprotocole)
            });
        } 
        ,storeObservateursCfAdd: new Ext.data.JsonStore({
            url: 'bibs/observateurscfadd'
            ,fields: [
                'id_role'
                ,{name:'auteur',sortType: Ext.data.SortTypes.asAccentuatedString}
            ]
            ,sortInfo: {
                field: 'auteur'
                ,direction: 'ASC'
            }
            ,autoLoad:true
        })
       

        /**
         * APIMethod:
         * Helper to create a map since all the map have many layers and option in common
         * It will be easier to configure in one place only
         */
        ,createMap: function() {
            var map;
            var wm= new OpenLayers.Projection("EPSG:3857");
            var epsg4326= new OpenLayers.Projection("EPSG:4326");
            
            var id = Ext.id();
            Ext.DomHelper.append(Ext.getBody(), {tag: 'div', cn: {tag: 'div', id: id}, style:'visibility: hidden'});
            map = new OpenLayers.Map(id 
                ,{
                    projection: wm
                    ,units: wm.getUnits()
                    ,resolutions: ign_resolutions
                    ,maxResolution: resolution_max
                    ,maxExtent: extent_max
                    ,units: wm.getUnits()
                    ,controls:[
                        new Geoportal.Control.TermsOfService()
                        ,new Geoportal.Control.PermanentLogo()
                        ,new OpenLayers.Control.ScaleLine()
                        ,new OpenLayers.Control.MousePosition({
                            // prefix: "Lambert 93 : x = "
                            suffix: " m"
                            ,separator: " m, y = "
                            // ,displayProjection: new OpenLayers.Projection("IGNF:LAMB93")
                            ,numDigits: 0
                            ,emptyString: ''
                        })
                        ,new OpenLayers.Control.KeyboardDefaults()
                        ,new OpenLayers.Control.Attribution()
                        ,new OpenLayers.Control.Navigation()
                    ]
                }
            );
            maMap = map;//debug
            layerTester.addEvents('mapReady');
            layerTester.addEvents('ignReady');
            
            var createOrthoLayer = function() {
                var matrixIds3857= new Array(22);
                for (var i= 0; i<22; i++) {
                    matrixIds3857[i]= {
                        identifier    : "" + i,
                        topLeftCorner : new OpenLayers.LonLat(-20037508,20037508)
                    };
                }
                var l0= new Geoportal.Layer.WMTS(
                        'Ortho-imagerie',
                        'http://gpp3-wxs.ign.fr/'+ign_api_key+'/geoportail/wmts',
                        {
                          layer: 'ORTHOIMAGERY.ORTHOPHOTOS',
                          style: 'normal',
                          matrixSet: "PM",
                          matrixIds: matrixIds3857,
                          format:'image/jpeg',
                          exceptions:"text/xml"
                        },
                        {
                          tileOrigin: new OpenLayers.LonLat(0,0),
                          isBaseLayer: false,
                          // resolutions: Geoportal.Catalogue.RESOLUTIONS.slice(0,20),
                          maxResolution: resolution_max,
                          alwaysInRange: false,
                          opacity : 1,
                          projection: wm,
                          maxExtent: extent_max,
                          units: wm.getUnits(),
                          attribution: 'provided by IGN'
                        }
                      );
                      map.addLayer(l0);
            };
            createOrthoLayer();
            var createCadastralLayer = function() {
                var matrixIds3857= new Array(22);
                for (var i= 0; i<22; i++) {
                    matrixIds3857[i]= {
                        identifier    : "" + i,
                        topLeftCorner : new OpenLayers.LonLat(-20037508,20037508)
                    };
                }
                var l0= new Geoportal.Layer.WMTS(
                        'Parcelles cadastrales',
                        'http://gpp3-wxs.ign.fr/'+ign_api_key+'/geoportail/wmts',
                        {
                          layer: 'CADASTRALPARCELS.PARCELS',
                          style: 'bdparcellaire_o',
                          matrixSet: "PM",
                          matrixIds: matrixIds3857,
                          format:'image/png',
                          exceptions:"text/xml"
                        },
                        {
                          tileOrigin: new OpenLayers.LonLat(0,0),
                          isBaseLayer: false,
                          maxResolution: resolution_max,
                          alwaysInRange: false,
                          projection: wm,
                          maxExtent: extent_max,
                          units: wm.getUnits(),
                          attribution: 'provided by IGN'
                        }
                      );
                      map.addLayer(l0);
            };
            createCadastralLayer();
            var createBaseLayer = function() {
                var matrixIds3857= new Array(22);
                for (var i= 0; i<22; i++) {
                    matrixIds3857[i]= {
                        identifier    : "" + i,
                        topLeftCorner : new OpenLayers.LonLat(-20037508,20037508)
                    };
                }
                var l0= new Geoportal.Layer.WMTS(
                        'Cartes ign',
                        'http://gpp3-wxs.ign.fr/'+ign_api_key+'/geoportail/wmts',
                        {
                          layer: 'GEOGRAPHICALGRIDSYSTEMS.MAPS',
                          style: 'normal',
                          matrixSet: "PM",
                          matrixIds: matrixIds3857,
                          format:'image/jpeg',
                          exceptions:"text/xml"
                        },
                        {
                          tileOrigin: new OpenLayers.LonLat(0,0),
                          isBaseLayer: true,
                          // resolutions: Geoportal.Catalogue.RESOLUTIONS.slice(0,20),
                          maxResolution: resolution_max,
                          alwaysInRange: true,
                          opacity : 1,
                          projection: wm,
                          maxExtent: extent_max,
                          units: wm.getUnits(),
                          attribution: 'provided by IGN'
                        }
                      );
                    map.addLayer(l0);
                    l0.events.on({
                        loadend:function() {
                            layerTester.fireEvent('ignReady');
                        }
                    });
            };
            createBaseLayer();

            var overlay = new OpenLayers.Layer.WMS("overlay",
                wms_uri
                ,{
                    layers: [
                      'znieff2', 'znieff1', 'aoa', 'secteurs', 'coeur', 'communes'
                      ,'ab','n2000','reservesnationales', 'reservesregionales'
                      ,'unitesgeo','reservesintegrales', 'reserveschasse'
                      // ,'sitesinscrits', 'sitesclasses'
                    ]
                    ,transparent: true
                    ,projection: wm
                    ,units: 'meters'
                    ,maxResolution: resolution_max
                    ,maxExtent: extent_max
                    ,statuscode: application.cf.user.statuscode
                }
                ,{singleTile: true}
            );
            map.addLayers([overlay]);
            layerTester.fireEvent('overlayReady');
            
            this.searchVectorLayer = new OpenLayers.Layer.Vector('search_vector_layer', {
                style: {
                  fillColor: "#000000"
                  ,strokeColor: "#ff0000"
                  ,cursor: "pointer"
                  ,fillOpacity: 0.1
                  ,strokeOpacity: 1
                  ,strokeWidth: 2
                  ,pointRadius: 8
                }
                ,styleMap: new OpenLayers.StyleMap({
                  temporary: new OpenLayers.Style({
                    strokeWidth: 2
                    ,strokeColor: "#ffa500"
                    ,fillOpacity: 0.2
                  })
                })
              });
            map.addLayers([this.searchVectorLayer]);
            
            this.selectFeatureControl = new OpenLayers.Control.SelectFeature(this.searchVectorLayer, {});
            map.addControl(this.selectFeatureControl);
            this.selectFeatureControl.activate();
            layerTester.on('ignReady',function(){
                if(firstMapLoad){
                    map.zoomToMaxExtent();
                    //--------Code Atol CD - Nicolas Chevobbe-----------
                    Ext.get('loading').fadeOut({
                        remove: true
                    });
                    //Et on essaye de localiser l'utilisateur
                    navigator.geolocation.getCurrentPosition(function(position) {
                        //On va se centrer sur la localisation de l'utilisateur
                        var lonLat = new OpenLayers.LonLat(position.coords.longitude, position.coords.latitude).transform(new OpenLayers.Projection("EPSG:4326"), map.getProjectionObject());
                        map.setCenter(lonLat, 10);

                    }
                    ,function(error) {
                        Ext.ux.Toast.msg('Erreur', 'Le navigateur n\'a pas pu vous géolocaliser');
                    } 
                    ,{
                        enableHighAccuracy : true
                        ,maximumAge : 600000
                        ,timeout : 27000
                    });
                    //--------Fin du code Atol CD - Nicolas Chevobbe-----------
                }
                firstMapLoad = false;
            });
            layerTester.fireEvent('mapReady');
            map.setCenter(centre_map, 9);
            //rendre possible la saisie des caractère + et - qui sont sinon dédiés à la navigation dans la carte
            map.events.on(
                {"mouseover":function(control){map.getControlsByClass('OpenLayers.Control.KeyboardDefaults')[0].activate();}
                ,"mouseout":function(control){map.getControlsByClass('OpenLayers.Control.KeyboardDefaults')[0].deactivate();}
            });
            return map;
        }
        ,getFeature: function(geom) {
            var v = application.cf.searchVectorLayer;
                //s'il n'y a pas de zonne de dessinée, on prend celle de l'emprise de la carte
                // alert(v.features.length);
                if (v.features.length<=0) {
                    // alert(v.features.length);
                    // var geom = map.getExtent().toGeometry();
                    var f = new OpenLayers.Feature.Vector(geom);
                    v.addFeatures([f]);
                }
            return v.features[0];
        }
        ,getFeatureWKT: function(geom) {
          return formatWKT.write(this.getFeature(geom));
        }
    }
}();


Ext.namespace("application.cf.utils");
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
// ajout d'une ligne pointilée <hr>
Ext.ns("Gil.ux");
        Gil.ux.line = Ext.extend(Ext.Component, {
          autoEl: 'hr'
          ,cls : 'hrdashed'
        });
Ext.reg('line', Gil.ux.line);


/**
 * Method: addSeparator
 * toolbar seperator creator helper
 */
application.cf.utils.addSeparator = function(toolbar) {
    toolbar.add(new Ext.Toolbar.Spacer());
    toolbar.add(new Ext.Toolbar.Separator());
    toolbar.add(new Ext.Toolbar.Spacer());
};
