use base::message_proto::CursorData;
use std::collections::{HashMap, HashSet};

/// A shape that decoded, still compressed, under the id the UI knows it by. Copied once it
/// decoded: the message's colors may be a slice of a larger received buffer, which a clone
/// would keep alive.
#[cfg(any(feature = "flutter", test))]
pub(super) fn cursor_shape(id: u64, cd: &CursorData, compressed: &[u8]) -> CursorData {
    CursorData {
        id,
        hotx: cd.hotx,
        hoty: cd.hoty,
        width: cd.width,
        height: cd.height,
        colors: compressed.to_vec().into(),
        ..Default::default()
    }
}

/// The RGBA of a shape kept by `Session::cursor_shapes`, for the UI to draw it again.
#[cfg(any(feature = "flutter", test))]
pub(crate) fn kept_cursor_rgba(shape: CursorData) -> hbb_common::ResultType<CursorData> {
    decode_cursor_data(shape)
}

// Both UI handlers receive validated, uncompressed RGBA from the receive loop.
pub(super) fn decode_cursor_data(data: CursorData) -> hbb_common::ResultType<CursorData> {
    use hbb_common::{anyhow::anyhow, bail};

    // Limit decoded cursor data to 1 MiB before JSON serialization.
    const MAX_CURSOR_SIZE: i32 = 512;
    const RGBA_CHANNELS: usize = 4;

    let mut cd = data;
    if !(1..=MAX_CURSOR_SIZE).contains(&cd.width) || !(1..=MAX_CURSOR_SIZE).contains(&cd.height) {
        bail!("invalid source size {}x{}", cd.width, cd.height);
    }
    if !(0..cd.width).contains(&cd.hotx) || !(0..cd.height).contains(&cd.hoty) {
        bail!(
            "hotspot ({},{}) is outside the cursor image",
            cd.hotx,
            cd.hoty
        );
    }
    let expected = (cd.width as usize)
        .checked_mul(cd.height as usize)
        .and_then(|pixels| pixels.checked_mul(RGBA_CHANNELS))
        .ok_or_else(|| anyhow!("cursor RGBA size overflow"))?;
    let max_compressed_size = zstd::zstd_safe::compress_bound(expected);
    if cd.colors.len() > max_compressed_size {
        bail!(
            "compressed cursor data too large: {} bytes (limit {max_compressed_size})",
            cd.colors.len()
        );
    }
    let colors = zstd::bulk::decompress(&cd.colors, expected)?;
    if colors.len() != expected {
        bail!(
            "invalid RGBA length: expected {expected}, got {}",
            colors.len()
        );
    }
    cd.colors = colors.into();
    Ok(cd)
}

/// Gives the UI one id per shape for a peer that names shapes by handle, so the UI decodes and
/// keeps a shape once however many handles it arrives under. Nothing is dropped for the
/// connection: the peer sends a shape once and may select any handle it named again.
#[derive(Default)]
pub(super) struct CursorDedupe {
    ids: HashMap<u64, u64>,
    // The shapes given to the UI, by content id: whether one that arrives needs decoding.
    decoded: HashSet<u64>,
}

impl CursorDedupe {
    /// Hashes the compressed colors: one peer compresses the same pixels to the same bytes, and
    /// a shape seen before is then never decompressed again.
    pub(super) fn name(cd: &CursorData) -> u64 {
        crate::cursor_content_id(cd.width, cd.height, cd.hotx, cd.hoty, &cd.colors)
    }

    pub(super) fn id(&self, peer_id: u64) -> u64 {
        self.ids.get(&peer_id).copied().unwrap_or(peer_id)
    }

    pub(super) fn has_decoded(&self, id: u64) -> bool {
        self.decoded.contains(&id)
    }

    /// Names the handle once its shape decoded, now or before.
    pub(super) fn record(&mut self, peer_id: u64, id: u64) {
        self.ids.insert(peer_id, id);
        self.decoded.insert(id);
    }

    /// Names a known handle by the content of a shape that did not decode, which is never
    /// marked decoded: the UI has no shape under it, now or when the handle is selected again,
    /// and the shape the handle named before is not shown in its place. A handle never seen is
    /// not filed, so what a peer sends that does not decode takes no room.
    pub(super) fn rejected(&mut self, peer_id: u64, id: u64) -> u64 {
        if let Some(named) = self.ids.get_mut(&peer_id) {
            *named = id;
        }
        id
    }
}

#[cfg(test)]
mod cursor_dedupe_tests {
    use super::*;

    fn shape(id: u64, hotx: i32, colors: &[u8]) -> CursorData {
        CursorData {
            id,
            hotx,
            width: 2,
            height: 2,
            colors: colors.to_vec().into(),
            ..Default::default()
        }
    }

