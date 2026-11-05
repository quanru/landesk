// Included in macos_impl to share the native event types and Enigo state.
impl Enigo {
    /// Set if ignore flags when posting events.
    pub fn set_ignore_flags(&mut self, ignore: bool) {
        self.ignore_flags = ignore;
    }

    ///
    pub fn reset_flag(&mut self) {
        self.flags = CGEventFlags::CGEventFlagNull;
    }

    ///
    pub fn add_flag(&mut self, key: &Key) {
        let flag = match key {
            &Key::CapsLock => CGEventFlags::CGEventFlagAlphaShift,
            &Key::Shift => CGEventFlags::CGEventFlagShift,
            &Key::Control => CGEventFlags::CGEventFlagControl,
            &Key::Alt => CGEventFlags::CGEventFlagAlternate,
            &Key::Meta => CGEventFlags::CGEventFlagCommand,
            &Key::NumLock => CGEventFlags::CGEventFlagNumericPad,
            _ => CGEventFlags::CGEventFlagNull,
        };
        self.flags |= flag;
    }

    // Since enigo (legacy mode) is deprecated, it is currently in maintenance only.
    fn post(&self, event: CGEvent, keycode: Option<u16>) {
        if !self.ignore_flags
            && matches!(keycode, Some(kVK_UpArrow | kVK_DownArrow | kVK_LeftArrow | kVK_RightArrow))
        {
            // Keep intrinsic arrow flags so macOS matches Control-Up and other
            // system shortcuts, as in LanDesk commit 74e43f92f.
            event.set_flags(self.flags
                | CGEventFlags::CGEventFlagSecondaryFn
                | CGEventFlags::CGEventFlagNumericPad);
            event.set_integer_value_field(EventField::EVENT_SOURCE_USER_DATA, ENIGO_INPUT_EXTRA_VALUE);
            event.post(CGEventTapLocation::HID);
            return;
        }
        if keycode == Some(kVK_F11) {
            // Some key events require the flags to work.
            // We can't simply set the flag to `CGEventFlags::CGEventFlagNull`.
            // eg. `F11` requires flags `CGEventFlags::CGEventFlagSecondaryFn | 0x20000000` to work.
            self.post_event(event, false);
        } else {
            // macOS system may use the previous event flag to generate the next event.
            // Only found this issue when locking the screen.
            // When we use enigo to lock the screen, the next mouse event will have the flag
            // `CGEventFlagControl | CGEventFlagCommand | 0x20000000`.
            // The key event will also have the flag `CGEventFlagControl | CGEventFlagCommand | 0x20000000`.
            // Therefore, we need to set the flag to `event.set_flags(self.flags)` to avoid this.
            self.post_event(event, true);
        }
    }

    fn post_event(&self, event: CGEvent, force_flags: bool) {
        if !self.ignore_flags && (force_flags || self.flags != CGEventFlags::CGEventFlagNull) {
            event.set_flags(self.flags);
        }
        event.set_integer_value_field(EventField::EVENT_SOURCE_USER_DATA, ENIGO_INPUT_EXTRA_VALUE);
        event.post(CGEventTapLocation::HID);
    }
}

impl MouseControllable for Enigo {
    fn as_any(&self) -> &dyn std::any::Any {
        self
    }

    fn as_mut_any(&mut self) -> &mut dyn std::any::Any {
        self
    }

    fn mouse_move_to(&mut self, x: i32, y: i32) {
        // For absolute movement, we don't set delta values
        // This maintains backward compatibility
        self.mouse_move_to_impl(x, y, None);
    }

    fn mouse_move_relative(&mut self, x: i32, y: i32) {
        let (display_width, display_height) = Self::main_display_size();
        let (current_x, y_inv) = Self::mouse_location_raw_coords();
        let current_y = (display_height as i32) - y_inv;
        // Use saturating arithmetic to prevent overflow/wraparound
        let mut new_x = current_x.saturating_add(x);
        let mut new_y = current_y.saturating_add(y);

        // Define screen center and edge margins for cursor reset
        let center_x = (display_width / 2) as i32;
        let center_y = (display_height / 2) as i32;
        // Margin calculation: 5% of the smaller screen dimension with a minimum of 50px.
        // This provides a comfortable buffer zone to detect when the cursor is approaching
        // screen edges, allowing us to reset it to center before it hits the boundary.
        // This ensures continuous relative mouse movement without getting stuck at edges.
        let margin = (display_width.min(display_height) / 20).max(50) as i32;

        // Check if cursor is approaching screen boundaries
        // Use saturating_sub to prevent negative thresholds on very small displays
        let right = (display_width as i32).saturating_sub(margin);
        let bottom = (display_height as i32).saturating_sub(margin);
        let near_edge = new_x < margin
            || new_x > right
            || new_y < margin
            || new_y > bottom;

        if near_edge {
            // Reset cursor to screen center to allow continuous movement
            // The delta values are still passed correctly for games/apps
            new_x = center_x;
            new_y = center_y;
        }

        // Clamp to screen bounds as a safety measure.
        // Use saturating_sub(1) to ensure coordinates don't exceed the last valid pixel.
        let max_x = (display_width as i32).saturating_sub(1).max(0);
        let max_y = (display_height as i32).saturating_sub(1).max(0);
        new_x = new_x.clamp(0, max_x);
        new_y = new_y.clamp(0, max_y);

        // Pass delta values for relative movement
        // This is critical for browser Pointer Lock API support
        // The delta fields (MOUSE_EVENT_DELTA_X/Y) are used by browsers
        // to calculate movementX/Y in Pointer Lock mode
        self.mouse_move_to_impl(new_x, new_y, Some((x, y)));
    }

