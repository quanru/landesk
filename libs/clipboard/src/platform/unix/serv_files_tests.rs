use super::*;
use std::fs;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

// Unique temp dir under the system temp dir; removed on drop (no dev-dep).
struct TmpDir(PathBuf);
impl TmpDir {
    fn new(tag: &str) -> Self {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_nanos())
            .unwrap_or(0);
        let mut dir = std::env::temp_dir();
        dir.push(format!("rustdesk_sig_test_{}_{}", tag, nanos));
        fs::create_dir_all(&dir).unwrap();
        TmpDir(dir)
    }
    fn join(&self, name: &str) -> PathBuf {
        self.0.join(name)
    }
}
impl Drop for TmpDir {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.0);
    }
}

fn path_str(p: &PathBuf) -> String {
    p.to_string_lossy().to_string()
}

// Tests that drive the global CLIP_FILES must not interleave.
static CLIP_FILES_TEST_LOCK: std::sync::Mutex<()> = std::sync::Mutex::new(());

fn lock_clip_files() -> std::sync::MutexGuard<'static, ()> {
    CLIP_FILES_TEST_LOCK
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
}

// Sparse, so a multi-GiB file costs no disk space.
fn write_at(path: &PathBuf, offset: u64, data: &[u8]) {
    use std::io::{Seek, SeekFrom, Write};
    let mut f = fs::File::create(path).unwrap();
    f.seek(SeekFrom::Start(offset)).unwrap();
    f.write_all(data).unwrap();
}

fn range_data(res: Vec<Result<ClipboardFile, CliprdrError>>) -> Vec<u8> {
    match res.into_iter().last() {
        Some(Ok(ClipboardFile::FileContentsResponse { requested_data, .. })) => requested_data,
        other => panic!("unexpected response: {:?}", other),
    }
}

#[test]
fn fingerprint_missing_path_is_default() {
    let tmp = TmpDir::new("missing");
    let missing = path_str(&tmp.join("does_not_exist.bin"));
    let sigs = fingerprint(&[missing]);
    assert_eq!(sigs.len(), 1);
    // A path that can't be stat'd -> default sig, which forces a rebuild.
    assert_eq!(sigs[0], FileSig::default());
    assert_eq!(sigs[0].mtime, None);
}

#[test]
fn fingerprint_detects_inplace_edit() {
    let tmp = TmpDir::new("edit");
    let file = tmp.join("a.bin");
    fs::write(&file, b"small").unwrap();
    let p = path_str(&file);

    let before = fingerprint(&[p.clone()]);
    // Same content, same path: fingerprint must be stable.
    let again = fingerprint(&[p.clone()]);
    assert_eq!(before, again);
    assert_eq!(before[0].size, 5);
    assert!(!before[0].is_dir);

    // Edit in place so the file grows.
    fs::write(&file, b"much larger contents than before").unwrap();
    let after = fingerprint(&[p]);
    assert_ne!(before, after);
    assert!(after[0].size > before[0].size);
}

#[test]
fn fingerprint_flags_directory() {
    let tmp = TmpDir::new("dir");
    let sub = tmp.join("subdir");
    fs::create_dir_all(&sub).unwrap();
    let sigs = fingerprint(&[path_str(&sub)]);
    assert_eq!(sigs.len(), 1);
    assert!(sigs[0].is_dir);
}

#[test]
fn recopy_after_edit_refreshes_cached_size() {
    let tmp = TmpDir::new("recopy");
    let file = tmp.join("doc.bin");
    fs::write(&file, b"v1").unwrap(); // 2 bytes
    let files = vec![path_str(&file)];

    // Drive the public, guarded `sync_files` over the global CLIP_FILES;
    // reset first.
    let _guard = lock_clip_files();
    clear_files();

    sync_files(&files).unwrap();
    {
        let cache = CLIP_FILES.lock();
        let idx = cache.first_file_index;
        assert_eq!(cache.file_list[idx].size, 2);
    }

    // In-place edit grows the file; the re-copy must rebuild. Pre-fix the
    // path-only guard early-returned and left the cached size stale at 2.
    fs::write(&file, b"v2 is bigger").unwrap(); // 12 bytes
    sync_files(&files).unwrap();
    {
        let cache = CLIP_FILES.lock();
        let idx = cache.first_file_index;
        assert_eq!(cache.file_list[idx].size, 12);
    }

    clear_files(); // leave the global clean for other tests
}

