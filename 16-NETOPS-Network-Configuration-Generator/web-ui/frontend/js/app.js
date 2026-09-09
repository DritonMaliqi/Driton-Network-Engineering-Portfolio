class NetOpsApp {

    constructor() {

        this.vendor = "";
        this.platform = "";
        this.technology = "";

        this.schema = [];

        this.currentConfig = null;

        this.generatedCount = 0;


        this.el = {

            pageTitle:
                document.getElementById(
                    "page-title"
                ),

            pageSubtitle:
                document.getElementById(
                    "page-subtitle"
                ),

            vendor:
                document.getElementById(
                    "vendor-select"
                ),

            platform:
                document.getElementById(
                    "platform-select"
                ),

            technology:
                document.getElementById(
                    "technology-select"
                ),

            parameters:
                document.getElementById(
                    "parameter-container"
                ),

            parameterCount:
                document.getElementById(
                    "parameter-count"
                ),

            parameterSubtitle:
                document.getElementById(
                    "parameter-subtitle"
                ),

            generate:
                document.getElementById(
                    "generate-button"
                ),

            config:
                document.getElementById(
                    "config-output"
                ),

            previewMeta:
                document.getElementById(
                    "preview-meta"
                ),

            addBuild:
                document.getElementById(
                    "add-build-button"
                ),

            save:
                document.getElementById(
                    "save-button"
                ),

            buildCount:
                document.getElementById(
                    "build-count"
                ),

            dashboardBuildCount:
                document.getElementById(
                    "dashboard-build-count"
                ),

            generatedCount:
                document.getElementById(
                    "generated-count"
                ),

            buildTotal:
                document.getElementById(
                    "build-section-total"
                ),

            buildList:
                document.getElementById(
                    "build-list"
                ),

            buildOutput:
                document.getElementById(
                    "build-output"
                ),

            vendorContext:
                document.getElementById(
                    "vendor-context"
                )
        };


        this.init();
    }


    async init() {

        this.bindNavigation();
        this.bindGenerator();
        this.bindPreview();
        this.bindBuild();
        this.bindIPAM();

        await this.checkAPI();
        await this.loadVendors();

        this.updateBuildUI();
    }


    /* =======================================================
       API STATUS
       ======================================================= */

    async checkAPI() {

        const dot =
            document.getElementById(
                "api-status-dot"
            );

        const text =
            document.getElementById(
                "api-status-text"
            );


        try {

            const status =
                await API.health();


            dot.classList.add(
                "online"
            );

            dot.classList.remove(
                "offline"
            );

            text.textContent =
                `API Online · ${
                    status.schema_count
                } schemas`;

        }
        catch {

            dot.classList.add(
                "offline"
            );

            dot.classList.remove(
                "online"
            );

            text.textContent =
                "API Offline";


            this.toast(
                "FastAPI backend is offline.",
                "error"
            );
        }
    }


    /* =======================================================
       NAVIGATION
       ======================================================= */

    bindNavigation() {

        document
            .querySelectorAll(
                ".nav-item"
            )
            .forEach(button => {

                button.addEventListener(
                    "click",
                    async () => {

                        const page =
                            button.dataset.page;

                        const vendor =
                            button.dataset.vendor;


                        this.showPage(
                            page
                        );


                        if (vendor) {

                            await this.selectVendor(
                                vendor
                            );
                        }
                    }
                );
            });


        document
            .getElementById(
                "start-generator"
            )
            .addEventListener(
                "click",
                () =>
                    this.showPage(
                        "generator"
                    )
            );


        document
            .querySelectorAll(
                "[data-dashboard-vendor]"
            )
            .forEach(card => {

                card.addEventListener(
                    "click",
                    async () => {

                        const vendor =
                            card.dataset
                                .dashboardVendor;

                        this.showPage(
                            "generator"
                        );

                        await this.selectVendor(
                            vendor
                        );
                    }
                );
            });
    }


    showPage(page) {

        document
            .querySelectorAll(
                ".page"
            )
            .forEach(element =>
                element.classList.remove(
                    "active"
                )
            );


        const target =
            document.getElementById(
                `page-${page}`
            );


        if (target) {
            target.classList.add(
                "active"
            );
        }


        document
            .querySelectorAll(
                ".nav-item"
            )
            .forEach(item => {

                item.classList.toggle(
                    "active",
                    item.dataset.page === page &&
                    !item.dataset.vendor
                );
            });


        const titles = {

            dashboard: [
                "Dashboard",
                "Network Configuration Automation"
            ],

            generator: [
                "Universal Generator",
                "Cisco · FortiGate · Palo Alto"
            ],

            ipam: [
                "IPAM & Subnet Planner",
                "IPv4 Address Planning & Management"
            ],

            build: [
                "Build Workspace",
                "Multi-Vendor Configuration Build"
            ]
        };


        const selected =
            titles[page] ||
            ["NETOPS", "Project 16"];


        this.el.pageTitle.textContent =
            selected[0];

        this.el.pageSubtitle.textContent =
            selected[1];


        if (page === "ipam") {
            this.loadIPAMRecords();
        }

        if (page === "build") {
            this.updateBuildUI();
        }
    }


    /* =======================================================
       VENDOR / PLATFORM / TECHNOLOGY
       ======================================================= */

    async loadVendors() {

        const result =
            await API.getVendors();


        this.el.vendor.innerHTML =
            '<option value="">Select vendor</option>';


        result.vendors.forEach(
            vendor => {

                const option =
                    document.createElement(
                        "option"
                    );

                option.value = vendor;
                option.textContent = vendor;

                this.el.vendor.appendChild(
                    option
                );
            }
        );
    }


    async selectVendor(vendor) {

        this.el.vendor.value =
            vendor;

        await this.onVendorChange();
    }


    bindGenerator() {

        this.el.vendor.addEventListener(
            "change",
            () =>
                this.onVendorChange()
        );


        this.el.platform.addEventListener(
            "change",
            () => {

                this.platform =
                    this.el.platform.value;

                this.updateContext();
            }
        );


        this.el.technology.addEventListener(
            "change",
            () =>
                this.onTechnologyChange()
        );


        this.el.generate.addEventListener(
            "click",
            () =>
                this.generate()
        );
    }


    async onVendorChange() {

        this.vendor =
            this.el.vendor.value;

        this.platform = "";
        this.technology = "";

        this.currentConfig = null;


        this.el.addBuild.disabled = true;
        this.el.save.disabled = true;


        this.el.platform.innerHTML =
            '<option value="">Select platform</option>';

        this.el.technology.innerHTML =
            '<option value="">Select technology</option>';


        if (!this.vendor) {

            this.el.platform.disabled = true;
            this.el.technology.disabled = true;

            this.renderEmptyParameters();

            return;
        }


        try {

            const [
                platforms,
                technologies
            ] =
                await Promise.all([
                    API.getPlatforms(
                        this.vendor
                    ),

                    API.getTechnologies(
                        this.vendor
                    )
                ]);


            platforms.platforms.forEach(
                platform => {

                    const option =
                        document.createElement(
                            "option"
                        );

                    option.value = platform;
                    option.textContent =
                        platform;

                    this.el.platform
                        .appendChild(
                            option
                        );
                }
            );


            technologies.technologies
                .forEach(
                    technology => {

                        const option =
                            document.createElement(
                                "option"
                            );

                        option.value =
                            technology;

                        option.textContent =
                            technology;

                        this.el.technology
                            .appendChild(
                                option
                            );
                    }
                );


            this.el.platform.disabled =
                false;

            this.el.technology.disabled =
                false;


            if (
                platforms.platforms.length
            ) {

                this.el.platform.value =
                    platforms.platforms[0];

                this.platform =
                    platforms.platforms[0];
            }


            this.updateContext();

        }
        catch (err) {

            this.toast(
                err.message,
                "error"
            );
        }
    }


    async onTechnologyChange() {

        this.technology =
            this.el.technology.value;

        this.platform =
            this.el.platform.value;


        this.currentConfig = null;

        this.el.addBuild.disabled = true;
        this.el.save.disabled = true;


        if (!this.technology) {

            this.renderEmptyParameters();

            return;
        }


        try {

            const result =
                await API.getSchema(
                    this.vendor,
                    this.technology
                );


            this.schema =
                result.parameters || [];


            this.renderParameters();

            this.el.generate.disabled =
                false;


            this.el.parameterSubtitle
                .textContent =
                    `${this.vendor} / ${
                        this.technology
                    }`;


            this.updateContext();

        }
        catch (err) {

            this.toast(
                err.message,
                "error"
            );
        }
    }


    updateContext() {

        if (!this.vendor) {

            this.el.vendorContext
                .textContent =
                    "No vendor selected";

            return;
        }


        const items = [
            this.vendor,
            this.platform,
            this.technology
        ].filter(Boolean);


        this.el.vendorContext
            .textContent =
                items.join(" / ");
    }


    /* =======================================================
       DYNAMIC PARAMETERS
       ======================================================= */

    renderEmptyParameters() {

        this.schema = [];

        this.el.parameterCount
            .textContent =
                "0 fields";


        this.el.generate.disabled =
            true;


        this.el.parameters.innerHTML = `
            <div class="empty-state">

                <div class="empty-icon">
                    ◇
                </div>

                <strong>
                    No technology selected
                </strong>

                <p>
                    Choose Vendor, Platform
                    and Technology above.
                </p>

            </div>
        `;
    }


    renderParameters() {

        this.el.parameters.innerHTML =
            "";


        this.el.parameterCount
            .textContent =
                `${this.schema.length} fields`;


        this.schema.forEach(
            field => {

                const wrapper =
                    document.createElement(
                        "div"
                    );

                wrapper.className =
                    "parameter-field";


                const required =
                    field.required
                        ? '<span class="required">*</span>'
                        : "";


                wrapper.innerHTML = `
                    <label class="field-label">
                        ${this.escapeHTML(
                            field.label
                        )}
                        ${required}
                    </label>

                    <input
                        class="parameter-input"
                        id="param-${
                            field.name
                        }"
                        data-param="${
                            field.name
                        }"
                        data-required="${
                            field.required
                                ? "true"
                                : "false"
                        }"
                        data-validation="${
                            field.validation || ""
                        }"
                        type="${
                            field.type === "password"
                                ? "password"
                                : field.type === "number"
                                    ? "number"
                                    : "text"
                        }"
                        value="${
                            this.escapeAttribute(
                                field.default ?? ""
                            )
                        }"
                        autocomplete="off"
                    >

                    <div
                        class="field-error"
                        id="error-${
                            field.name
                        }"
                    ></div>
                `;


                this.el.parameters
                    .appendChild(
                        wrapper
                    );
            }
        );


        this.el.parameters
            .querySelectorAll(
                ".parameter-input"
            )
            .forEach(input => {

                input.addEventListener(
                    "blur",
                    () =>
                        FormValidation
                            .validateInput(
                                input
                            )
                );
            });
    }


    collectParameters() {

        const parameters = {};


        this.el.parameters
            .querySelectorAll(
                ".parameter-input"
            )
            .forEach(input => {

                parameters[
                    input.dataset.param
                ] =
                    input.value.trim();
            });


        return parameters;
    }


    /* =======================================================
       GENERATE
       ======================================================= */

    async generate() {

        if (
            !this.vendor ||
            !this.platform ||
            !this.technology
        ) {

            this.toast(
                "Select Vendor, Platform and Technology.",
                "warning"
            );

            return;
        }


        const valid =
            await FormValidation
                .validateContainer(
                    this.el.parameters
                );


        if (!valid) {

            this.toast(
                "Correct validation errors before generating.",
                "error"
            );

            return;
        }


        const parameters =
            this.collectParameters();


        this.el.generate.disabled =
            true;

        this.el.generate.textContent =
            "Generating...";


        try {

            const result =
                await API.generate(
                    this.vendor,
                    this.platform,
                    this.technology,
                    parameters
                );


            this.currentConfig =
                result;


            this.el.config.textContent =
                result.config;


            this.el.previewMeta
                .textContent =
                    `${result.vendor} · ${
                        result.platform
                    } · ${
                        result.technology
                    }`;


            this.el.addBuild.disabled =
                false;

            this.el.save.disabled =
                false;


            this.generatedCount++;


            this.el.generatedCount
                .textContent =
                    this.generatedCount;


            this.toast(
                "Configuration generated successfully.",
                "success"
            );

        }
        catch (err) {

            this.toast(
                err.message,
                "error"
            );
        }
        finally {

            this.el.generate.disabled =
                false;

            this.el.generate.textContent =
                "Generate Configuration";
        }
    }


    /* =======================================================
       PREVIEW
       ======================================================= */

    bindPreview() {

        document
            .getElementById(
                "copy-button"
            )
            .addEventListener(
                "click",
                () =>
                    this.copyText(
                        this.el.config
                            .textContent
                    )
            );


        document
            .getElementById(
                "clear-button"
            )
            .addEventListener(
                "click",
                () =>
                    this.clearPreview()
            );


        this.el.addBuild
            .addEventListener(
                "click",
                () =>
                    this.addToBuild()
            );


        this.el.save
            .addEventListener(
                "click",
                () =>
                    this.saveCurrent()
            );
    }


    clearPreview() {

        this.currentConfig = null;

        this.el.config.textContent =
            "# Configuration Preview cleared.";

        this.el.previewMeta
            .textContent =
                "Ready for configuration generation.";

        this.el.addBuild.disabled =
            true;

        this.el.save.disabled =
            true;
    }


    addToBuild() {

        if (!this.currentConfig) {

            this.toast(
                "Generate a configuration first.",
                "warning"
            );

            return;
        }


        const added =
            Builder.add({
                vendor:
                    this.currentConfig.vendor,

                platform:
                    this.currentConfig.platform,

                technology:
                    this.currentConfig.technology,

                name:
                    this.currentConfig.name,

                config:
                    this.currentConfig.config
            });


        if (!added) {

            this.toast(
                "This configuration is already in the build.",
                "warning"
            );

            return;
        }


        this.updateBuildUI();


        this.toast(
            "Configuration added to build.",
            "success"
        );
    }


    saveCurrent() {

        if (!this.currentConfig) {
            return;
        }


        const timestamp =
            this.timestamp();


        const safeVendor =
            this.safeFilename(
                this.currentConfig.vendor
            );


        const safeTech =
            this.safeFilename(
                this.currentConfig.technology
            );


        const filename =
            `NETOPS-${safeVendor}-${safeTech}-${timestamp}.cfg`;


        this.download(
            this.currentConfig.config,
            filename
        );


        this.toast(
            `Saved ${filename}`,
            "success"
        );
    }


    /* =======================================================
       BUILD
       ======================================================= */

    /* =======================================================
       IPAM
       ======================================================= */

    bindIPAM() {

        document
            .querySelectorAll(".ipam-tab")
            .forEach(button => {

                button.addEventListener(
                    "click",
                    () => {

                        document
                            .querySelectorAll(".ipam-tab")
                            .forEach(tab =>
                                tab.classList.remove("active")
                            );

                        document
                            .querySelectorAll(".ipam-module")
                            .forEach(module =>
                                module.classList.remove("active")
                            );

                        button.classList.add("active");

                        const target =
                            document.getElementById(
                                `ipam-module-${
                                    button.dataset.ipamTab
                                }`
                            );

                        if (target) {
                            target.classList.add("active");
                        }
                    }
                );
            });


        const calculateButton =
            document.getElementById(
                "ipam-calculate-button"
            );

        if (calculateButton) {

            calculateButton.addEventListener(
                "click",
                () =>
                    this.calculateIPAM()
            );
        }


        const vlsmButton =
            document.getElementById(
                "vlsm-plan-button"
            );

        if (vlsmButton) {

            vlsmButton.addEventListener(
                "click",
                () =>
                    this.generateVLSM()
            );
        }


        const searchButton =
            document.getElementById(
                "ipam-search-button"
            );

        if (searchButton) {
            searchButton.addEventListener(
                "click",
                () =>
                    this.loadIPAMRecords()
            );
        }


        const refreshButton =
            document.getElementById(
                "ipam-refresh-button"
            );

        if (refreshButton) {
            refreshButton.addEventListener(
                "click",
                () => {

                    document
                        .getElementById(
                            "ipam-search"
                        )
                        .value = "";

                    this.loadIPAMRecords();
                }
            );
        }


        const searchInput =
            document.getElementById(
                "ipam-search"
            );

        if (searchInput) {
            searchInput.addEventListener(
                "keydown",
                event => {

                    if (event.key === "Enter") {
                        this.loadIPAMRecords();
                    }
                }
            );
        }


        const newButton =
            document.getElementById(
                "ipam-new-button"
            );

        if (newButton) {
            newButton.addEventListener(
                "click",
                () =>
                    this.resetIPAMForm()
            );
        }


        const saveRecordButton =
            document.getElementById(
                "ipam-save-record-button"
            );

        if (saveRecordButton) {
            saveRecordButton.addEventListener(
                "click",
                () =>
                    this.saveIPAMRecord()
            );
        }


        const importButton =
            document.getElementById(
                "ipam-import-button"
            );

        const importFile =
            document.getElementById(
                "ipam-import-file"
            );

        if (
            importButton &&
            importFile
        ) {

            importButton.addEventListener(
                "click",
                () =>
                    importFile.click()
            );


            importFile.addEventListener(
                "change",
                async () => {

                    const file =
                        importFile.files?.[0];

                    if (!file) {
                        return;
                    }

                    await this.importIPAMCsv(
                        file
                    );

                    importFile.value = "";
                }
            );
        }


        const exportButton =
            document.getElementById(
                "ipam-export-button"
            );

        if (exportButton) {

            exportButton.addEventListener(
                "click",
                () =>
                    this.exportIPAMCsv()
            );
        }
    }


    async calculateIPAM() {

        const input =
            document.getElementById(
                "ipam-cidr"
            );

        const results =
            document.getElementById(
                "ipam-calc-results"
            );

        const network =
            input.value.trim();

        if (!network) {

            this.toast(
                "Enter an IPv4/CIDR value.",
                "warning"
            );

            return;
        }

        try {

            const response =
                await API.ipamCalculate(
                    network
                );

            const data =
                response.result;


            results.innerHTML = "";


            Object.entries(data)
                .forEach(([key, value]) => {

                    const item =
                        document.createElement(
                            "div"
                        );

                    item.className =
                        "ipam-result-card";

                    item.innerHTML = `
                        <span>
                            ${this.escapeHTML(
                                key.replace(
                                    /_/g,
                                    " "
                                )
                            )}
                        </span>

                        <strong>
                            ${this.escapeHTML(
                                String(value)
                            )}
                        </strong>
                    `;

                    results.appendChild(
                        item
                    );
                });


            this.toast(
                "Subnet calculation completed.",
                "success"
            );

        }
        catch (err) {

            this.toast(
                err.message,
                "error"
            );
        }
    }


    async generateVLSM() {

        const network =
            document
                .getElementById(
                    "vlsm-network"
                )
                .value
                .trim();


        const text =
            document
                .getElementById(
                    "vlsm-requirements"
                )
                .value;


        const output =
            document.getElementById(
                "vlsm-result"
            );


        if (!network) {

            this.toast(
                "Enter the parent network.",
                "warning"
            );

            return;
        }


        const requirements = [];


        text.split(/\r?\n/)
            .map(line => line.trim())
            .filter(Boolean)
            .forEach(line => {

                const parts =
                    line.split(",");

                if (parts.length < 2) {
                    return;
                }

                const name =
                    parts[0].trim();

                const hosts =
                    Number(
                        parts[1].trim()
                    );

                if (
                    name &&
                    Number.isInteger(hosts) &&
                    hosts > 0
                ) {

                    requirements.push({
                        name,
                        hosts
                    });
                }
            });


        if (!requirements.length) {

            this.toast(
                "Enter at least one valid VLSM requirement.",
                "warning"
            );

            return;
        }


        try {

            const response =
                await API.ipamVlsm(
                    network,
                    requirements
                );


            const plan =
                response.plan || [];


            if (!plan.length) {

                output.innerHTML = `
                    <div class="empty-state">
                        No VLSM allocations returned.
                    </div>
                `;

                return;
            }


            const columns =
                Object.keys(plan[0]);


            let html = `
                <table class="ipam-table">
                    <thead>
                        <tr>
            `;


            columns.forEach(column => {

                html += `
                    <th>
                        ${this.escapeHTML(
                            column.replace(
                                /_/g,
                                " "
                            )
                        )}
                    </th>
                `;
            });


            html += `
                        </tr>
                    </thead>
                    <tbody>
            `;


            plan.forEach(row => {

                html += "<tr>";

                columns.forEach(column => {

                    html += `
                        <td>
                            ${this.escapeHTML(
                                String(
                                    row[column] ?? ""
                                )
                            )}
                        </td>
                    `;
                });

                html += "</tr>";
            });


            html += `
                    </tbody>
                </table>
            `;


            output.innerHTML =
                html;


            this.toast(
                "VLSM plan generated successfully.",
                "success"
            );

        }
        catch (err) {

            this.toast(
                err.message,
                "error"
            );
        }
    }


    ipamStatusClass(status) {

        const value =
            String(status || "")
                .trim()
                .toLowerCase();


        if (value === "assigned") {
            return "assigned";
        }

        if (value === "reserved") {
            return "reserved";
        }

        if (value === "available") {
            return "available";
        }

        return "unknown";
    }


    async loadIPAMRecords() {

        const body =
            document.getElementById(
                "ipam-records-body"
            );

        if (!body) {
            return;
        }


        const search =
            document
                .getElementById(
                    "ipam-search"
                )
                .value
                .trim();


        try {

            const response =
                await API.ipamList(
                    search
                );


            const records =
                response.records || [];


            document
                .getElementById(
                    "ipam-record-count"
                )
                .textContent =
                    `${records.length} records`;


            const summary = {
                total: records.length,
                assigned: 0,
                reserved: 0,
                available: 0
            };


            records.forEach(record => {

                const status =
                    String(
                        record[7] ?? ""
                    )
                    .trim()
                    .toLowerCase();


                if (status === "assigned") {
                    summary.assigned++;
                }
                else if (status === "reserved") {
                    summary.reserved++;
                }
                else if (status === "available") {
                    summary.available++;
                }
            });


            document
                .getElementById(
                    "ipam-summary-total"
                )
                .textContent =
                    summary.total;


            document
                .getElementById(
                    "ipam-summary-assigned"
                )
                .textContent =
                    summary.assigned;


            document
                .getElementById(
                    "ipam-summary-reserved"
                )
                .textContent =
                    summary.reserved;


            document
                .getElementById(
                    "ipam-summary-available"
                )
                .textContent =
                    summary.available;


            body.innerHTML = "";


            if (!records.length) {

                body.innerHTML = `
                    <tr>
                        <td
                            colspan="9"
                            class="ipam-empty-row"
                        >
                            No IPAM records found.
                        </td>
                    </tr>
                `;

                return;
            }


            records.forEach(record => {

                const row =
                    document.createElement(
                        "tr"
                    );


                row.innerHTML = `
                    <td>
                        ${this.escapeHTML(
                            String(record[0] ?? "")
                        )}
                    </td>

                    <td>
                        ${this.escapeHTML(
                            String(record[1] ?? "")
                        )}
                    </td>

                    <td>
                        /${this.escapeHTML(
                            String(record[2] ?? "")
                        )}
                    </td>

                    <td>
                        ${this.escapeHTML(
                            String(record[3] ?? "")
                        )}
                    </td>

                    <td>
                        ${this.escapeHTML(
                            String(record[4] ?? "")
                        )}
                    </td>

                    <td>
                        ${this.escapeHTML(
                            String(record[5] ?? "")
                        )}
                    </td>

                    <td>
                        ${this.escapeHTML(
                            String(record[6] ?? "")
                        )}
                    </td>

                    <td>
                        <span
                            class="ipam-status-badge ${
                                this.ipamStatusClass(
                                    record[7]
                                )
                            }"
                        >
                            ${this.escapeHTML(
                                String(record[7] ?? "")
                            )}
                        </span>
                    </td>

                    <td>
                        <div class="ipam-actions">

                            <button
                                class="btn btn-ghost ipam-edit-button"
                                data-id="${record[0]}"
                            >
                                Edit
                            </button>

                            <button
                                class="btn btn-danger ipam-delete-button"
                                data-id="${record[0]}"
                            >
                                Delete
                            </button>

                        </div>
                    </td>
                `;


                body.appendChild(
                    row
                );
            });


            body
                .querySelectorAll(
                    ".ipam-edit-button"
                )
                .forEach(button => {

                    button.addEventListener(
                        "click",
                        () =>
                            this.editIPAMRecord(
                                Number(
                                    button.dataset.id
                                )
                            )
                    );
                });


            body
                .querySelectorAll(
                    ".ipam-delete-button"
                )
                .forEach(button => {

                    button.addEventListener(
                        "click",
                        () =>
                            this.deleteIPAMRecord(
                                Number(
                                    button.dataset.id
                                )
                            )
                    );
                });

        }
        catch (err) {

            this.toast(
                err.message,
                "error"
            );
        }
    }


    async editIPAMRecord(recordId) {

        try {

            const response =
                await API.ipamGet(
                    recordId
                );


            const record =
                response.record;


            if (!record) {
                return;
            }


            document
                .getElementById(
                    "ipam-record-id"
                )
                .value =
                    record[0] ?? "";


            document
                .getElementById(
                    "ipam-address"
                )
                .value =
                    record[1] ?? "";


            document
                .getElementById(
                    "ipam-prefix"
                )
                .value =
                    record[2] ?? 24;


            document
                .getElementById(
                    "ipam-hostname"
                )
                .value =
                    record[3] ?? "";


            document
                .getElementById(
                    "ipam-device-type"
                )
                .value =
                    record[4] ?? "";


            document
                .getElementById(
                    "ipam-vlan"
                )
                .value =
                    record[5] ?? "";


            document
                .getElementById(
                    "ipam-location"
                )
                .value =
                    record[6] ?? "";


            document
                .getElementById(
                    "ipam-status"
                )
                .value =
                    record[7] ?? "Assigned";


            document
                .getElementById(
                    "ipam-description"
                )
                .value =
                    record[8] ?? "";


            document
                .getElementById(
                    "ipam-form-title"
                )
                .textContent =
                    "Edit IP Allocation";


            document
                .getElementById(
                    "ipam-save-record-button"
                )
                .textContent =
                    "Update IP Allocation";


            this.toast(
                `Editing record ${recordId}.`,
                "success"
            );

        }
        catch (err) {

            this.toast(
                err.message,
                "error"
            );
        }
    }


    collectIPAMRecord() {

        return {

            ip_address:
                document
                    .getElementById(
                        "ipam-address"
                    )
                    .value
                    .trim(),

            prefix:
                Number(
                    document
                        .getElementById(
                            "ipam-prefix"
                        )
                        .value
                ),

            hostname:
                document
                    .getElementById(
                        "ipam-hostname"
                    )
                    .value
                    .trim(),

            device_type:
                document
                    .getElementById(
                        "ipam-device-type"
                    )
                    .value
                    .trim(),

            vlan:
                document
                    .getElementById(
                        "ipam-vlan"
                    )
                    .value
                    .trim(),

            location:
                document
                    .getElementById(
                        "ipam-location"
                    )
                    .value
                    .trim(),

            status:
                document
                    .getElementById(
                        "ipam-status"
                    )
                    .value,

            description:
                document
                    .getElementById(
                        "ipam-description"
                    )
                    .value
                    .trim()
        };
    }


    async saveIPAMRecord() {

        const record =
            this.collectIPAMRecord();


        if (!record.ip_address) {

            this.toast(
                "IP Address is required.",
                "warning"
            );

            return;
        }


        if (
            !Number.isInteger(
                record.prefix
            ) ||
            record.prefix < 0 ||
            record.prefix > 32
        ) {

            this.toast(
                "Prefix must be between 0 and 32.",
                "warning"
            );

            return;
        }


        const recordId =
            document
                .getElementById(
                    "ipam-record-id"
                )
                .value;


        try {

            if (recordId) {

                await API.ipamUpdate(
                    Number(recordId),
                    record
                );


                this.toast(
                    "IP allocation updated.",
                    "success"
                );

            }
            else {

                await API.ipamAdd(
                    record
                );


                this.toast(
                    "IP allocation added.",
                    "success"
                );
            }


            this.resetIPAMForm();

            await this.loadIPAMRecords();

        }
        catch (err) {

            this.toast(
                err.message,
                "error"
            );
        }
    }


    async deleteIPAMRecord(recordId) {

        const confirmed =
            confirm(
                `Delete IPAM record ${recordId}?`
            );


        if (!confirmed) {
            return;
        }


        try {

            await API.ipamDelete(
                recordId
            );


            this.toast(
                "IP allocation deleted.",
                "success"
            );


            this.resetIPAMForm();

            await this.loadIPAMRecords();

        }
        catch (err) {

            this.toast(
                err.message,
                "error"
            );
        }
    }


    resetIPAMForm() {

        const fields = [
            "ipam-record-id",
            "ipam-address",
            "ipam-hostname",
            "ipam-device-type",
            "ipam-vlan",
            "ipam-location",
            "ipam-description"
        ];


        fields.forEach(id => {

            const element =
                document.getElementById(
                    id
                );

            if (element) {
                element.value = "";
            }
        });


        document
            .getElementById(
                "ipam-prefix"
            )
            .value = "24";


        document
            .getElementById(
                "ipam-status"
            )
            .value = "Assigned";


        document
            .getElementById(
                "ipam-form-title"
            )
            .textContent =
                "Add IP Allocation";


        document
            .getElementById(
                "ipam-save-record-button"
            )
            .textContent =
                "Save IP Allocation";
    }


    async importIPAMCsv(file) {

        if (
            !file.name
                .toLowerCase()
                .endsWith(".csv")
        ) {

            this.toast(
                "Select a CSV file.",
                "warning"
            );

            return;
        }


        try {

            const response =
                await API.ipamImportCsv(
                    file
                );


            this.toast(
                `CSV imported: ${
                    response.filename || file.name
                }`,
                "success"
            );


            await this.loadIPAMRecords();

        }
        catch (err) {

            this.toast(
                err.message,
                "error"
            );
        }
    }


    exportIPAMCsv() {

        try {

            const url =
                API.ipamExportUrl();


            const anchor =
                document.createElement(
                    "a"
                );


            anchor.href = url;

            anchor.download =
                "netforge-ipam-export.csv";


            document.body.appendChild(
                anchor
            );

            anchor.click();

            anchor.remove();


            this.toast(
                "IPAM CSV export started.",
                "success"
            );

        }
        catch (err) {

            this.toast(
                err.message,
                "error"
            );
        }
    }


    bindBuild() {

        document
            .getElementById(
                "clear-build-button"
            )
            .addEventListener(
                "click",
                () => {

                    if (!Builder.count()) {

                        this.toast(
                            "Build is already empty.",
                            "warning"
                        );

                        return;
                    }


                    const confirmed =
                        confirm(
                            "Remove all sections from the current build?"
                        );


                    if (!confirmed) {
                        return;
                    }


                    Builder.clear();

                    this.updateBuildUI();

                    this.toast(
                        "Build cleared.",
                        "success"
                    );
                }
            );


        document
            .getElementById(
                "export-build-button"
            )
            .addEventListener(
                "click",
                () =>
                    this.exportBuild()
            );


        document
            .getElementById(
                "copy-build-button"
            )
            .addEventListener(
                "click",
                () =>
                    this.copyText(
                        Builder.fullBuild()
                    )
            );
    }


    updateBuildUI() {

        const count =
            Builder.count();


        this.el.buildCount.textContent =
            count;

        this.el.dashboardBuildCount
            .textContent =
                count;

        this.el.buildTotal.textContent =
            count;


        this.el.buildOutput.textContent =
            Builder.fullBuild();


        this.el.buildList.innerHTML =
            "";


        if (!count) {

            this.el.buildList.innerHTML = `
                <div class="build-empty">
                    No configuration sections
                    have been added yet.
                </div>
            `;

            return;
        }


        Builder.sections.forEach(
            (section, index) => {

                const item =
                    document.createElement(
                        "div"
                    );

                item.className =
                    "build-item";


                item.innerHTML = `
                    <div class="build-item-top">

                        <strong>
                            Section ${
                                index + 1
                            }
                        </strong>

                        <button
                            class="build-remove"
                            data-index="${
                                index
                            }"
                            title="Remove"
                        >
                            ×
                        </button>

                    </div>

                    <div class="build-item-meta">

                        <span class="build-chip">
                            ${this.escapeHTML(
                                section.vendor
                            )}
                        </span>

                        <span class="build-chip">
                            ${this.escapeHTML(
                                section.platform || ""
                            )}
                        </span>

                        <span class="build-chip">
                            ${this.escapeHTML(
                                section.technology
                            )}
                        </span>

                    </div>
                `;


                this.el.buildList
                    .appendChild(
                        item
                    );
            }
        );


        this.el.buildList
            .querySelectorAll(
                ".build-remove"
            )
            .forEach(button => {

                button.addEventListener(
                    "click",
                    () => {

                        Builder.remove(
                            Number(
                                button.dataset.index
                            )
                        );

                        this.updateBuildUI();

                        this.toast(
                            "Build section removed.",
                            "success"
                        );
                    }
                );
            });
    }


    exportBuild() {

        if (!Builder.count()) {

            this.toast(
                "Build is empty.",
                "warning"
            );

            return;
        }


        const filename =
            `NETOPS-Full-Build-${
                this.timestamp()
            }.cfg`;


        this.download(
            Builder.fullBuild(),
            filename
        );


        this.toast(
            `Exported ${filename}`,
            "success"
        );
    }


    /* =======================================================
       UTILITIES
       ======================================================= */

    async copyText(text) {

        if (!text) {

            this.toast(
                "Nothing to copy.",
                "warning"
            );

            return;
        }


        try {

            await navigator.clipboard
                .writeText(text);


            this.toast(
                "Copied to clipboard.",
                "success"
            );

        }
        catch {

            const area =
                document.createElement(
                    "textarea"
                );

            area.value = text;

            document.body.appendChild(
                area
            );

            area.select();

            document.execCommand(
                "copy"
            );

            area.remove();


            this.toast(
                "Copied to clipboard.",
                "success"
            );
        }
    }


    download(content, filename) {

        const blob =
            new Blob(
                [content + "\n"],
                {
                    type:
                        "text/plain;charset=utf-8"
                }
            );


        const url =
            URL.createObjectURL(
                blob
            );


        const anchor =
            document.createElement(
                "a"
            );


        anchor.href = url;
        anchor.download = filename;

        document.body.appendChild(
            anchor
        );

        anchor.click();

        anchor.remove();


        URL.revokeObjectURL(
            url
        );
    }


    safeFilename(value) {

        return String(value || "")
            .replace(
                /[^a-zA-Z0-9_-]+/g,
                "-"
            )
            .replace(
                /-+/g,
                "-"
            )
            .replace(
                /^-|-$/g,
                ""
            );
    }


    timestamp() {

        const date =
            new Date();


        const pad =
            value =>
                String(value)
                    .padStart(
                        2,
                        "0"
                    );


        return (
            date.getFullYear() +
            pad(
                date.getMonth() + 1
            ) +
            pad(
                date.getDate()
            ) +
            "-" +
            pad(
                date.getHours()
            ) +
            pad(
                date.getMinutes()
            ) +
            pad(
                date.getSeconds()
            )
        );
    }


    toast(
        message,
        type = "info"
    ) {

        const container =
            document.getElementById(
                "toast-container"
            );


        const toast =
            document.createElement(
                "div"
            );


        toast.className =
            `toast ${type}`;


        toast.textContent =
            message;


        container.appendChild(
            toast
        );


        setTimeout(
            () => {

                toast.remove();

            },
            4200
        );
    }


    escapeHTML(value) {

        const element =
            document.createElement(
                "div"
            );

        element.textContent =
            String(
                value ?? ""
            );

        return element.innerHTML;
    }


    escapeAttribute(value) {

        return String(
            value ?? ""
        )
        .replace(
            /&/g,
            "&amp;"
        )
        .replace(
            /"/g,
            "&quot;"
        )
        .replace(
            /</g,
            "&lt;"
        )
        .replace(
            />/g,
            "&gt;"
        );
    }

}


document.addEventListener(
    "DOMContentLoaded",
    () => {

        window.NETOPS =
            new NetOpsApp();

    }
);