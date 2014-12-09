<?php

/**
 * TMenus form base class.
 *
 * @method TMenus getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseTMenusForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_menu'        => new sfWidgetFormInputHidden(),
      'nom_menu'       => new sfWidgetFormInputText(),
      'desc_menu'      => new sfWidgetFormTextarea(),
      'id_application' => new sfWidgetFormDoctrineChoice(array('model' => $this->getRelatedModelName('TApplications'), 'add_empty' => true)),
    ));

    $this->setValidators(array(
      'id_menu'        => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_menu')), 'empty_value' => $this->getObject()->get('id_menu'), 'required' => false)),
      'nom_menu'       => new sfValidatorString(array('max_length' => 50)),
      'desc_menu'      => new sfValidatorString(array('required' => false)),
      'id_application' => new sfValidatorDoctrineChoice(array('model' => $this->getRelatedModelName('TApplications'), 'required' => false)),
    ));

    $this->widgetSchema->setNameFormat('t_menus[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'TMenus';
  }

}