#[test]
fn range_request_huge_length_is_clamped() {
    let tmp = TmpDir::new("range");
    let file = tmp.join("data.bin");
    fs::write(&file, b"0123456789").unwrap();
    let files = vec![path_str(&file)];

    let mut clip = ClipFiles::default();
    clip.sync_files(&files, fingerprint(&files)).unwrap();
    let file_idx = clip.first_file_index;

    // offset + length used to wrap to 0, skip the clamp and ask for a u64::MAX buffer.
    let resp = clip
        .serve_file_contents(
            0,
            FileContentsRequest::Range {
                stream_id: 0,
                file_idx,
                offset: 1,
                length: u64::MAX,
            },
        )
        .unwrap();
    match resp {
        ClipboardFile::FileContentsResponse { requested_data, .. } => {
            assert_eq!(requested_data, b"123456789");
        }
        _ => panic!("unexpected response"),
    }
}

#[test]
fn range_request_decodes_wire_fields_as_u32() {
    let tmp = TmpDir::new("decode");
    let small = tmp.join("small.bin");
    fs::write(&small, b"0123456789").unwrap();
    let large = tmp.join("large.bin");
    write_at(&large, 0x8000_0000, b"tail");

    let _guard = lock_clip_files();
    clear_files();
    sync_files(&[path_str(&small), path_str(&large)]).unwrap();
    let small_idx = CLIP_FILES.lock().first_file_index as i32;
    let large_idx = small_idx + 1;

    // A negative cbRequested is a UINT32 length, clamped to the rest of the file.
    let res = read_file_contents(0, 0, small_idx, 0x2, 1, 0, -1, None);
    assert_eq!(range_data(res), b"123456789");

    // An nPositionLow with bit 31 set is an offset past 2 GiB, not a huge one.
    let res = read_file_contents(0, 0, large_idx, 0x2, 0x8000_0000u32 as i32, 0, 4, None);
    assert_eq!(range_data(res), b"tail");

    clear_files();
}

#[test]
fn range_request_over_limit_is_rejected() {
    let tmp = TmpDir::new("limit");
    let file = tmp.join("big.bin");
    let size = MAX_RANGE_READ + 1;
    write_at(&file, size - 1, b"x");
    let files = vec![path_str(&file)];

    let mut clip = ClipFiles::default();
    clip.sync_files(&files, fingerprint(&files)).unwrap();
    let file_idx = clip.first_file_index;

    let res = clip.serve_file_contents(
        0,
        FileContentsRequest::Range {
            stream_id: 0,
            file_idx,
            offset: 0,
            length: u32::MAX as u64,
        },
    );
    assert!(matches!(res, Err(CliprdrError::InvalidRequest { .. })));
}

#[test]
fn host_copy_during_transfer_keeps_serving_the_sent_list() {
    let tmp = TmpDir::new("recopy_in_flight");
    let first = tmp.join("first.bin");
    fs::write(&first, b"AAAAAAAA").unwrap();
    let second = tmp.join("second.bin");
    fs::write(&second, b"BBBBBBBB").unwrap();

    let _guard = lock_clip_files();
    clear_files();
    sync_files(&[path_str(&first)]).unwrap();
    get_file_list_pdu(1);
    let idx = CLIP_FILES.lock().first_file_index as i32;
    let read = |offset| range_data(read_file_contents(1, 7, idx, 0x2, offset, 0, 4, None));
    assert_eq!(read(0), b"AAAA");

    // Copying another file on this side must not redirect the peer's stream.
    sync_files(&[path_str(&second)]).unwrap();
    assert_eq!(read(4), b"AAAA");

    clear_files();
}

