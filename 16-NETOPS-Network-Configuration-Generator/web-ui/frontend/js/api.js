const API = {

    baseURL: "/api",

    async request(endpoint, options = {}) {

        const response = await fetch(
            `${this.baseURL}${endpoint}`,
            {
                headers: {
                    "Content-Type": "application/json",
                    ...(options.headers || {})
                },
                ...options
            }
        );

        let payload = null;

        try {
            payload = await response.json();
        }
        catch {
            payload = {};
        }

        if (!response.ok) {

            let message =
                payload?.detail ||
                `HTTP ${response.status}`;

            if (
                typeof message === "object" &&
                Array.isArray(message.errors)
            ) {
                message =
                    message.errors.join("\n");
            }

            throw new Error(
                typeof message === "string"
                    ? message
                    : JSON.stringify(message)
            );
        }

        return payload;
    },


    health() {
        return this.request("/health");
    },


    getVendors() {
        return this.request("/vendors");
    },


    getPlatforms(vendor) {
        return this.request(
            `/platforms?vendor=${
                encodeURIComponent(vendor)
            }`
        );
    },


    getTechnologies(vendor) {
        return this.request(
            `/technologies?vendor=${
                encodeURIComponent(vendor)
            }`
        );
    },


    getSchema(vendor, technology) {
        return this.request(
            `/schema?vendor=${
                encodeURIComponent(vendor)
            }&technology=${
                encodeURIComponent(technology)
            }`
        );
    },


    validate(
        fieldName,
        fieldValue,
        validationType
    ) {

        return this.request(
            "/validate",
            {
                method: "POST",

                body: JSON.stringify({
                    field_name: fieldName,
                    field_value: fieldValue,
                    validation_type: validationType
                })
            }
        );
    },


    generate(
        vendor,
        platform,
        technology,
        parameters
    ) {

        return this.request(
            "/generate",
            {
                method: "POST",

                body: JSON.stringify({
                    vendor,
                    platform,
                    technology,
                    parameters
                })
            }
        );
    },


    ipamCalculate(network) {

        return this.request(
            "/ipam/calculate",
            {
                method: "POST",
                body: JSON.stringify({
                    network
                })
            }
        );
    },


    ipamVlsm(network, requirements) {

        return this.request(
            "/ipam/vlsm",
            {
                method: "POST",
                body: JSON.stringify({
                    network,
                    requirements
                })
            }
        );
    },


    ipamList(search = "") {

        return this.request(
            `/ipam/allocations?search=${
                encodeURIComponent(search)
            }`
        );
    },


    ipamGet(recordId) {

        return this.request(
            `/ipam/allocations/${recordId}`
        );
    },


    ipamAdd(record) {

        return this.request(
            "/ipam/allocations",
            {
                method: "POST",
                body: JSON.stringify(record)
            }
        );
    },


    ipamUpdate(recordId, record) {

        return this.request(
            `/ipam/allocations/${recordId}`,
            {
                method: "PUT",
                body: JSON.stringify(record)
            }
        );
    },


    ipamDelete(recordId) {

        return this.request(
            `/ipam/allocations/${recordId}`,
            {
                method: "DELETE"
            }
        );
    },


    async ipamImportCsv(file) {

        const formData =
            new FormData();

        formData.append(
            "file",
            file
        );

        const response =
            await fetch(
                `${this.baseURL}/ipam/import-csv`,
                {
                    method: "POST",
                    body: formData
                }
            );


        let payload = {};

        try {
            payload =
                await response.json();
        }
        catch {
            payload = {};
        }


        if (!response.ok) {

            const detail =
                payload?.detail ||
                `HTTP ${response.status}`;

            throw new Error(
                typeof detail === "string"
                    ? detail
                    : JSON.stringify(detail)
            );
        }


        return payload;
    },


    ipamExportUrl() {

        return `${this.baseURL}/ipam/export-csv`;
    }

};
