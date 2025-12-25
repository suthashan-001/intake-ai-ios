#!/usr/bin/env swift

// App Icon Generator for IntakeAI
// Run this script to generate the app icon PNG files
// Usage: swift GenerateAppIcon.swift

import Cocoa
import CoreGraphics

// IntakeAI Brand Colors
let primaryColor = NSColor(red: 0.290, green: 0.486, blue: 0.349, alpha: 1.0) // Sage green
let primaryDarkColor = NSColor(red: 0.220, green: 0.400, blue: 0.275, alpha: 1.0)
let whiteColor = NSColor.white

func createAppIcon(size: CGFloat, isDark: Bool = false) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    // Background - gradient from primary to primaryDark
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.2237 // iOS app icon corner radius ratio
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Create gradient
    let gradient = NSGradient(starting: isDark ? primaryDarkColor : primaryColor,
                              ending: isDark ? primaryColor.withAlphaComponent(0.8) : primaryDarkColor)
    gradient?.draw(in: path, angle: 135)

    // Draw heart with plus icon
    let centerX = size / 2
    let centerY = size / 2
    let iconSize = size * 0.5

    // Heart shape
    let heartPath = NSBezierPath()
    let heartWidth = iconSize
    let heartHeight = iconSize * 0.9
    let startX = centerX - heartWidth / 2
    let startY = centerY - heartHeight / 3

    // Draw heart using bezier curves
    heartPath.move(to: NSPoint(x: centerX, y: startY - heartHeight * 0.35))

    // Right side of heart
    heartPath.curve(to: NSPoint(x: centerX + heartWidth/2, y: startY + heartHeight * 0.1),
                   controlPoint1: NSPoint(x: centerX + heartWidth * 0.1, y: startY - heartHeight * 0.35),
                   controlPoint2: NSPoint(x: centerX + heartWidth/2, y: startY - heartHeight * 0.15))

    heartPath.curve(to: NSPoint(x: centerX, y: startY + heartHeight * 0.55),
                   controlPoint1: NSPoint(x: centerX + heartWidth/2, y: startY + heartHeight * 0.35),
                   controlPoint2: NSPoint(x: centerX + heartWidth * 0.25, y: startY + heartHeight * 0.5))

    // Left side of heart
    heartPath.curve(to: NSPoint(x: centerX - heartWidth/2, y: startY + heartHeight * 0.1),
                   controlPoint1: NSPoint(x: centerX - heartWidth * 0.25, y: startY + heartHeight * 0.5),
                   controlPoint2: NSPoint(x: centerX - heartWidth/2, y: startY + heartHeight * 0.35))

    heartPath.curve(to: NSPoint(x: centerX, y: startY - heartHeight * 0.35),
                   controlPoint1: NSPoint(x: centerX - heartWidth/2, y: startY - heartHeight * 0.15),
                   controlPoint2: NSPoint(x: centerX - heartWidth * 0.1, y: startY - heartHeight * 0.35))

    heartPath.close()

    // Fill heart with white
    whiteColor.setFill()
    heartPath.fill()

    // Draw plus sign inside heart
    let plusColor = isDark ? primaryDarkColor : primaryColor
    plusColor.setFill()

    let plusSize = iconSize * 0.25
    let plusThickness = plusSize * 0.25
    let plusCenterY = startY + heartHeight * 0.1

    // Horizontal bar
    let horizontalBar = NSRect(
        x: centerX - plusSize/2,
        y: plusCenterY - plusThickness/2,
        width: plusSize,
        height: plusThickness
    )
    NSBezierPath(roundedRect: horizontalBar, xRadius: plusThickness/2, yRadius: plusThickness/2).fill()

    // Vertical bar
    let verticalBar = NSRect(
        x: centerX - plusThickness/2,
        y: plusCenterY - plusSize/2,
        width: plusThickness,
        height: plusSize
    )
    NSBezierPath(roundedRect: verticalBar, xRadius: plusThickness/2, yRadius: plusThickness/2).fill()

    // Draw document lines at the bottom of heart (representing intake form)
    let lineColor = isDark ? primaryDarkColor.withAlphaComponent(0.8) : primaryColor.withAlphaComponent(0.8)
    lineColor.setStroke()

    let lineWidth: CGFloat = plusThickness * 0.6
    let lineSpacing = lineWidth * 2.5
    let lineStartY = plusCenterY - plusSize/2 - lineSpacing * 1.5
    let lineEndX = centerX + plusSize * 0.6
    let lineStartX = centerX - plusSize * 0.6

    for i in 0..<3 {
        let linePath = NSBezierPath()
        let y = lineStartY - CGFloat(i) * lineSpacing
        let width = i == 2 ? (lineEndX - lineStartX) * 0.6 : (lineEndX - lineStartX)
        linePath.move(to: NSPoint(x: lineStartX, y: y))
        linePath.line(to: NSPoint(x: lineStartX + width, y: y))
        linePath.lineWidth = lineWidth
        linePath.lineCapStyle = .round
        linePath.stroke()
    }

    image.unlockFocus()

    return image
}

func saveImage(_ image: NSImage, to path: String) {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        print("Failed to create CGImage")
        return
    }

    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    bitmapRep.size = image.size

    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Saved: \(path)")
    } catch {
        print("Failed to save: \(error)")
    }
}

// Main execution
let scriptPath = CommandLine.arguments[0]
let scriptURL = URL(fileURLWithPath: scriptPath)
let projectDir = scriptURL.deletingLastPathComponent()
let iconDir = projectDir.appendingPathComponent("IntakeAI/Assets.xcassets/AppIcon.appiconset")

// Generate icons
let icon1024 = createAppIcon(size: 1024, isDark: false)
let icon1024Dark = createAppIcon(size: 1024, isDark: true)

saveImage(icon1024, to: iconDir.appendingPathComponent("AppIcon.png").path)
saveImage(icon1024Dark, to: iconDir.appendingPathComponent("AppIcon-Dark.png").path)

print("\nApp icons generated successfully!")
print("Location: \(iconDir.path)")
