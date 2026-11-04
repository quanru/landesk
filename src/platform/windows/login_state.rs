//! WTS flags reverse their meaning on Windows 7 / Server 2008 R2.
pub(super) fn locked_from_flags(flags: u32, reversed: bool) -> Option<bool> {
    match flags {
        0 => Some(!reversed),
        1 => Some(reversed),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn known_flags_respect_windows_version_and_unknown_never_means_locked() {
        for reversed in [false, true] {
            assert_eq!(locked_from_flags(0, reversed), Some(!reversed));
            assert_eq!(locked_from_flags(1, reversed), Some(reversed));
            for flags in [2, u32::MAX] {
                assert_eq!(locked_from_flags(flags, reversed), None);
            }
        }
    }
}
