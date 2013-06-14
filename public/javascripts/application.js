$(function() {
    $("body").on("submit", "form", function(event) {
        event.preventDefault();
    });

    $("input").each(function() {
        var input;

        input = $(this);

        input.data("previous-value", input.val());
    });

    $("body").on("keyup", "input", function() {
        var form, keyupTimeout;

        form = $(this).closest("form");

        keyupTimeout = form.data("keyupTimeout");

        if (keyupTimeout) {
            clearTimeout(keyupTimeout);
        }

        keyupTimeout = setTimeout(function() {
            var valuesChanged;

            valuesChanged = false;

            $("input").each(function() {
                var input;

                input = $(this);

                if (input.data("previous-value") !== input.val()) {
                    valuesChanged = true;
                }

                input.data("previous-value", input.val());
            });

            if (valuesChanged && $("#first-name").val() !== "" && $("#last-name").val() !== "" && $("#email").val() !== "") {
                $("#qr-code").empty();

                $("#qr-code").append($("<img>").attr("src", "/qr?" + form.serialize()));
            }
        }, 750);

        form.data("keyupTimeout", keyupTimeout);
    });

    $("body").on("click", "#email-qr-code", function(event) {
        var form;

        event.preventDefault();

        form = $(this).closest("form");

        if ($("#first-name").val() !== "" && $("#last-name").val() !== "" && $("#email").val() !== "") {
            $("#email-qr-code").attr("disabled", true);

            $.ajax({
                type: "POST",
                url: "/email",
                data: form.serialize(),
                success: function(data, textStatus, jqXHR) {
                    console.log(data, textStatus, jqXHR);

                    $("#email-result").text(data.message);
                },
                error: function(jqXHR, textStatus, errorThrown) {
                    console.log(jqXHR, textStatus, errorThrown);

                    $("#email-result").text(errorThrown);

                    $("#email-qr-code").attr("disabled", false);
                },
                dataType: "json"
            });
        }
    });
});
