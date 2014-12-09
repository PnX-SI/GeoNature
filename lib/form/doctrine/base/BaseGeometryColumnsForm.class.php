<?php

/**
 * GeometryColumns form base class.
 *
 * @method GeometryColumns getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseGeometryColumnsForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'f_table_catalog'   => new sfWidgetFormInputHidden(),
      'f_table_schema'    => new sfWidgetFormTextarea(),
      'f_table_name'      => new sfWidgetFormTextarea(),
      'f_geometry_column' => new sfWidgetFormTextarea(),
      'coord_dimension'   => new sfWidgetFormInputText(),
      'srid'              => new sfWidgetFormInputText(),
      'type'              => new sfWidgetFormInputText(),
    ));

    $this->setValidators(array(
      'f_table_catalog'   => new sfValidatorChoice(array('choices' => array($this->getObject()->get('f_table_catalog')), 'empty_value' => $this->getObject()->get('f_table_catalog'), 'required' => false)),
      'f_table_schema'    => new sfValidatorString(array('max_length' => 256)),
      'f_table_name'      => new sfValidatorString(array('max_length' => 256)),
      'f_geometry_column' => new sfValidatorString(array('max_length' => 256)),
      'coord_dimension'   => new sfValidatorInteger(),
      'srid'              => new sfValidatorInteger(),
      'type'              => new sfValidatorString(array('max_length' => 30)),
    ));

    $this->widgetSchema->setNameFormat('geometry_columns[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'GeometryColumns';
  }

}
