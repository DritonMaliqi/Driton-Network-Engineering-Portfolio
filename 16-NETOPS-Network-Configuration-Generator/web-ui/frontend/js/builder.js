const Builder = {

    storageKey: "netops_project16_build",

    sections: [],


    load() {

        try {

            const stored =
                localStorage.getItem(
                    this.storageKey
                );

            if (stored) {

                const parsed =
                    JSON.parse(stored);

                if (Array.isArray(parsed)) {
                    this.sections = parsed;
                }
            }

        }
        catch {
            this.sections = [];
        }

        return this.sections;
    },


    save() {

        localStorage.setItem(
            this.storageKey,
            JSON.stringify(
                this.sections
            )
        );
    },


    add(section) {

        const normalized =
            String(section.config || "")
                .trim()
                .replace(/\r\n/g, "\n");


        const duplicate =
            this.sections.some(
                existing =>
                    String(
                        existing.config || ""
                    )
                    .trim()
                    .replace(/\r\n/g, "\n")
                    === normalized
            );


        if (duplicate) {
            return false;
        }


        this.sections.push({
            ...section,
            addedAt:
                new Date().toISOString()
        });


        this.save();

        return true;
    },


    remove(index) {

        if (
            index < 0 ||
            index >= this.sections.length
        ) {
            return;
        }

        this.sections.splice(
            index,
            1
        );

        this.save();
    },


    clear() {

        this.sections = [];

        localStorage.removeItem(
            this.storageKey
        );
    },


    count() {
        return this.sections.length;
    },


    fullBuild() {

        if (!this.sections.length) {
            return "# Build is empty.";
        }


        const output = [];


        this.sections.forEach(
            (section, index) => {

                output.push(
                    "############################################################"
                );

                output.push(
                    `# NETOPS BUILD SECTION ${
                        index + 1
                    }`
                );

                output.push(
                    `# Vendor: ${
                        section.vendor
                    }`
                );

                if (section.platform) {

                    output.push(
                        `# Platform: ${
                            section.platform
                        }`
                    );
                }

                output.push(
                    `# Technology: ${
                        section.technology
                    }`
                );

                output.push(
                    "############################################################"
                );

                output.push("");

                output.push(
                    String(
                        section.config || ""
                    ).trim()
                );

                output.push("");
            }
        );


        return output
            .join("\n")
            .trimEnd();
    }

};


Builder.load();