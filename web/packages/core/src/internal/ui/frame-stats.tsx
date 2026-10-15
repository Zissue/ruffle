import type { RuffleHandle } from "../../../dist/ruffle_web.js";

const GRAPH_SAMPLES = 64;
const BAR_WIDTH = 2;
const BAR_STEP = 3;
const GRAPH_WIDTH = GRAPH_SAMPLES * BAR_STEP;
const GRAPH_HEIGHT = 40;
const TEXT_INTERVAL_MS = 500;
const HUD_MARGIN = 8;
const MIN_SCALE_MS = 4;
const LOGIC_COLOR = "#3987e5";
const RENDER_COLOR = "#d95926";

/**
 * @returns The HTMLElement containing the frame stats overlay
 */
export function FrameStats() {
    return (
        <div id="frame-stats" class="hidden">
            <div id="frame-stats-renderer"></div>
            <dl>
                <dt>FPS</dt>
                <dd id="frame-stats-fps"></dd>
                <dt class="frame-stats-logic">Logic</dt>
                <dd id="frame-stats-logic"></dd>
                <dt class="frame-stats-render">Render</dt>
                <dd id="frame-stats-render"></dd>
                <dt>Memory</dt>
                <dd id="frame-stats-memory"></dd>
            </dl>
            <canvas id="frame-stats-graph"></canvas>
        </div>
    );
}

class Durations {
    sum = 0;
    max = 0;
    count = 0;

    add(ms: number) {
        this.sum += ms;
        this.max = Math.max(this.max, ms);
        this.count++;
    }

    format(): string {
        if (this.count === 0) {
            return "-";
        }
        return `${(this.sum / this.count).toFixed(1)} ms  max ${this.max.toFixed(1)}`;
    }
}

export class FrameStatsView {
    private readonly root: HTMLElement;
    private readonly container: HTMLElement;
    private readonly graph: HTMLCanvasElement;
    private readonly renderer: HTMLElement;
    private readonly fps: HTMLElement;
    private readonly logicText: HTMLElement;
    private readonly render: HTMLElement;
    private readonly memory: HTMLElement;

    private instance: RuffleHandle | null = null;
    private observing = false;
    private drawQueued = false;

    private readonly logicSamples = new Float64Array(GRAPH_SAMPLES);
    private readonly renderSamples = new Float64Array(GRAPH_SAMPLES);
    private samples = 0;
    private pendingLogicMs = 0;

    private frameRate = 0;
    private framesRun = 0;
    private memoryBytes = 0;
    private windowStart = 0;
    private windowFramesRun = 0;
    private logic = new Durations();
    private renders = new Durations();
    summary: string | null = null;

    constructor(root: HTMLElement, container: HTMLElement) {
        this.root = root;
        this.container = container;
        this.graph = root.querySelector(
            "#frame-stats-graph",
        ) as HTMLCanvasElement;
        this.renderer = root.querySelector("#frame-stats-renderer")!;
        this.fps = root.querySelector("#frame-stats-fps")!;
        this.logicText = root.querySelector("#frame-stats-logic")!;
        this.render = root.querySelector("#frame-stats-render")!;
        this.memory = root.querySelector("#frame-stats-memory")!;
        root.addEventListener("pointerdown", this.startDrag.bind(this));
    }

    private startDrag(event: PointerEvent) {
        if (event.button !== 0) {
            return;
        }
        event.preventDefault();
        this.root.setPointerCapture(event.pointerId);
        const hud = this.root.getBoundingClientRect();
        const grabX = event.clientX - hud.left;
        const grabY = event.clientY - hud.top;
        const fraction = (offset: number, range: number) =>
            range > 0 ? Math.min(Math.max(offset / range, 0), 1) : 0;
        const drag = (event: PointerEvent) => {
            const area = this.container.getBoundingClientRect();
            const x = fraction(
                event.clientX - grabX - area.left - HUD_MARGIN,
                area.width - hud.width - 2 * HUD_MARGIN,
            );
            const y = fraction(
                event.clientY - grabY - area.top - HUD_MARGIN,
                area.height - hud.height - 2 * HUD_MARGIN,
            );
            this.root.style.left = `calc(${HUD_MARGIN}px + ${x} * (100% - ${2 * HUD_MARGIN}px))`;
            this.root.style.top = `calc(${HUD_MARGIN}px + ${y} * (100% - ${2 * HUD_MARGIN}px))`;
            this.root.style.right = "auto";
            this.root.style.transform = `translate(${-x * 100}%, ${-y * 100}%)`;
        };
        this.root.addEventListener("pointermove", drag);
        this.root.addEventListener(
            "lostpointercapture",
            () => this.root.removeEventListener("pointermove", drag),
            { once: true },
        );
    }

    get visible(): boolean {
        return !this.root.classList.contains("hidden");
    }

    setVisible(visible: boolean) {
        this.root.classList.toggle("hidden", !visible);
        this.observe();
    }

    setInstance(instance: RuffleHandle | null) {
        this.instance = instance;
        this.observe();
    }

