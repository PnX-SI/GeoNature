<?php

/**
 * SpatialRefSys form base class.
 *
 * @method SpatialRefSys getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseSpatialRefSysForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'srid'      => new sfWidgetFormInputHidden(),
      'auth_name' => new sfWidgetFormTextarea(),
      'auth_srid' => new sfWidgetFormInputText(),
      'srtext'    => new sfWidgetFormTextarea(),
      'proj4text' => new sfWidgetFormTextarea(),
    ));

    $this->setValidators(array(
      'srid'      => new sfValidatorChoice(array('choices' => array($this->getObject()->get('srid')), 'empty_value' => $this->getObject()->get('srid'), 'required' => false)),
      'auth_name' => new sfValidatorString(array('max_length' => 256, 'required' => false)),
      'auth_srid' => new sfValidatorInteger(array('required' => false)),
      'srtext'    => new sfValidatorString(array('max_length' => 2048, 'required' => false)),
      'proj4text' => new sfValidatorString(array('max_length' => 2048, 'required' => false)),
    ));

    $this->widgetSchema->setNameFormat('spatial_ref_sys[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'SpatialRefSys';
  }

}
