<body style="margin: auto; font-family: Arial; font-size: 14px;">
    <div id="bandeau_accueil"><img src="images/bandeau_faune.jpg" border="0"></div>
    <h1 style="font-weight: bold; text-align: center; font-size: 4em; margin: 70px 0px; line-height: 100%;"><?php echo sfGeonatureConfig::$apptitle_main; ?></h1>
    <div id="container" style="width:1024px;margin: auto; ">
  
        <div id="bande_consultation" style="color:#FFFFFF;background: linear-gradient(90deg, #f09819 30%, #edde5d 90%) repeat scroll 0 0 rgba(0, 0, 0, 0);letter-spacing:5px;font-weight:bold;text-shadow:0 0 3px #000;height:25px;">
            <div style="vertical-align:middle;display:inline-block;"><img src="images/logo_pag.png" border="0" width="25px" height="25px"></div>
            <div style="vertical-align:middle;display:inline-block;">CONSULTATION</div>
        </div>
        <div id="contenu_consultation" style="margin-bottom:30px">  
            <div>
                <div style="margin:10px 0 0 50px ">
                    <div style="vertical-align:middle;display:inline-block;"><img src="images/pictos/oiseau.gif" border="0"></div>
                    <div style="vertical-align:middle;display:inline-block;"><a href="synthese" style="text-decoration: none">Synthèse des observations</a></div>
                </div>
            </div>
        </div>
        
        <div id="bande_saisie" style="color:#FFFFFF;background: linear-gradient(90deg, #f09819 30%, #edde5d 90%) repeat scroll 0 0 rgba(0, 0, 0, 0);letter-spacing:5px;font-weight:bold;text-shadow:0 0 3px #000;height:25px;">
            <div style="vertical-align:middle;display:inline-block;"><img src="images/logo_pag.png" border="0" width="25px" height="25px"></div>
            <div style="vertical-align:middle;display:inline-block;">SAISIE</div>
        </div>
        <div id="contenu_saisie" style="margin-bottom:30px">
            Pour saisir de nouvelles données, vous pouvez utiliser l'un des liens ci-dessous.<br/>
            Pour modifier des données contact faune, contact invertébré ou mortalité, vous devez passer par la synthèse pour retrouver les enregistrements à modifier.<br/><br/>
            <? echo $liens_saisie;?>
        </div>
        <!--
        <div id="bande_consultation" style="color:#FFFFFF;background: linear-gradient(90deg, #f09819 30%, #edde5d 90%) repeat scroll 0 0 rgba(0, 0, 0, 0);letter-spacing:5px;font-weight:bold;text-shadow:0 0 3px #000;height:25px;">
            <div style="vertical-align:middle;display:inline-block;"><img src="images/logo_pag.png" border="0" width="25px" height="25px"></div>
            <div style="vertical-align:middle;display:inline-block;">STATISTIQUES</div>
        </div>
        <div>
            <div id="header">
                <h2>Utilisation des outils de saisie Faune</h2>
            </div>
            <div id="content">
                <div id="header">
                    <h3>Cumul des observations selon le mode de saisie</h3>
                </div>
                <div class="demo-container">
                    <p>Faune vertébrée</p>
                    <div id="placeholder1" class="demo-placeholder"></div>
                </div>             
                <div class="demo-container">
                    <p>Faune invertébrée</p>
                    <div id="placeholder3" class="demo-placeholder"></div>
                </div>

                <br/>
                <div id="header">
                    <h3>Evolution du nombre d'espèces vues ou à rechercher</h3>
                </div>
                <div class="demo-container">
                    <p>Faune vertébrée</p>
                    <div id="placeholder2" class="demo-placeholder"></div>
                </div>
                
                <div class="demo-container">
                    <p>Faune invertébrée</p>
                    <div id="placeholder4" class="demo-placeholder"></div>
                </div>
            </div>
        </div>
        -->
    </div>
 </body>
