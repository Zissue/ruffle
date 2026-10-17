import { injectRuffleAndWait, playAndMonitor } from "../utils.js";
import { expect } from "chai";
import { Config, Player, Setup } from "ruffle-core";

const UNDRAWN = [0, 0, 0, 0];
const BLUE = [0, 0, 255, 255];

async function createSuspendedPlayer() {
    await browser.url("http://localhost:4567/test_assets/js_api.html");
    await injectRuffleAndWait(browser);
    await browser.execute(async () => {
        const ruffle = (window.RufflePlayer as Setup.PublicAPI).newest();
        const player = ruffle!.createPlayer();
        player.id = "ruffle-player";
        player.ruffle().renderingSuspended = true;
        document.getElementById("test-container")!.appendChild(player);
        await player.ruffle().load({
            url: "/test_assets/example.swf",
            preferredRenderer: "canvas" as Config.RenderBackend,
        });
    });
    const player = await browser.$("#ruffle-player").getElement();
    await playAndMonitor(browser, player);
    return player;
}

async function centerPixel(player: WebdriverIO.Element) {
    return await browser.execute((playerElement) => {
        const canvas = (playerElement as HTMLElement).shadowRoot!.querySelector(
            "canvas",
        )!;
        const x = Math.floor(canvas.width / 2);
        const y = Math.floor(canvas.height / 2);
        return Array.from(
            canvas.getContext("2d")!.getImageData(x, y, 1, 1).data,
        );
    }, player);
}

async function waitForCenterPixel(
    player: WebdriverIO.Element,
    expected: number[],
    timeoutMsg: string,
) {
    await browser.waitUntil(
        async () =>
            JSON.stringify(await centerPixel(player)) ===
            JSON.stringify(expected),
        { timeoutMsg },
    );
}

async function setRenderingSuspended(
    player: WebdriverIO.Element,
    value: boolean,
) {
    await browser.execute(
        (playerElement, value) => {
            (
                playerElement as Player.PlayerElement
            ).ruffle().renderingSuspended = value;
        },
        player,
        value,
    );
}

async function waitForAnimationFrames(count: number) {
    await browser.execute(async (count) => {
        for (let i = 0; i < count; i++) {
            await new Promise((resolve) => requestAnimationFrame(resolve));
        }
    }, count);
}

describe("RufflePlayer.renderingSuspended", () => {
    it("runs the movie without drawing it, and draws it when turned off", async () => {
        const player = await createSuspendedPlayer();
        await waitForAnimationFrames(10);
        expect(await centerPixel(player)).to.deep.equal(UNDRAWN);

        await setRenderingSuspended(player, false);
        await waitForCenterPixel(
            player,
            BLUE,
            "Expected the movie to be drawn",
        );
    });

    it("draws a paused movie resized while suspended when turned off", async () => {
        const player = await createSuspendedPlayer();
        await browser.execute((playerElement) => {
            (playerElement as Player.PlayerElement).ruffle().suspend();
        }, player);
        await setRenderingSuspended(player, false);
        await waitForCenterPixel(
            player,
            BLUE,
            "Expected the movie to be drawn",
        );

        await setRenderingSuspended(player, true);
        await browser.execute((playerElement) => {
            (playerElement as HTMLElement).style.width = "300px";
        }, player);
        await waitForCenterPixel(
            player,
            UNDRAWN,
            "Expected the resize to clear the canvas",
        );
        await waitForAnimationFrames(10);
        expect(await centerPixel(player)).to.deep.equal(UNDRAWN);

        await setRenderingSuspended(player, false);
        await waitForCenterPixel(
            player,
            BLUE,
            "Expected the movie to be drawn",
        );
    });
});
