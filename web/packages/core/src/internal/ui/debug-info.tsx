import { text } from "../i18n.js";
import { isExtension } from "../../current-script.js";
import { buildInfo } from "../../build-info.js";
import { RUFFLE_ORIGIN } from "../constants.js";

/**
 * @returns The HTMLElement containing the debug info modal
 */
export function DebugInfo() {
    return (
        <div id="debug-info-modal" class="modal hidden">
            <div class="modal-area">
                <div id="debug-info-header">
                    <a href={RUFFLE_ORIGIN} target="_blank">
                        {text("context-menu-about-ruffle", {
                            flavor: isExtension ? "extension" : "",
                            version: buildInfo.versionName,
                        })}
                    </a>
                    <span id="debug-info-copy" class="modal-button">
                        {text("debug-info-copy")}
                    </span>
                    <span class="close-modal"></span>
                </div>
                <textarea id="debug-info-text" readOnly></textarea>
            </div>
        </div>
    );
}
