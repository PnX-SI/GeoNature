let roles = []

$('#availability').on('change', function() {
    let selected = $(this).find(":selected")[0];
    if (selected && selected.hasAttribute("sensitivity_filter"))
        $("#sensitivity_filter").parent().show();
    else
        $("#sensitivity_filter").parent().hide();
        $('#sensitivity_filter').prop('checked', false);

    if (selected && selected.hasAttribute("scope_filter"))
        $("#scope").parent().show();
    else {
        $("#scope").parent().hide();
        $("#scope").val("__None").trigger("change");
    }
});

$('#availability').trigger('change');

$(document).ajaxSuccess(function(event, xhr, options){
    roles = xhr.responseJSON;
});

let startingRole = $("#role").attr('data-json');
let startingAvailability = $("#availability :selected").val();
if (startingRole) {
    startingRole = JSON.parse(startingRole);
    hideAvailability(startingRole);
}

$("#role").on('change', function() {
    let data = $("#role").select2("data");
    $("#availability option").prop('disabled', false);
    if (data) {
        let role = roles.find(r => r[0] === data.id);
        hideAvailability(role)
    }
});

function hideAvailability(role) {
    if (Array.isArray(role[2])) {
        for (i in role[2]) {
            const key = role[2][i];
            const selectedOption = $('#availability').select2("data");
            let option = $("#availability option").filter((i, e) => {return $(e).val() === key});

            if (!(startingAvailability === key && role[0] === startingRole[0]))
                option.prop('disabled', true);
            
            if (selectedOption && selectedOption.id === key && option.prop('disabled')) {
                $("#availability").select2("val", "").trigger('change');
            }
        }
    }
}