    #[test]
    fn a_shape_sent_under_a_new_handle_keeps_its_id() {
        let mut dedupe = CursorDedupe::default();
        let first = CursorDedupe::name(&shape(1, 0, b"arrow"));
        assert!(!dedupe.has_decoded(first));
        dedupe.record(1, first);

        let again = CursorDedupe::name(&shape(2, 0, b"arrow"));
        assert_eq!(again, first);
        assert!(dedupe.has_decoded(again));
        dedupe.record(2, again);
        assert_eq!(dedupe.id(2), first);
        assert_eq!(dedupe.id(1), first);
    }

    #[test]
    fn the_hotspot_is_part_of_the_shape() {
        let a = CursorDedupe::name(&shape(1, 0, b"arrow"));
        let b = CursorDedupe::name(&shape(2, 1, b"arrow"));
        assert_ne!(a, b);
    }

    #[test]
    fn a_reused_handle_names_its_latest_shape() {
        let mut dedupe = CursorDedupe::default();
        dedupe.record(1, CursorDedupe::name(&shape(1, 0, b"arrow")));
        let beam = CursorDedupe::name(&shape(1, 0, b"beam"));
        dedupe.record(1, beam);
        assert_eq!(dedupe.id(1), beam);
    }

    #[test]
    fn a_rejected_shape_names_its_handle_and_is_never_decoded() {
        let mut dedupe = CursorDedupe::default();
        let arrow = CursorDedupe::name(&shape(7, 0, b"arrow"));
        dedupe.record(7, arrow);
        let beam = CursorDedupe::name(&shape(8, 0, b"beam"));
        dedupe.record(8, beam);
        let broken = CursorDedupe::name(&shape(7, 0, b"broken"));
        assert_eq!(
            dedupe.rejected(7, broken),
            broken,
            "not the shape it named before"
        );
        assert_eq!(
            dedupe.id(7),
            broken,
            "nor when the handle is selected again"
        );
        assert_eq!(dedupe.id(8), beam, "another handle keeps its shape");
        assert!(!dedupe.has_decoded(broken));
        assert!(
            dedupe.has_decoded(arrow),
            "kept for a handle that brings it again"
        );
        dedupe.record(7, arrow);
        assert_eq!(dedupe.id(7), arrow);
    }

    #[test]
    fn a_shape_rejected_under_handles_never_seen_files_nothing() {
        let mut dedupe = CursorDedupe::default();
        let broken = CursorDedupe::name(&shape(0, 0, b"broken"));
        for handle in 0..1000 {
            assert_eq!(dedupe.rejected(handle, broken), broken);
        }
        assert!(dedupe.ids.is_empty());
        assert!(!dedupe.has_decoded(broken));
    }

    #[test]
    fn an_id_the_peer_never_sent_is_passed_on() {
        assert_eq!(CursorDedupe::default().id(7), 7);
    }

    #[test]
    fn peers_from_1_5_0_name_cursors_by_content() {
        use hbb_common::get_version_number as v;
        assert!(!crate::is_peer_naming_cursors_by_content(v("1.4.9")));
        assert!(crate::is_peer_naming_cursors_by_content(v("1.5.0")));
        assert!(crate::is_peer_naming_cursors_by_content(v("1.5.1")));
    }
}

#[cfg(test)]
mod kept_cursor_tests {
    use super::*;

    fn compressed(width: i32, height: i32) -> CursorData {
        let rgba = vec![7u8; (width * height * 4) as usize];
        CursorData {
            id: 1,
            width,
            height,
            colors: hbb_common::compress::compress(&rgba).into(),
            ..Default::default()
        }
    }

    #[test]
    fn a_kept_shape_is_a_copy_under_the_ui_id() {
        let mut cd = compressed(4, 4);
        cd.hotx = 1;
        let kept = cursor_shape(42, &cd, &cd.colors);
        assert_eq!(kept.id, 42);
        assert_eq!((kept.hotx, kept.width, kept.height), (1, 4, 4));
        assert_eq!(kept.colors, cd.colors);
        assert_ne!(
            kept.colors.as_ptr(),
            cd.colors.as_ptr(),
            "not a view of the received buffer"
        );
    }

    #[test]
    fn a_kept_shape_is_checked_again_when_it_is_read() {
        assert_eq!(kept_cursor_rgba(compressed(4, 4)).unwrap().colors.len(), 64);
        assert!(
            kept_cursor_rgba(compressed(513, 1)).is_err(),
            "over the size cap"
        );
        let mut bomb = compressed(4, 4);
        bomb.colors = hbb_common::compress::compress(&vec![0u8; 1 << 20]).into();
        assert!(kept_cursor_rgba(bomb).is_err(), "more pixels than its size");
    }
}

#[cfg(test)]
#[path = "cursor_validation_tests.rs"]
mod cursor_validation_tests;
