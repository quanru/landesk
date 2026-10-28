// Read-only macOS capture geometry probe. Does not create a capture stream,
// change display modes, or request screen recording permission.
#[cfg(target_os = "macos")]
fn main() -> std::io::Result<()> {
    let display = scrap::Display::primary()?;
    println!("capture={}x{} coordinate_scale={}", display.width(), display.height(), display.scale());
    Ok(())
}

#[cfg(not(target_os = "macos"))]
fn main() {}
