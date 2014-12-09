<?php

/**
 * TApplications form base class.
 *
 * @method TApplications getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseTApplicationsForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_application'   => new sfWidgetFormInputHidden(),
      'nom_application'  => new sfWidgetFormInputText(),
      'desc_application' => new sfWidgetFormTextarea(),
      'connect_host'     => new sfWidgetFormInputText(),
      'connect_database' => new sfWidgetFormInputText(),
      'connect_user'     => new sfWidgetFormInputText(),
      'connect_pass'     => new sfWidgetFormInputText(),
    ));

    $this->setValidators(array(
      'id_application'   => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_application')), 'empty_value' => $this->getObject()->get('id_application'), 'required' => false)),
      'nom_application'  => new sfValidatorString(array('max_length' => 50)),
      'desc_application' => new sfValidatorString(array('required' => false)),
      'connect_host'     => new sfValidatorString(array('max_length' => 100, 'required' => false)),
      'connect_database' => new sfValidatorString(array('max_length' => 50, 'required' => false)),
      'connect_user'     => new sfValidatorString(array('max_length' => 50, 'required' => false)),
      'connect_pass'     => new sfValidatorString(array('max_length' => 20, 'required' => false)),
    ));

    $this->widgetSchema->setNameFormat('t_applications[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'TApplications';
  }

}
