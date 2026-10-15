interface UserAgentData {
    platform: string;
    getHighEntropyValues(hints: string[]): Promise<{
        fullVersionList?: { brand: string; version: string }[];
        platformVersion?: string;
        architecture?: string;
    }>;
}

interface Gpu {
    requestAdapter(): Promise<{
        info: {
            vendor: string;
            architecture: string;
            description: string;
            isFallbackAdapter?: boolean;
        };
    } | null>;
}

/**
 * Describes the browser and GPU as the browser reports them, which a
 * replaced user agent string doesn't show.
 *
 * @returns Lines of "Name: value" text.
 */
export async function describeSystem(): Promise<string> {
    const { userAgentData, gpu } = navigator as Navigator & {
        userAgentData?: UserAgentData;
        gpu?: Gpu;
    };
    const lines: string[] = [];
    if (userAgentData) {
        const { fullVersionList, platformVersion, architecture } =
            await userAgentData.getHighEntropyValues([
                "fullVersionList",
                "platformVersion",
                "architecture",
            ]);
        const brands = (fullVersionList ?? [])
            .filter(({ brand }) => !/not.a.brand/i.test(brand))
            .map(({ brand, version }) => `${brand} ${version}`);
        lines.push(`Browser: ${brands.join(", ")}`);
        lines.push(
            `OS: ${userAgentData.platform} ${platformVersion ?? ""} ${architecture ?? ""}`.trimEnd(),
        );
    }
    if (!gpu) {
        lines.push("WebGPU adapter: navigator.gpu is missing");
    } else {
        const adapter = await gpu.requestAdapter();
        if (!adapter) {
            lines.push("WebGPU adapter: none");
        } else {
            const { vendor, architecture, description, isFallbackAdapter } =
                adapter.info;
            const fallback = isFallbackAdapter ? " (fallback adapter)" : "";
            lines.push(
                `WebGPU adapter: ${[vendor, architecture, description].filter(Boolean).join(" ")}${fallback}`,
            );
        }
    }
    return lines.join("\n");
}
