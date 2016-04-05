<body>
<div id="home">
    
    <div class="jumbotron">
        <div id="bandeau_accueil"></div>
        <h1 id="home_title" ><small class="text-muted"><?php echo sfGeonatureConfig::$apptitle_main; ?></small></h1>
    </div>
    <div id="accueil" class="container">

        <h2>SYNTHÈSE</h2>
            <p>Pour consulter la synthèse des observations faune et flore, tous protocoles confondus.</p>
            <p class="ligne_lien">
                 <a href="synthese" class="btn btn-default"><img src="images/pictos/oiseau.gif">Synthèse des observations</a>
            </p>
            <div id="interligne50"></div>
            
        <h2>PROTOCOLES</h2>
            <p>
                Pour saisir de nouvelles données, vous pouvez utiliser l'un des liens ci-dessous.<br/>
                Pour modifier des données saisies à l'aide d'un des formulaires proposés en lien ci-dessous, vous devez passer par la synthèse pour retrouver les enregistrements à modifier.
            </p>
            <p>
                <?php echo $liens_saisie;?>
            </p>
        <?php if(sfGeonatureConfig::$show_statistiques){ ?>
        <h2>STATISTIQUES</h3>
            <div class="row" style="border:1px solid #ddd;">
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Règnes</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="kd-chart" style="height: 250px;" ></div>
                </div>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Classes</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="cl-chart" style="height: 250px;" ></div>
                </div>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Observations par années</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="year-chart" style="height: 250px;" ></div>
                </div>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Contact faune vertébrée</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="cf-chart" style="height: 250px;" ></div>
                </div>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Contact faune invertébrée</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="inv-chart" style="height: 250px;" ></div>
                </div>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Contact flore</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="cflore-chart" style="height: 250px;" ></div>
                </div>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Flore station</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="fs-chart" style="height: 250px;" ></div>
                </div>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Flore prioritaire</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="fp-chart" style="height: 250px;" ></div>
                </div>
            </div>
        <?php } ?>
        <footer>
            <h5>
            <small>
                <a href="https://github.com/PnEcrins/GeoNature/" target="_blank">GeoNature</a>
                , développé par le 
                <a href="http://www.ecrins-parcnational.fr" target="_blank">
                Parc national des Ecrins </a>
                - Basé sur Taxref <?php echo sfGeonatureConfig::$taxref_version; ?>
            </small>
            <a class="pull-right" href="deconnexion"><img src="images/logout.gif" title="Déconnexion"/></a>
            </h5>
        </footer>
        
    </div>
</div>
<script>
var constructDatas = function(arr) {
    var datas = [];
    var item;
    for(var i=0; i<arr.length ; i++){
        if(arr[i][0] !=null){
            item = {value: arr[i][1], label: arr[i][0]};
            datas.push(item);
        }
    }
    return datas;
};
var constructDonuts = function(datas,div) {
    return new Morris.Donut({
        element: div
        ,data: datas
        ,backgroundColor: '#ccc'
        ,labelColor: '#666699'
        ,colors:['#f2e5ff','#e5ccff','#d9b3ff','#cc99ff','#bf80ff','#bf80ff','#b266ff','#a64dff','#9933ff','#8c1aff','#7f00ff','#7300e6','#6600cc','#5900b3','#4c0099','#400080','#330066','#26004d','#190033','#0d001a']
        ,formatter: function (x) { return x }
    });
};

var constructBars = function(datas,div) {
    return new Morris.Bar({
    element: div,
    data:datas,
    xkey: 'annee',
    ykeys: ['nb'],
    labels: ['nombre d\'observations'],
    barRatio: 0.4,
    xLabelAngle: 35,
    hideHover: 'auto'
  });
};

var constructLinesWNT = function(datas,div) {
    return new Morris.Line({
        element: div,
        data: datas,
        xkey: 'd',
        ykeys: ['web', 'nomade','total'],
        labels: ['web', 'nomade','total']
    })
};
var constructSimpleLine = function(datas,div) {
    return new Morris.Line({
        element: div,
        data: datas,
        xkey: 'd',
        ykeys: ['nb'],
        labels: ['nombre d\'observations']
    })
};
function onDataReceived1(series) {
    var datas = constructDatas(series);
    constructDonuts(datas,'kd-chart');  
};
function onDataReceived2(series) {
    var datas = constructDatas(series);
    constructDonuts(datas,'cl-chart');   
};
function onDataReceived3(series) {
    constructBars(series,'year-chart');   
};
function onDataReceived4(series) {
    constructLinesWNT(series,'cf-chart');   
};
function onDataReceived5(series) {
    constructLinesWNT(series,'inv-chart');   
};
function onDataReceived6(series) {
    constructLinesWNT(series,'cflore-chart');   
};
function onDataReceived7(series) {
    constructSimpleLine(series,'fs-chart');   
};
function onDataReceived8(series) {
    constructSimpleLine(series,'fp-chart');   
};
//récupération des données avec une requête ajax et lancement de la construction du graphique sur le success
function getDatas(url, successFunction) {
    $.ajax({
        url: url
        ,type: "GET"
        ,dataType: "json"
        ,success: successFunction
    });
};
getDatas('datasnbobskd',onDataReceived1);
getDatas('datasnbobscl',onDataReceived2);
getDatas('datasnbobsyear',onDataReceived3);
getDatas('datasnbobscf',onDataReceived4);
getDatas('datasnbobsinv',onDataReceived5);
getDatas('datasnbobscflore',onDataReceived6);
getDatas('datasnbobsfs',onDataReceived7);

</script>
 </body>
