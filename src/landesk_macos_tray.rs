use hbb_common::libc;
use std::{
    fs::{File, OpenOptions},
    io,
    os::unix::{fs::OpenOptionsExt, io::AsRawFd},
    path::Path,
};

pub fn lock() -> io::Result<Option<File>> {
    let uid = unsafe { libc::geteuid() };
    // launchd and the GUI can have different TMPDIR values.
    acquire(&Path::new("/tmp").join(format!("md.lifeos.LanDesk-tray-{uid}.lock")))
}

fn acquire(path: &Path) -> io::Result<Option<File>> {
    let file = OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .mode(0o600)
        .custom_flags(libc::O_NOFOLLOW | libc::O_CLOEXEC)
        .open(path)?;
    // Keep the inode in place: unlinking it would let another process lock a new file.
    if unsafe { libc::flock(file.as_raw_fd(), libc::LOCK_EX | libc::LOCK_NB) } == 0 {
        return Ok(Some(file));
    }
    let error = io::Error::last_os_error();
    if error.kind() == io::ErrorKind::WouldBlock {
        Ok(None)
    } else {
        Err(error)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn only_one_tray_owner_and_release_allows_restart() {
        let path = std::env::temp_dir().join(format!("landesk-tray-test-{}", std::process::id()));
        let first = acquire(&path).unwrap().unwrap();
        assert!(acquire(&path).unwrap().is_none());
        drop(first);
        assert!(acquire(&path).unwrap().is_some());
        std::fs::remove_file(path).unwrap();
    }
}