    private observe() {
        this.observing = this.visible && this.instance !== null;
        this.instance?.set_frame_observer(
            this.observing ? this.onFrame.bind(this) : null,
        );
        this.samples = 0;
        this.pendingLogicMs = 0;
        this.windowStart = 0;
    }

    private onFrame(
        tickMs: number,
        renderMs: number,
        framesRun: number,
        frameRate: number,
        memoryBytes: number,
    ) {
        this.framesRun = framesRun;
        this.frameRate = frameRate;
        this.memoryBytes = memoryBytes;
        this.pendingLogicMs += tickMs;
        if (renderMs < 0) {
            return;
        }
        const index = this.samples % GRAPH_SAMPLES;
        this.logicSamples[index] = this.pendingLogicMs;
        this.renderSamples[index] = renderMs;
        this.samples++;
        this.logic.add(this.pendingLogicMs);
        this.renders.add(renderMs);
        this.pendingLogicMs = 0;
        if (!this.drawQueued) {
            this.drawQueued = true;
            queueMicrotask(this.draw.bind(this));
        }
    }

    private draw() {
        this.drawQueued = false;
        if (!this.observing) {
            return;
        }
        const now = performance.now();
        if (this.windowStart === 0) {
            this.startWindow(now);
        } else if (now - this.windowStart >= TEXT_INTERVAL_MS) {
            this.updateText(now);
            this.startWindow(now);
        }
        this.drawGraph();
    }

    private startWindow(now: number) {
        this.windowStart = now;
        this.windowFramesRun = this.framesRun;
        this.logic = new Durations();
        this.renders = new Durations();
    }

    private updateText(now: number) {
        const canvas = this.container.querySelector("canvas");
        const size = canvas ? `  ${canvas.width}×${canvas.height}` : "";
        this.renderer.textContent = `${this.instance?.renderer_name() ?? ""}${size}`;
        const fps =
            ((this.framesRun - this.windowFramesRun) * 1000) /
            (now - this.windowStart);
        this.fps.textContent = `${fps.toFixed(1)} / ${Math.round(this.frameRate)}`;
        this.logicText.textContent = this.logic.format();
        this.render.textContent = this.renders.format();
        this.memory.textContent = `${Math.round(this.memoryBytes / (1024 * 1024))} MB`;
        this.summary = [
            `Renderer: ${this.renderer.textContent}`,
            `FPS: ${this.fps.textContent}`,
            `Logic per frame: ${this.logicText.textContent}`,
            `Render: ${this.render.textContent}`,
            `Wasm memory: ${this.memory.textContent}`,
        ].join("\n");
    }

    private drawGraph() {
        const scale = window.devicePixelRatio;
        const width = Math.round(GRAPH_WIDTH * scale);
        const height = Math.round(GRAPH_HEIGHT * scale);
        if (this.graph.width !== width || this.graph.height !== height) {
            this.graph.width = width;
            this.graph.height = height;
        }
        const context = this.graph.getContext("2d")!;
        context.setTransform(scale, 0, 0, scale, 0, 0);
        context.clearRect(0, 0, GRAPH_WIDTH, GRAPH_HEIGHT);

        const budgetMs = this.frameRate > 0 ? 1000 / this.frameRate : 1000 / 60;
        const count = Math.min(this.samples, GRAPH_SAMPLES);
        let slowestMs = 0;
        for (let i = 0; i < count; i++) {
            slowestMs = Math.max(
                slowestMs,
                this.logicSamples[i]! + this.renderSamples[i]!,
            );
        }
        const scaleMs = Math.min(
            2 * budgetMs,
            Math.max(MIN_SCALE_MS, slowestMs),
        );
        const pixelsPerMs = GRAPH_HEIGHT / scaleMs;
        for (let i = 0; i < count; i++) {
            const index = (this.samples - count + i) % GRAPH_SAMPLES;
            const x = GRAPH_WIDTH - (count - i) * BAR_STEP;
            const logicHeight = Math.min(
                this.logicSamples[index]! * pixelsPerMs,
                GRAPH_HEIGHT,
            );
            const renderHeight = Math.min(
                this.renderSamples[index]! * pixelsPerMs,
                GRAPH_HEIGHT - logicHeight,
            );
            context.fillStyle = LOGIC_COLOR;
            context.fillRect(
                x,
                GRAPH_HEIGHT - logicHeight,
                BAR_WIDTH,
                logicHeight,
            );
            context.fillStyle = RENDER_COLOR;
            context.fillRect(
                x,
                GRAPH_HEIGHT - logicHeight - renderHeight,
                BAR_WIDTH,
                renderHeight,
            );
        }

        if (budgetMs <= scaleMs) {
            const y = Math.round(GRAPH_HEIGHT - budgetMs * pixelsPerMs) + 0.5;
            context.strokeStyle = "rgb(255 255 255 / 0.5)";
            context.setLineDash([3, 3]);
            context.beginPath();
            context.moveTo(0, y);
            context.lineTo(GRAPH_WIDTH, y);
            context.stroke();
        }
        context.fillStyle = "#c3c2b7";
        context.font = "9px ui-monospace, monospace";
        context.textBaseline = "top";
        context.fillText(`${Math.round(scaleMs)} ms`, 0, 0);
    }
}
