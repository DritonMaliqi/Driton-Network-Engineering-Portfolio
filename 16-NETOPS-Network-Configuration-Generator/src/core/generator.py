class GeneratorRegistry:

    def __init__(self):
        self.generators = {}

    def register(self, vendor, technology, generator_function):
        key = (
            vendor.strip().lower(),
            technology.strip().lower()
        )

        self.generators[key] = generator_function

    def available(self):
        return sorted(self.generators.keys())

    def generate(self, vendor, technology, **kwargs):
        key = (
            vendor.strip().lower(),
            technology.strip().lower()
        )

        generator = self.generators.get(key)

        if not generator:
            raise KeyError(
                f"No generator registered for "
                f"{vendor} / {technology}"
            )

        return generator(**kwargs)
