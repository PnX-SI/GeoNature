<?php

/**
 * CorRoles form base class.
 *
 * @method CorRoles getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseCorRolesForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_role_groupe'      => new sfWidgetFormInputHidden(),
      'id_role_utilisateur' => new sfWidgetFormDoctrineChoice(array('model' => $this->getRelatedModelName('TRolesUtilisateur'), 'add_empty' => false)),
    ));

    $this->setValidators(array(
      'id_role_groupe'      => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_role_groupe')), 'empty_value' => $this->getObject()->get('id_role_groupe'), 'required' => false)),
      'id_role_utilisateur' => new sfValidatorDoctrineChoice(array('model' => $this->getRelatedModelName('TRolesUtilisateur'))),
    ));

    $this->widgetSchema->setNameFormat('cor_roles[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'CorRoles';
  }

}