#[test]
fn stream_keeps_its_list_after_a_second_paste() {
    let tmp = TmpDir::new("repaste_in_flight");
    let first = tmp.join("first.bin");
    fs::write(&first, b"AAAAAAAA").unwrap();
    let second = tmp.join("second.bin");
    fs::write(&second, b"BBBBBBBB").unwrap();

    let _guard = lock_clip_files();
    clear_files();
    sync_files(&[path_str(&first)]).unwrap();
    let first_id = file_list_id(&get_file_list_pdu(1));
    let idx = CLIP_FILES.lock().first_file_index as i32;

    // The peer copies the second file on this side and pastes it while the first
    // transfer is still reading.
    sync_files(&[path_str(&second)]).unwrap();
    let second_id = file_list_id(&get_file_list_pdu(1));
    assert_ne!(first_id, second_id);

    let read = |id| range_data(read_file_contents(1, 7, idx, 0x2, 4, 0, 4, Some(id)));
    assert_eq!(read(first_id), b"AAAA");
    assert_eq!(read(second_id), b"BBBB");

    clear_files();
}

#[test]
fn named_list_must_have_been_sent_to_the_conn() {
    let tmp = TmpDir::new("foreign_list");
    let first = tmp.join("first.bin");
    fs::write(&first, b"AAAAAAAA").unwrap();
    let second = tmp.join("second.bin");
    fs::write(&second, b"BBBBBBBB").unwrap();

    let _guard = lock_clip_files();
    clear_files();
    sync_files(&[path_str(&first)]).unwrap();
    let first_id = file_list_id(&get_file_list_pdu(1));
    let idx = CLIP_FILES.lock().first_file_index as i32;
    sync_files(&[path_str(&second)]).unwrap();

    let refused = |conn_id, id| {
        matches!(
            read_file_contents(conn_id, 7, idx, 0x2, 0, 0, 4, Some(id)).last(),
            Some(Err(CliprdrError::InvalidRequest { .. }))
        )
    };
    // Retired list, asked for by a connection it was never sent to.
    assert!(refused(2, first_id));
    // A list id this side never sent.
    assert!(refused(1, first_id ^ 1));

    clear_files();
}

#[test]
fn failed_recopy_keeps_the_current_list() {
    let tmp = TmpDir::new("failed_recopy");
    let first = tmp.join("first.bin");
    fs::write(&first, b"AAAAAAAA").unwrap();
    let missing = tmp.join("missing.bin");

    let _guard = lock_clip_files();
    clear_files();
    sync_files(&[path_str(&first)]).unwrap();
    let pdu = get_file_list_pdu(1);

    assert!(sync_files(&[path_str(&missing)]).is_err());
    assert_eq!(get_file_list_pdu(1), pdu);

    clear_files();
}

fn file_index(path: &PathBuf) -> i32 {
    let files = CLIP_FILES.lock();
    files
        .file_list
        .iter()
        .position(|f| &f.path == path)
        .unwrap() as i32
}

// Replaces `path` the way editors save: write aside, then rename over it.
fn replace_atomically(path: &PathBuf, data: &[u8]) {
    let aside = path.with_extension("new");
    fs::write(&aside, data).unwrap();
    fs::rename(&aside, path).unwrap();
}

#[test]
fn retired_list_closes_only_files_not_being_read() {
    let tmp = TmpDir::new("retired_handles");
    let first = tmp.join("first.bin");
    fs::write(&first, b"AAAABBBB").unwrap();
    let next = tmp.join("next.bin");
    fs::write(&next, b"CCCCDDDD").unwrap();
    let other = tmp.join("other.bin");
    fs::write(&other, b"EEEEEEEE").unwrap();

    let _guard = lock_clip_files();
    clear_files();
    sync_files(&[path_str(&first), path_str(&next)]).unwrap();
    let id = file_list_id(&get_file_list_pdu(1));
    let (first_idx, next_idx) = (file_index(&first), file_index(&next));
    let read = |idx, offset| range_data(read_file_contents(1, 7, idx, 0x2, offset, 0, 4, Some(id)));
    // Leaves `first` open at offset 4, and preloads `next`.
    assert_eq!(read(first_idx, 0), b"AAAA");

    sync_files(&[path_str(&other)]).unwrap();
    {
        let retired = RETIRED_CLIP_FILES.lock();
        let open = |idx: i32| retired[0].file_list[idx as usize].handle.is_some();
        assert!(open(first_idx));
        assert!(!open(next_idx));
    }
    assert_eq!(read(first_idx, 4), b"BBBB");
    assert_eq!(read(next_idx, 0), b"CCCC");

    clear_files();
}

