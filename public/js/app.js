'use strict';

/* Calendar */
$(document).ready(function () {
    $('#html').summernote({height: 200});
});

/* Server pages */
$('.personpop').popover({placement:'auto', html:true});

$('#modal_cert').on('show.bs.modal', function (event) {
    var button = $(event.relatedTarget);
    var server_cert_id = button.data('server_cert_id');
    $('#server_cert_id').val(server_cert_id);
    if (server_cert_id) {
        $('#delete_server_cert').show();
    } else {
        $('#delete_server_cert').hide();
    }
    var cert_id = button.data('cert_id');
    $('#cert_id').val(cert_id);
    var use_id = button.data('use_id');
    $('#use_id').val(use_id);
});

/* Document retire */
$('#modal_retire').on('show.bs.modal', function (event) {
    var button = $(event.relatedTarget);
    var retire = button.data('retire');
    $('#retire').val(retire);
});

/* Document edit */
$( ".radio_doctype" ).change(function() {
    if (this.value == "binary" || this.value == "signed" || this.value == "record")
    {
        $( "#div_binary" ).show(400);
        $( "#div_text" ).hide(400);
    }
    else {
        $( "#div_binary" ).hide(400);
        $( "#div_text" ).show(400);
    }
});
$('#editor').on('change', function(){
    localStorage.setItem('draft-content', $(this).val());
});

/* Issues */
$('.issuetype').on('change', function(){
    let $selected = $(this).find(":selected");
    if ($selected.data('is-breach')) {
        $('.rca').show();
    } else {
        $('.rca').hide();
    }
    if ($selected.data('is-general')) {
        $('.security_considerations').show();
    } else {
        $('.security_considerations').hide();
    }
}).trigger('change');
