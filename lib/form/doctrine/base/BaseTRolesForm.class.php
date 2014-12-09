<?php

/**
 * TRoles form base class.
 *
 * @method TRoles getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseTRolesForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'groupe'        => new sfWidgetFormInputCheckbox(),
      'id_role'       => new sfWidgetFormInputHidden(),
      'organisme'     => new sfWidgetFormTextarea(),
      'identifiant'   => new sfWidgetFormInputText(),
      'nom_role'      => new sfWidgetFormInputText(),
      'prenom_role'   => new sfWidgetFormInputText(),
      'desc_role'     => new sfWidgetFormTextarea(),
      'pass'          => new sfWidgetFormInputText(),
      'email'         => new sfWidgetFormInputText(),
      'id_unite'      => new sfWidgetFormDoctrineChoice(array('model' => $this->getRelatedModelName('BibUnites'), 'add_empty' => true)),
      'pne'           => new sfWidgetFormInputCheckbox(),
      'assermentes'   => new sfWidgetFormInputCheckbox(),
      'enposte'       => new sfWidgetFormInputCheckbox(),
      'dernieracces'  => new sfWidgetFormDateTime(),
      'session_appli' => new sfWidgetFormInputText(),
      'date_insert'   => new sfWidgetFormDateTime(),
      'date_update'   => new sfWidgetFormDateTime(),
    ));

    $this->setValidators(array(
      'groupe'        => new sfValidatorBoolean(array('required' => false)),
      'id_role'       => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_role')), 'empty_value' => $this->getObject()->get('id_role'), 'required' => false)),
      'organisme'     => new sfValidatorString(array('required' => false)),
      'identifiant'   => new sfValidatorString(array('max_length' => 100, 'required' => false)),
      'nom_role'      => new sfValidatorString(array('max_length' => 50, 'required' => false)),
      'prenom_role'   => new sfValidatorString(array('max_length' => 50, 'required' => false)),
      'desc_role'     => new sfValidatorString(array('required' => false)),
      'pass'          => new sfValidatorString(array('max_length' => 100, 'required' => false)),
      'email'         => new sfValidatorString(array('max_length' => 250, 'required' => false)),
      'id_unite'      => new sfValidatorDoctrineChoice(array('model' => $this->getRelatedModelName('BibUnites'), 'required' => false)),
      'pne'           => new sfValidatorBoolean(array('required' => false)),
      'assermentes'   => new sfValidatorBoolean(array('required' => false)),
      'enposte'       => new sfValidatorBoolean(array('required' => false)),
      'dernieracces'  => new sfValidatorDateTime(array('required' => false)),
      'session_appli' => new sfValidatorString(array('max_length' => 50, 'required' => false)),
      'date_insert'   => new sfValidatorDateTime(array('required' => false)),
      'date_update'   => new sfValidatorDateTime(array('required' => false)),
    ));

    $this->widgetSchema->setNameFormat('t_roles[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'TRoles';
  }

}