    fn mouse_down(&mut self, button: MouseButton) -> crate::ResultType {
        let now = std::time::Instant::now();
        if let Some(t) = self.last_click_time {
            if t.elapsed().as_millis() as u32 <= self.double_click_interval {
                self.multiple_click += 1;
            } else {
                self.multiple_click = 1;
            }
        }
        self.last_click_time = Some(now);
        let (current_x, current_y) = Self::mouse_location();
        let (button, event_type, btn_value) = match button {
            MouseButton::Left => (CGMouseButton::Left, CGEventType::LeftMouseDown, None),
            MouseButton::Middle => (CGMouseButton::Center, CGEventType::OtherMouseDown, None),
            MouseButton::Right => (CGMouseButton::Right, CGEventType::RightMouseDown, None),
            MouseButton::Back => (
                CGMouseButton::Left,
                CGEventType::OtherMouseDown,
                Some(MOUSE_EVENT_BUTTON_NUMBER_BACK),
            ),
            MouseButton::Forward => (
                CGMouseButton::Left,
                CGEventType::OtherMouseDown,
                Some(MOUSE_EVENT_BUTTON_NUMBER_FORWARD),
            ),
            _ => {
                log::info!("Unsupported button {:?}", button);
                return Ok(());
            }
        };
        let dest = CGPoint::new(current_x as f64, current_y as f64);
        if let Some(src) = self.event_source.as_ref() {
            if let Ok(event) = CGEvent::new_mouse_event(src.clone(), event_type, dest, button) {
                if self.multiple_click > 1 {
                    event.set_integer_value_field(
                        EventField::MOUSE_EVENT_CLICK_STATE,
                        self.multiple_click,
                    );
                }
                if let Some(v) = btn_value {
                    event.set_integer_value_field(EventField::MOUSE_EVENT_BUTTON_NUMBER, v);
                }
                self.post(event, None);
            }
        }
        Ok(())
    }

    fn mouse_up(&mut self, button: MouseButton) {
        let (current_x, current_y) = Self::mouse_location();
        let (button, event_type, btn_value) = match button {
            MouseButton::Left => (CGMouseButton::Left, CGEventType::LeftMouseUp, None),
            MouseButton::Middle => (CGMouseButton::Center, CGEventType::OtherMouseUp, None),
            MouseButton::Right => (CGMouseButton::Right, CGEventType::RightMouseUp, None),
            MouseButton::Back => (
                CGMouseButton::Left,
                CGEventType::OtherMouseUp,
                Some(MOUSE_EVENT_BUTTON_NUMBER_BACK),
            ),
            MouseButton::Forward => (
                CGMouseButton::Left,
                CGEventType::OtherMouseUp,
                Some(MOUSE_EVENT_BUTTON_NUMBER_FORWARD),
            ),
            _ => {
                log::info!("Unsupported button {:?}", button);
                return;
            }
        };
        let dest = CGPoint::new(current_x as f64, current_y as f64);
        if let Some(src) = self.event_source.as_ref() {
            if let Ok(event) = CGEvent::new_mouse_event(src.clone(), event_type, dest, button) {
                if self.multiple_click > 1 {
                    event.set_integer_value_field(
                        EventField::MOUSE_EVENT_CLICK_STATE,
                        self.multiple_click,
                    );
                }
                if let Some(v) = btn_value {
                    event.set_integer_value_field(EventField::MOUSE_EVENT_BUTTON_NUMBER, v);
                }
                self.post(event, None);
            }
        }
    }

    fn mouse_click(&mut self, button: MouseButton) {
        self.mouse_down(button).ok();
        self.mouse_up(button);
    }

    fn mouse_scroll_x(&mut self, length: i32) {
        let mut scroll_direction = -1; // 1 left -1 right;
        let mut length = length;

        if length < 0 {
            length *= -1;
            scroll_direction *= -1;
        }

        if let Some(src) = self.event_source.as_ref() {
            for _ in 0..length {
                unsafe {
                    let mouse_ev = CGEventCreateScrollWheelEvent(
                        &src,
                        ScrollUnit::Line,
                        2, // CGWheelCount 1 = y 2 = xy 3 = xyz
                        0,
                        scroll_direction,
                    );

                    CGEventPost(CGEventTapLocation::HID, mouse_ev);
                    CFRelease(mouse_ev as *const std::ffi::c_void);
                }
            }
        }
    }

