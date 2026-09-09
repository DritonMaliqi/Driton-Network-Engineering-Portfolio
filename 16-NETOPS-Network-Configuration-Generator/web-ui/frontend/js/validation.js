const FormValidation = {

    async validateInput(input) {

        const required =
            input.dataset.required === "true";

        const validation =
            input.dataset.validation || "";

        const value =
            input.value.trim();

        const error =
            document.getElementById(
                `error-${input.dataset.param}`
            );

        input.classList.remove(
            "error",
            "valid"
        );

        if (error) {
            error.textContent = "";
        }

        if (!value) {

            if (required) {

                input.classList.add("error");

                if (error) {
                    error.textContent =
                        "This field is required.";
                }

                return false;
            }

            return true;
        }


        if (!validation) {

            input.classList.add("valid");
            return true;
        }


        try {

            const result =
                await API.validate(
                    input.dataset.param,
                    value,
                    validation
                );


            if (result.valid) {

                input.classList.add("valid");

                return true;
            }


            input.classList.add("error");

            if (error) {
                error.textContent =
                    result.message ||
                    "Invalid value.";
            }

            return false;

        }
        catch (err) {

            input.classList.add("error");

            if (error) {
                error.textContent =
                    err.message;
            }

            return false;
        }
    },


    async validateContainer(container) {

        const fields = [
            ...container.querySelectorAll(
                ".parameter-input"
            )
        ];

        let allValid = true;

        for (const field of fields) {

            const valid =
                await this.validateInput(
                    field
                );

            if (!valid) {
                allValid = false;
            }
        }

        return allValid;
    }

};