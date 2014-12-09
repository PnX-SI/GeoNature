<?php 

/**
 * Login Form
 *
 */
class LoginForm extends BaseForm
{
	
	/**
	 * Configure login Form
	 *
	 */
  public function configure()
  {
	//setWidgets = définition des champs du formulaire = name d'un input par exemple
    $this->setWidgets(array(
      'login'  => new sfWidgetFormInputText(),
      'password'  => new sfWidgetFormInputPassword(),
    ));
	//valide chaque champ selon son contenu (voir la doc symfony pour les différentes classes de validator ; par exemple sfValditorEmail
    $this->setValidators(array(
      'login' => new sfValidatorString(array('required' => true), array('required'=>'Identifiant requis.')),
      'password' => new sfValidatorString(array('required' => true), array('required'=>'Mot de passe requis.')),
    ));
	//placer des labels devant les champs
    $this->widgetSchema->setLabels(array(
      'login' => 'Identifiant',
      'password' => 'Mot de passe'
    ));
    //défini un préfixe dans le name ou le id du html
    $this->widgetSchema->setNameFormat('login[%s]');
	//probalement écriture du html avec des div
    $this->widgetSchema->setFormFormatterName('div');
    
    // post traitement pour vérifier que le formulaire entier est bien valide ; ici on va vérifier que l'utilisateur à bien des droits
    $this->validatorSchema->setPostValidator(
      new sfValidatorCallback(array('callback' => array($this, 'checkPassword')))
    );
  }
 
  /**
   * Check login/pass
   *
   * @param sfValidator $validator
   * @param array $values
   * 
   * @return array
   */
	public function checkPassword($validator, $values)
	{
	$passmd5= md5($values['password']);
	//la fonction identify est dans le fichier /lib/model/fauneUsers.class.php
	  if (!empty($values['login']) && !empty($values['password']) && !(fauneUsers::identify($values['login'], $passmd5)))
	  {
	    $error = new sfValidatorError($validator, 'Mot de passe incorrect');
	 
	    // throw an error bound to the password field
	    throw new sfValidatorErrorSchema($validator, array('password' => $error));
	  }
	 
	  return $values;
	}
  
}