    fn mouse_scroll_y(&mut self, length: i32) {
        let mut scroll_direction = -1; // 1 left -1 right;
        let mut length = length;

        if length < 0 {
            length *= -1;
            scroll_direction *= -1;
        }

        if let Some(src) = self.event_source.as_ref() {
            for _ in 0..length {
                unsafe {
                    let mouse_ev = CGEventCreateScrollWheelEvent(
                        &src,
                        ScrollUnit::Line,
                        1, // CGWheelCount 1 = y 2 = xy 3 = xyz
                        scroll_direction,
                    );

                    CGEventPost(CGEventTapLocation::HID, mouse_ev);
                    CFRelease(mouse_ev as *const std::ffi::c_void);
                }
            }
        }
    }
}

// https://stackoverflow.
// com/questions/1918841/how-to-convert-ascii-character-to-cgkeycode

impl KeyboardControllable for Enigo {
    fn as_any(&self) -> &dyn std::any::Any {
        self
    }

    fn as_mut_any(&mut self) -> &mut dyn std::any::Any {
        self
    }

    fn key_sequence(&mut self, sequence: &str) {
        // NOTE(dustin): This is a fix for issue https://github.com/enigo-rs/enigo/issues/68
        // TODO(dustin): This could be improved by aggregating 20 bytes worth of graphemes at a time
        // but i am unsure what would happen for grapheme clusters greater than 20 bytes ...
        use unicode_segmentation::UnicodeSegmentation;
        let clusters = UnicodeSegmentation::graphemes(sequence, true).collect::<Vec<&str>>();
        for cluster in clusters {
            if let Some(src) = self.event_source.as_ref() {
                if let Ok(event) = CGEvent::new_keyboard_event(src.clone(), 0, true) {
                    event.set_string(cluster);
                    self.post(event, None);
                } else {
                    hbb_common::throttled_log!(
                        KEYBOARD_ERROR_LOG_INTERVAL,
                        error,
                        "Failed to inject macOS Enigo key-sequence: could not create keyboard event"
                    );
                }
            } else {
                hbb_common::throttled_log!(
                    KEYBOARD_ERROR_LOG_INTERVAL,
                    error,
                    "Failed to inject macOS Enigo key-sequence: event source is not initialized"
                );
            }
        }
    }

    fn key_click(&mut self, key: Key) {
        let keycode = self.key_to_keycode(key);
        if keycode == u16::MAX {
            hbb_common::throttled_log!(
                KEYBOARD_ERROR_LOG_INTERVAL,
                error,
                "Failed to inject macOS Enigo key-click: keycode mapping is unavailable"
            );
            return;
        }

        if let Some(src) = self.event_source.as_ref() {
            if let Ok(event) = CGEvent::new_keyboard_event(src.clone(), keycode, true) {
                self.post(event, Some(keycode));
            } else {
                hbb_common::throttled_log!(
                    KEYBOARD_ERROR_LOG_INTERVAL,
                    error,
                    "Failed to inject macOS Enigo key-down in key-click: could not create keyboard event"
                );
            }

            if let Ok(event) = CGEvent::new_keyboard_event(src.clone(), keycode, false) {
                self.post(event, Some(keycode));
            } else {
                hbb_common::throttled_log!(
                    KEYBOARD_ERROR_LOG_INTERVAL,
                    error,
                    "Failed to inject macOS Enigo key-up in key-click: could not create keyboard event"
                );
            }
        } else {
            hbb_common::throttled_log!(
                KEYBOARD_ERROR_LOG_INTERVAL,
                error,
                "Failed to inject macOS Enigo key-click: event source is not initialized"
            );
        }
    }

    fn key_down(&mut self, key: Key) -> crate::ResultType {
        let code = self.key_to_keycode(key);
        if code == u16::MAX {
            return Err("".into());
        }
        if let Some(src) = self.event_source.as_ref() {
            if let Ok(event) = CGEvent::new_keyboard_event(src.clone(), code, true) {
                self.post(event, Some(code));
            }
        }
        Ok(())
    }

    fn key_up(&mut self, key: Key) {
        let code = self.key_to_keycode(key);
        if code == u16::MAX {
            hbb_common::throttled_log!(
                KEYBOARD_ERROR_LOG_INTERVAL,
                error,
                "Cannot map macOS Enigo key-up to a keycode"
            );
        }
        if let Some(src) = self.event_source.as_ref() {
            if let Ok(event) = CGEvent::new_keyboard_event(src.clone(), code, false) {
                self.post(event, Some(code));
            } else {
                hbb_common::throttled_log!(
                    KEYBOARD_ERROR_LOG_INTERVAL,
                    error,
                    "Failed to inject macOS Enigo key-up: could not create keyboard event"
                );
            }
        } else {
            hbb_common::throttled_log!(
                KEYBOARD_ERROR_LOG_INTERVAL,
                error,
                "Failed to inject macOS Enigo key-up: event source is not initialized"
            );
        }
    }

    fn get_key_state(&mut self, key: Key) -> bool {
        let keycode = self.key_to_keycode(key);
        unsafe { CGEventSourceKeyState(1, keycode) }
    }
}

