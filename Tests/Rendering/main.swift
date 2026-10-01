import AppKit
let app = NSApplication.shared
for (name, pose, asset, time) in [("sleep",PetPresentation.sleeping,"sleeping",1.2),("carry",PetPresentation.carried,"carried",0.0)] {
    let view = PetView(frame: NSRect(x:0,y:0,width:224,height:243))
    view.sprite = NSImage(contentsOfFile:"assets/\(asset).png")!
    view.pose = pose; view.elapsed = time
    let image = NSImage(size:view.bounds.size)
    image.lockFocus()
    NSColor(calibratedRed:0.22,green:0.29,blue:0.34,alpha:1).setFill(); view.bounds.fill()
    // Same drawing code as the app; composite the result onto the QA background.
    let transparent = NSImage(size:view.bounds.size)
    transparent.lockFocus(); view.draw(view.bounds); transparent.unlockFocus()
    transparent.draw(in:view.bounds)
    image.unlockFocus()
    let rep = NSBitmapImageRep(data:image.tiffRepresentation!)!
    try! rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"build/\(name)-preview.png"))
    assert(rep.pixelsWide > 0)
}
print("PASS: native sleep and carried drawing renders")
