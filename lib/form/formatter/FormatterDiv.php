<?php

class sfWidgetFormSchemaFormatterDiv extends sfWidgetFormSchemaFormatter
{
  protected
    $rowFormat       = "<div class=\"form-row %class%\">\n  %error%%label%\n
%field%%help%\n%hidden_fields%</div>\n",
    $errorRowFormat  = "<div class=\"form-errors\">\n%errors%</div>\n",
    $helpFormat      = '<div class="form-help">%help%</div>',
    $decoratorFormat = "<div>\n  %content%</div>";

} 