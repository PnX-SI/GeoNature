<?php

/**
 * CorRoleDroitApplication form base class.
 *
 * @method CorRoleDroitApplication getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseCorRoleDroitApplicationForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_role'        => new sfWidgetFormInputHidden(),
      'id_droit'       => new sfWidgetFormDoctrineChoice(array('model' => $this->getRelatedModelName('BibDroits'), 'add_empty' => false)),
      'id_application' => new sfWidgetFormInputText(),
    ));

    $this->setValidators(array(
      'id_role'        => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_role')), 'empty_value' => $this->getObject()->get('id_role'), 'required' => false)),
      'id_droit'       => new sfValidatorDoctrineChoice(array('model' => $this->getRelatedModelName('BibDroits'))),
      'id_application' => new sfValidatorInteger(),
    ));

    $this->widgetSchema->setNameFormat('cor_role_droit_application[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'CorRoleDroitApplication';
  }

}
