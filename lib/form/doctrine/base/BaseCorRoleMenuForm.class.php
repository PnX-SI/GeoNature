<?php

/**
 * CorRoleMenu form base class.
 *
 * @method CorRoleMenu getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseCorRoleMenuForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_role' => new sfWidgetFormInputHidden(),
      'id_menu' => new sfWidgetFormInputText(),
    ));

    $this->setValidators(array(
      'id_role' => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_role')), 'empty_value' => $this->getObject()->get('id_role'), 'required' => false)),
      'id_menu' => new sfValidatorInteger(),
    ));

    $this->widgetSchema->setNameFormat('cor_role_menu[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'CorRoleMenu';
  }

}
