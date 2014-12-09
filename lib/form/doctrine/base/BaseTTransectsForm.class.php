<?php

/**
 * TTransects form base class.
 *
 * @method TTransects getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseTTransectsForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_transect'           => new sfWidgetFormInputHidden(),
      'nom_transect'          => new sfWidgetFormInputText(),
      'altitude_transect'     => new sfWidgetFormInputText(),
      'the_geom'              => new sfWidgetFormTextarea(),
      'supprime'              => new sfWidgetFormInputCheckbox(),
      'verrou'                => new sfWidgetFormInputCheckbox(),
      'id_utilisateur_verrou' => new sfWidgetFormInputText(),
      'date_verrou'           => new sfWidgetFormDateTime(),
    ));

    $this->setValidators(array(
      'id_transect'           => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_transect')), 'empty_value' => $this->getObject()->get('id_transect'), 'required' => false)),
      'nom_transect'          => new sfValidatorString(array('max_length' => 200)),
      'altitude_transect'     => new sfValidatorInteger(array('required' => false)),
      'the_geom'              => new sfValidatorString(array('required' => false)),
      'supprime'              => new sfValidatorBoolean(array('required' => false)),
      'verrou'                => new sfValidatorBoolean(array('required' => false)),
      'id_utilisateur_verrou' => new sfValidatorInteger(array('required' => false)),
      'date_verrou'           => new sfValidatorDateTime(array('required' => false)),
    ));

    $this->widgetSchema->setNameFormat('t_transects[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'TTransects';
  }

}
