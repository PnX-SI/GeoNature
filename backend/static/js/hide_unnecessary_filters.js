$('#availability').on('change', function() {
    if ($(this).find(":selected")[0].hasAttribute("sensitivity_filter"))
        $("#sensitivity_filter").parent().show();
    else
        $("#sensitivity_filter").parent().hide();
        $('#sensitivity_filter').prop('checked', false);

    if ($(this).find(":selected")[0].hasAttribute("scope_filter"))
        $("#scope").parent().show();
    else {
        $("#scope").parent().hide();
        $("#scope").val("__None").trigger("change");
    }
});

$('#availability').trigger('change');