#[test]
fn files_being_read_keep_their_content_when_their_paths_are_replaced() {
    let tmp = TmpDir::new("replaced_paths");
    let first = tmp.join("first.bin");
    fs::write(&first, b"1111aaaa").unwrap();
    let second = tmp.join("second.bin");
    fs::write(&second, b"2222bbbb").unwrap();
    let other = tmp.join("other.bin");
    fs::write(&other, b"EEEEEEEE").unwrap();

    let _guard = lock_clip_files();
    clear_files();
    sync_files(&[path_str(&first), path_str(&second)]).unwrap();
    let id = file_list_id(&get_file_list_pdu(1));
    let (first_idx, second_idx) = (file_index(&first), file_index(&second));
    let read = |idx, offset| range_data(read_file_contents(1, 7, idx, 0x2, offset, 0, 4, Some(id)));
    // Two files part-way through at once.
    assert_eq!(read(first_idx, 0), b"1111");
    assert_eq!(read(second_idx, 0), b"2222");

    sync_files(&[path_str(&other)]).unwrap();
    replace_atomically(&first, b"3333cccc");
    replace_atomically(&second, b"4444dddd");

    assert_eq!(read(first_idx, 4), b"aaaa");
    assert_eq!(read(second_idx, 4), b"bbbb");

    clear_files();
}

#[test]
fn same_file_metadata_in_another_folder_is_another_list() {
    let tmp = TmpDir::new("same_metadata");
    let (dir_a, dir_b) = (tmp.join("a"), tmp.join("b"));
    fs::create_dir_all(&dir_a).unwrap();
    fs::create_dir_all(&dir_b).unwrap();
    let (first, second) = (dir_a.join("report.bin"), dir_b.join("report.bin"));
    fs::write(&first, b"AAAAAAAA").unwrap();
    fs::write(&second, b"BBBBBBBB").unwrap();
    // Same name, size and mtime: the descriptors differ only by the nonce.
    let mtime = SystemTime::UNIX_EPOCH + std::time::Duration::from_secs(1_700_000_000);
    for path in [&first, &second] {
        fs::File::options()
            .write(true)
            .open(path)
            .unwrap()
            .set_modified(mtime)
            .unwrap();
    }

    let _guard = lock_clip_files();
    clear_files();
    sync_files(&[path_str(&first)]).unwrap();
    let first_id = file_list_id(&get_file_list_pdu(1));
    let idx = CLIP_FILES.lock().first_file_index as i32;
    sync_files(&[path_str(&second)]).unwrap();
    let second_id = file_list_id(&get_file_list_pdu(1));
    assert_ne!(first_id, second_id);

    let read = |id| range_data(read_file_contents(1, 7, idx, 0x2, 4, 0, 4, Some(id)));
    assert_eq!(read(first_id), b"AAAA");
    assert_eq!(read(second_id), b"BBBB");

    clear_files();
}

#[test]
fn a_retired_list_refuses_a_file_replaced_before_its_read() {
    let tmp = TmpDir::new("replaced_unread");
    let first = tmp.join("first.bin");
    fs::write(&first, b"AAAAAAAA").unwrap();
    let second = tmp.join("second.bin");
    fs::write(&second, b"BBBBBBBB").unwrap();
    let other = tmp.join("other.bin");
    fs::write(&other, b"EEEEEEEE").unwrap();

    let _guard = lock_clip_files();
    clear_files();
    sync_files(&[path_str(&first), path_str(&second)]).unwrap();
    let id = file_list_id(&get_file_list_pdu(1));
    let (first_idx, second_idx) = (file_index(&first), file_index(&second));
    let read = |idx, offset| read_file_contents(1, 7, idx, 0x2, offset, 0, 4, Some(id));
    assert_eq!(range_data(read(first_idx, 0)), b"AAAA");

    // Retiring closes `second`, which has not been read yet; it is then replaced.
    sync_files(&[path_str(&other)]).unwrap();
    replace_atomically(&second, b"CCCCCCCCCC");

    assert!(matches!(
        read(second_idx, 0).last(),
        Some(Err(CliprdrError::InvalidRequest { .. }))
    ));
    // The file part-way through is unaffected.
    assert_eq!(range_data(read(first_idx, 4)), b"AAAA");

    clear_files();
}
