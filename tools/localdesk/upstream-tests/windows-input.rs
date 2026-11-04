#[cfg(test)]
mod windows_input {
    // PRODUCTION_ABSOLUTE_COORDINATES
    #[test]
    fn extreme_remote_coordinates_are_clamped_without_overflow_or_division_by_zero() {
        assert_eq!(to_absolute(i32::MAX, i32::MIN, 1), Some(65535));
        assert_eq!(to_absolute(i32::MIN, i32::MAX, 1), Some(0));
        assert_eq!(to_absolute(500, 0, 1000), Some(32767));
        assert_eq!(to_absolute(-500, -1000, 1000), Some(32767));
        assert_eq!(to_absolute(0, 0, 0), None);
        assert_eq!(to_absolute(0, 0, -1), None);
    }
}
