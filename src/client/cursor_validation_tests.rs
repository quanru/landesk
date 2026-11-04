use super::*;

fn valid() -> CursorData {
    CursorData {
        width: 2,
        height: 3,
        colors: zstd::bulk::compress(&[7; 24], 1).unwrap().into(),
        ..Default::default()
    }
}

#[test]
fn invalid_dimensions_and_hotspots_are_rejected() {
    assert_eq!(decode_cursor_data(valid()).unwrap().colors.len(), 24);
    for (w, h) in [(0, 3), (-1, 3), (2, 0), (513, 3), (i32::MAX, i32::MAX)] {
        let mut cd = valid();
        cd.width = w;
        cd.height = h;
        assert!(decode_cursor_data(cd).is_err());
    }
    for (x, y) in [(-1, 0), (0, -1), (2, 0), (0, 3), (i32::MAX, i32::MAX)] {
        let mut cd = valid();
        cd.hotx = x;
        cd.hoty = y;
        assert!(decode_cursor_data(cd).is_err());
    }
}

#[test]
fn malformed_truncated_and_excess_rgba_are_rejected() {
    for pixels in [vec![7; 23], vec![7; 25], vec![0; 1 << 20]] {
        let mut cd = valid();
        cd.colors = zstd::bulk::compress(&pixels, 1).unwrap().into();
        assert!(decode_cursor_data(cd).is_err());
    }
    let mut cd = valid();
    cd.colors = b"invalid zstd".to_vec().into();
    assert!(decode_cursor_data(cd).is_err());
    let mut cd = valid();
    cd.colors.truncate(cd.colors.len() - 1);
    assert!(decode_cursor_data(cd).is_err());
}

#[test]
fn compressed_input_is_bounded_before_decompression() {
    let mut cd = valid();
    cd.colors = vec![0; zstd::zstd_safe::compress_bound(24) + 1].into();
    assert!(decode_cursor_data(cd)
        .unwrap_err()
        .to_string()
        .contains("compressed cursor data too large"));
}
