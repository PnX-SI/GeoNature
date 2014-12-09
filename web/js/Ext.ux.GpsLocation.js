/**
 * @class Ext.ux.Toast
 * Fenêtre pour le positionnement par gsp 
 * Gil DELUERMOZ 2014
 * @singleton
 */
Ext.ux.GpsLocation = function() {

    // var userProjection = new OpenLayers.Projection("EPSG:32622"); // si besoin de définition manuelle dans ce fichier
    // variables définies dans le config.js
    var userProjection = gps_user_projection; 
    var fuseau = fuseauUTM;
    var xmin = x_min;
    var xmax = x_max;
    var ymin = y_min;
    var ymax = y_max;
    var xex = x_exemple;
    var yex = y_exemple;
    var pnNameLong = pn_name_long;
    
    var submitFormGps = function(layer, zone, longitude, latitude, mapProjection, userProjection) {
        if(Ext.getCmp('form-gps-fiche').getForm().isValid()){
            // création du point et reprojection grace à proj4js;
            //j'ai du télécharger et ajouter le répertoire de la lib pro4js 
            //puis créer EPSG32622.js dans un répertoire defs
            //Les 2 projections nécessaires pour le transform sont définies au moment de la création de la fenêtre GSP sinon il y a un pb de timeout et la reprojection n'a pas le temps de se faire ???
            var features = [];
            var projSource = userProjection;
            // alert ('le temps d\'initialisation des projections ou de proj4 ???');
            var mageometry = new OpenLayers.Geometry.Point(longitude, latitude);
            OpenLayers.Projection.transform(mageometry,projSource,mapProjection);
            var mafeature = new OpenLayers.Feature.Vector(mageometry);
            features.push(mafeature);
            map.setCenter(new OpenLayers.LonLat(mageometry.x, mageometry.y),15); //on centre et on zoome avant d'ajouter le point sinon ajout impossible si echelle de zoom insuffisante voir events.on('featureadded'...
            layer.addFeatures(features);
            layer.redraw();
            Ext.getCmp('window-gps').destroy();
        }
        else{
            Ext.Msg.alert('Attention', 'Une information est mal saisie ou n\'est pas valide.</br>Vous devez la corriger avant de poursuivre.');
        }
    };
    
    return{
        initGpsWindow : function(layer) {
            var mapProjection = map.getProjectionObject();
                        
            return new Ext.Window({
                id:'window-gps'
                ,layout:'border'
                ,height:250
                ,width: 400
                ,closeAction:'hide'
                ,autoScroll:true
                ,modal: true
                ,plain: true
                ,split: true
                ,buttons: [{
                    text:'Positionner'
                    ,id:'gps-afficher-button'
                    ,handler: function(){
                        var zone, longitude, latitude;
                        zone = Ext.getCmp('gps-fiche-zone').getValue();
                        longitude = Ext.getCmp('gps-fiche-longitude').getValue();
                        latitude = Ext.getCmp('gps-fiche-latitude').getValue();
                        submitFormGps(layer,zone, longitude, latitude, mapProjection, userProjection);   
                    }
                },{
                    text: 'Annuler et fermer'
                    ,handler: function(){
                        Ext.getCmp('window-gps').destroy();
                        Ext.ux.Toast.msg('Annulation !', 'Aucun point n\'a été positionné.');
                    }
                }]
                ,items: [{
                    id:'form-gps-fiche'
                    ,xtype: 'form'
                    ,title: 'Positionnement d\'un point à partir de coordonnées UTM'
                    ,region: 'center'
                    ,labelWidth: 100 // label settings here cascade unless overridden
                    ,frame:true
                    ,border:false
                    ,split: false
                    ,autoScroll:false
                    ,monitorValid:true
                    ,bodyStyle:'padding:5px 5px 0'
                    ,width: 350
                    ,defaultType: 'numberfield'
                    ,items: [{
                        id: 'gps-fiche-zone'
                        ,xtype: 'numberfield'
                        ,allowDecimals :false
                        ,allowNegative: false
                        ,fieldLabel: 'Fuseau '+fuseau
                        ,allowBlank:false
                        ,enableKeyEvents:true
                        // ,minValue:22
                        // ,minText:'Ce fuseau n\'est pas valide. Fuseau = 22'
                        // ,maxText:'Ce fuseau n\'est pas valide. Fuseau = 22'
                        // ,maxValue:22
                        ,value:fuseau
                        ,blankText: 'Le fuseau est obligatoire. Ce doit être le fuseau '+fuseau+'.'
                        ,name: 'zone'
                        ,width: 150
                    },{
                        id: 'gps-fiche-longitude'
                        ,xtype: 'numberfield'
                        ,allowDecimals :false
                        ,allowNegative: false
                        ,disabled:false
                        ,fieldLabel: 'X '
                        ,minValue:xmin
                        ,minText:'Cette coordonnées en x n\'est pas valide pour l\'emprise de la carte. Elle doit être supérieure à '+xmin+'.'
                        ,maxValue:xmax
                        ,maxText:'Cette coordonnées en x n\'est pas valide pour l\'emprise de la carte. Elle doit être inférieure à '+xmax+'.'
                        ,allowBlank:false
                        ,blankText: 'La coordonnées en x est obligatoire. Ce doit être un nombre entier négatif entre '+xmin+' et '+xmax+'; coordonnées UTM en mètre'
                        ,name: 'longitude'
                        ,width: 150
                    },{
                        id: 'gps-fiche-latitude'
                        ,xtype: 'numberfield'
                        ,allowDecimals :false
                        ,allowNegative: false
                        ,disabled:false
                        ,fieldLabel: 'Y '
                        ,minValue:230000
                        ,minText:'Cette coordonnées en y n\'est pas valide pour l\'emprise de la carte. Elle doit être supérieure à '+ymin+'. (fuseau '+fuseau+').'
                        ,maxValue:655000
                        ,maxText:'Cette coordonnées en y n\'est pas valide pour l\'emprise de la carte. Elle doit être inférieure à '+ymax+'. (fuseau '+fuseau+').'
                        ,allowBlank:false
                        ,blankText: 'La coordonnées en y est obligatoire. Ce doit être un nombre entier positif entre '+ymin+' et '+ymax+'; coordonnées UTM en mètre'
                        ,name: 'latitude'
                        ,width: 150
                    }
                    ]
                    ,listeners: {
                        clientvalidation:function(form,valid){
                            if(valid){Ext.getCmp('gps-afficher-button').enable();}
                            else{Ext.getCmp('gps-afficher-button').disable();}
                        }
                    }
                },{
                    id:'panel-export-evenement'
                    ,xtype: 'panel'
                    ,region: 'south'
                    ,frame:true
                    ,border:false
                    ,split: false
                    ,autoScroll:false
                    ,bodyStyle:'padding:5px 5px 0'
                    ,width: 350
                    ,html: 'Les coordonnés doivent être en UTM. </br>Fuseau '+fuseau+' uniquement pour le '+pnNameLong+'.</br>Exemple : Fuseau : '+fuseau+' -  X : '+xex+'   Y : '+yex+''
                }]
                ,listeners: {
                    hide:function(){this.destroy();}
                } 
            });
        }
    }
}();