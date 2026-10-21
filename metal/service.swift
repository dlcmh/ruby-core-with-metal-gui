import AppKit
import MetalKit
import QuartzCore
import simd

// MARK: - GPU side

private struct Uniforms {
    var resolution: SIMD2<Float>
    var angle: Float
}

// Kept in the executable so the demo has no runtime asset dependencies.
private let shaderSource = """
#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float2 resolution;
    float angle;
};

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut square_vertex(uint vertexID [[vertex_id]],
                               constant Uniforms &uniforms [[buffer(0)]]) {
    const float2 corners[4] = {
        float2(-0.5, -0.5),
        float2( 0.5, -0.5),
        float2(-0.5,  0.5),
        float2( 0.5,  0.5)
    };

    float2 point = corners[vertexID] * 0.9;

    float sine = sin(uniforms.angle);
    float cosine = cos(uniforms.angle);
    point = float2(point.x * cosine - point.y * sine,
                   point.x * sine + point.y * cosine);

    // NDC is -1...1 on both axes, so correcting x by the aspect ratio keeps
    // this quad square when the window is resized.
    point.x *= uniforms.resolution.y / max(uniforms.resolution.x, 1.0);

    VertexOut out;
    out.position = float4(point, 0.0, 1.0);
    return out;
}

fragment float4 square_fragment() {
    return float4(0.98, 0.44, 0.12, 1.0);
}
"""

private final class Renderer: NSObject, MTKViewDelegate {
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let speed: Float

    private var angle: Float = 0
    private var previousFrameTime = CACurrentMediaTime()

    init?(view: MTKView, device: MTLDevice, speed: Float) {
        guard let commandQueue = device.makeCommandQueue() else {
            fputs("[metal-service] could not create a command queue\n", stderr)
            return nil
        }

        do {
            let library = try device.makeLibrary(source: shaderSource, options: nil)

            guard
                let vertexFunction = library.makeFunction(name: "square_vertex"),
                let fragmentFunction = library.makeFunction(name: "square_fragment")
            else {
                fputs("[metal-service] shader functions are missing\n", stderr)
                return nil
            }

            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.label = "Rotating square"
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat

            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fputs("[metal-service] could not create the render pipeline: \(error)\n", stderr)
            return nil
        }

        self.commandQueue = commandQueue
        self.speed = speed
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        let deltaTime = Float(min(max(now - previousFrameTime, 0), 1.0 / 15.0))
        previousFrameTime = now
        angle = (angle + speed * deltaTime).truncatingRemainder(dividingBy: .pi * 2)

        guard
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            return
        }

        var uniforms = Uniforms(
            resolution: SIMD2<Float>(
                Float(view.drawableSize.width),
                Float(view.drawableSize.height)
            ),
            angle: angle
        )

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - AppKit window

private final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let speed: Float
    private var window: NSWindow?
    private var renderer: Renderer?

    init(speed: Float) {
        self.speed = speed
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMainMenu()

        guard let device = MTLCreateSystemDefaultDevice() else {
            fputs("[metal-service] this Mac does not provide a Metal device\n", stderr)
            NSApp.terminate(nil)
            return
        }

        let contentRect = NSRect(x: 0, y: 0, width: 800, height: 600)
        let view = MTKView(frame: contentRect, device: device)
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0.035, green: 0.04, blue: 0.07, alpha: 1)
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = false

        guard let renderer = Renderer(view: view, device: device, speed: speed) else {
            NSApp.terminate(nil)
            return
        }

        view.delegate = renderer
        self.renderer = renderer

        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Ruby Core · Metal"
        window.contentView = view
        window.minSize = NSSize(width: 360, height: 360)
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        self.window = window

        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func installMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        let appName = ProcessInfo.processInfo.processName

        appMenu.addItem(
            withTitle: "Quit \(appName)",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }
}

// MARK: - Entry point

private func requestedSpeed() -> Float {
    let arguments = CommandLine.arguments

    if arguments.contains("--help") || arguments.contains("-h") {
        print("Usage: metal-service [--speed RADIANS_PER_SECOND]")
        exit(0)
    }

    guard
        let flagIndex = arguments.firstIndex(of: "--speed"),
        arguments.indices.contains(flagIndex + 1),
        let speed = Float(arguments[flagIndex + 1]),
        speed.isFinite
    else {
        return 0.9
    }

    return speed
}

let application = NSApplication.shared
private let appDelegate = AppDelegate(speed: requestedSpeed())
application.delegate = appDelegate
application.setActivationPolicy(.regular)
application.run()
