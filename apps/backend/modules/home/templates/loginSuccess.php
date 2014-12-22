<?php use_helper('Url') ?>
  <h2 style="color:#FFFFFF;font-family:Arial;letter-spacing:2px;margin-top:35px;text-align:center;text-shadow:0 0 3px #555555;">
   <?php echo sfGeonatureConfig::$appname_main; ?>
  </h2> 
<form action="<?php echo url_for('@login') ?>" method="post" id="loginForm">
  <div id="container">
      <?php echo $form?>
      <input type="submit" id="submit" value="Connexion" />
  </div>
  <div id="reflect"></div>
</form>
