use crate::{
    platform::unix::{
        filetype::file_list_id,
        local_file::{construct_file_list, LocalFile},
    },
    ClipboardFile, CliprdrError,
};
use hbb_common::{
    bytes::{BufMut, BytesMut},
    log,
};
use parking_lot::Mutex;
use std::{
    collections::VecDeque,
    path::PathBuf,
    sync::{atomic::Ordering, Arc},
    time::SystemTime,
    usize,
};

// Our clients request at most this much per range: macOS 4 MiB, FUSE less, and Windows
// splits larger reads (WF_CLIPRDR_MAX_RANGE_READ). A larger read is refused, not shortened:
// a short response reads as end of file to IStream callers on Windows.
const MAX_RANGE_READ: u64 = 16 * 1024 * 1024;

lazy_static::lazy_static! {
    // local files are cached, this value should not be changed when copying files
    // Because `CliprdrFileContentsRequest` only contains the index of the file in the list.
    // We need to keep the file list in the same order as the remote side.
    // We may add a `FileId` field to `CliprdrFileContentsRequest` in the future.
    static ref CLIP_FILES: Arc<Mutex<ClipFiles>> = Default::default();
    // Lists replaced by a newer copy after a peer was sent them, oldest first. The peer's
    // streams keep reading the list they came from. Lock after `CLIP_FILES`.
    static ref RETIRED_CLIP_FILES: Mutex<VecDeque<ClipFiles>> = Default::default();
}

const MAX_RETIRED_CLIP_FILES: usize = 4;

// The first descriptor's `clsid`, inside the 32 reserved bytes every peer skips. A random
// nonce there makes each copy's list id distinct, even when two copies have identical
// names, sizes and times (the same file in two folders).
const LIST_NONCE: std::ops::Range<usize> = 8..24;

#[derive(Debug)]
enum FileContentsRequest {
    Size {
        stream_id: i32,
        file_idx: usize,
    },

    Range {
        stream_id: i32,
        file_idx: usize,
        offset: u64,
        length: u64,
    },
}

// Cheap fingerprint of one top-level selected entry. A change in size/mtime --
// or a directory in the selection -- forces sync_files() to rebuild (see below).
#[derive(Debug, Default, Clone, PartialEq, Eq)]
struct FileSig {
    size: u64,
    mtime: Option<SystemTime>,
    is_dir: bool,
}

// Stat the top-level selected paths only (no recursion), same order as `files`.
fn fingerprint(files: &[String]) -> Vec<FileSig> {
    files
        .iter()
        .map(|s| match std::fs::metadata(s) {
            Ok(mt) => FileSig {
                size: mt.len(),
                mtime: mt.modified().ok(),
                is_dir: mt.is_dir(),
            },
            Err(_) => FileSig::default(),
        })
        .collect()
}

#[derive(Default)]
struct ClipFiles {
    files: Vec<String>,
    // Fingerprint of `files` (same len/order); detects in-place edits on re-copy.
    sigs: Vec<FileSig>,
    file_list: Vec<LocalFile>,
    first_file_index: usize,
    files_pdu: Vec<u8>,
    // `file_list_id(files_pdu)`, which peers send back as `clip_data_id`.
    id: i32,
    // Connections that were sent `files_pdu`.
    served_to: Vec<i32>,
}

impl ClipFiles {
    fn clear(&mut self) {
        self.files.clear();
        self.sigs.clear();
        self.file_list.clear();
        self.first_file_index = usize::MAX;
        self.files_pdu.clear();
        self.id = 0;
        self.served_to.clear();
    }

    fn sync_files(
        &mut self,
        clipboard_files: &[String],
        sigs: Vec<FileSig>,
    ) -> Result<(), CliprdrError> {
        let clipboard_paths = clipboard_files
            .iter()
            .map(|s| PathBuf::from(s))
            .collect::<Vec<_>>();
        self.file_list = construct_file_list(&clipboard_paths)?;
        self.first_file_index = self
            .file_list
            .iter()
            .position(|f| !f.path.is_dir())
            .unwrap_or(usize::MAX);
        self.files = clipboard_files.to_vec();
        self.sigs = sigs;
        Ok(())
    }

    fn build_file_list_pdu(&mut self) -> Result<(), CliprdrError> {
        let mut data = BytesMut::with_capacity(4 + 592 * self.file_list.len());
        data.put_u32_le(self.file_list.len() as u32);
        for file in self.file_list.iter() {
            data.put(file.as_bin()?.as_slice());
        }
        self.files_pdu = data.to_vec();
        if let Some(nonce) = self.files_pdu.get_mut(LIST_NONCE) {
            nonce.copy_from_slice(&rand::random::<[u8; 16]>());
        }
        self.id = file_list_id(&self.files_pdu);
        Ok(())
    }

    // Close files that are not being read, such as the preloaded next file; `read_exact_at`
    // reopens them on the next read. A file part-way through keeps its handle and offset, so
    // its remaining bytes come from the same file even if its path is replaced meanwhile.
    fn release_handles(&mut self) {
        for file in self.file_list.iter_mut() {
            if file.offset.load(Ordering::Relaxed) == 0 {
                file.handle = None;
            }
        }
    }

    // A retired list's file is reopened by path once its handle was closed, and the path may now
    // name a replacement. Check size and modified time on the handle the read will use, and refuse
    // a file that no longer matches the list.
    fn check_retired_file(&mut self, request: &FileContentsRequest) -> Result<(), CliprdrError> {
        let FileContentsRequest::Range { file_idx, .. } = request else {
            return Ok(());
        };
        let Some(file) = self.file_list.get_mut(*file_idx) else {
            return Ok(());
        };
        if file.is_dir {
            return Ok(());
        }
        file.load_handle()?;
        let unchanged = file
            .handle
            .as_ref()
            .and_then(|handle| handle.get_ref().metadata().ok())
            .map_or(false, |md| {
                md.len() == file.size && md.modified().ok() == Some(file.last_write_time)
            });
        if unchanged {
            Ok(())
        } else {
            Err(CliprdrError::InvalidRequest {
                description: format!("file {} changed since its list was sent", file.name),
            })
        }
    }

    fn get_files_for_audit(&self, request: &FileContentsRequest) -> Option<ClipboardFile> {
        if let FileContentsRequest::Range {
            file_idx, offset, ..
        } = request
        {
            if *file_idx == self.first_file_index && *offset == 0 {
                let files: Vec<(String, u64)> = self
                    .file_list
                    .iter()
                    .filter_map(|f| {
                        if f.path.is_file() {
                            Some((f.path.to_string_lossy().to_string(), f.size))
                        } else {
                            None
                        }
                    })
                    .collect::<_>();
                if files.is_empty() {
                    return None;
                } else {
                    return Some(ClipboardFile::Files { files });
                }
            }
        }
        None
    }

    fn serve_file_contents(
        &mut self,
        conn_id: i32,
        request: FileContentsRequest,
    ) -> Result<ClipboardFile, CliprdrError> {
        let (file_idx, file_contents_resp) = match request {
            FileContentsRequest::Size {
                stream_id,
                file_idx,
            } => {
                log::debug!("file contents (size) requested from conn: {}", conn_id);
                let Some(file) = self.file_list.get(file_idx) else {
                    log::error!(
                        "invalid file index {} requested from conn: {}",
                        file_idx,
                        conn_id
                    );
                    return Err(CliprdrError::InvalidRequest {
                        description: format!(
                            "invalid file index {} requested from conn: {}",
                            file_idx, conn_id
                        ),
                    });
                };

                log::debug!(
                    "conn {} requested file-{}: {}",
                    conn_id,
                    file_idx,
                    file.name
                );

                let size = file.size;
                (
                    file_idx,
                    ClipboardFile::FileContentsResponse {
                        msg_flags: 0x1,
                        stream_id,
                        requested_data: size.to_le_bytes().to_vec(),
                    },
                )
            }
            FileContentsRequest::Range {
                stream_id,
                file_idx,
                offset,
                length,
            } => {
                log::debug!(
                    "file contents (range from {} length {}) request from conn: {}",
                    offset,
                    length,
                    conn_id
                );
                let Some(file) = self.file_list.get_mut(file_idx) else {
                    log::error!(
                        "invalid file index {} requested from conn: {}",
                        file_idx,
                        conn_id
                    );
                    return Err(CliprdrError::InvalidRequest {
                        description: format!(
                            "invalid file index {} requested from conn: {}",
                            file_idx, conn_id
                        ),
                    });
                };
                log::debug!(
                    "conn {} requested file-{}: {}",
                    conn_id,
                    file_idx,
                    file.name
                );

                if offset > file.size {
                    log::error!("invalid reading offset requested from conn: {}", conn_id);
                    return Err(CliprdrError::InvalidRequest {
                        description: format!(
                            "invalid reading offset requested from conn: {}",
                            conn_id
                        ),
                    });
                }
                let read_size = if length > file.size - offset {
                    file.size - offset
                } else {
                    length
                };

                if read_size > MAX_RANGE_READ {
                    return Err(CliprdrError::InvalidRequest {
                        description: format!(
                            "file contents request of {} bytes exceeds the {} byte limit, conn: {}",
                            read_size, MAX_RANGE_READ, conn_id
                        ),
                    });
                }

                let mut buf = vec![0u8; read_size as usize];

                file.read_exact_at(&mut buf, offset)?;

                (
                    file_idx,
                    ClipboardFile::FileContentsResponse {
                        msg_flags: 0x1,
                        stream_id,
                        requested_data: buf,
                    },
                )
            }
        };

        log::debug!("file contents sent to conn: {}", conn_id);
        // hot reload next file
        for next_file in self.file_list.iter_mut().skip(file_idx + 1) {
            if !next_file.is_dir {
                next_file.load_handle()?;
                break;
            }
        }
        Ok(file_contents_resp)
    }
}

#[inline]
pub fn clear_files() {
    CLIP_FILES.lock().clear();
    RETIRED_CLIP_FILES.lock().clear();
}

// The list a request reads from: the one its `clip_data_id` names, else the one last sent to
// the connection. A named list that is gone yields `None`. A peer that sends no id and was
// never sent a list reads the current one, as before.
fn select_clip_files<'a>(
    current: &'a mut ClipFiles,
    retired: &'a mut VecDeque<ClipFiles>,
    conn_id: i32,
    clip_data_id: Option<i32>,
) -> Option<&'a mut ClipFiles> {
    match clip_data_id {
        Some(id) if current.id == id => Some(current),
        Some(id) => retired
            .iter_mut()
            .rev()
            .find(|files| files.id == id && files.served_to.contains(&conn_id)),
        None if current.served_to.contains(&conn_id) => Some(current),
        None => retired
            .iter_mut()
            .rev()
            .find(|files| files.served_to.contains(&conn_id))
            .or(Some(current)),
    }
}

// Keep a list a peer was sent, so its streams do not read the new copy at the same indexes.
fn retire_if_served(mut replaced: ClipFiles) {
    if replaced.served_to.is_empty() {
        return;
    }
    replaced.release_handles();
    let mut retired = RETIRED_CLIP_FILES.lock();
    if retired.len() == MAX_RETIRED_CLIP_FILES {
        retired.pop_front();
    }
    retired.push_back(replaced);
}

pub fn read_file_contents(
    conn_id: i32,
    stream_id: i32,
    list_index: i32,
    dw_flags: i32,
    n_position_low: i32,
    n_position_high: i32,
    cb_requested: i32,
    clip_data_id: Option<i32>,
) -> Vec<Result<ClipboardFile, CliprdrError>> {
    let fcr = if dw_flags == 0x1 {
        FileContentsRequest::Size {
            stream_id,
            file_idx: list_index as usize,
        }
    } else if dw_flags == 0x2 {
        // nPositionLow and cbRequested are UINT32s carried in i32 fields. Sign-extending
        // them rejects offsets whose low word is >= 2 GiB and turns a negative length
        // into a near-u64::MAX read.
        let offset = (n_position_high as u64) << 32 | n_position_low as u32 as u64;
        let length = cb_requested as u32 as u64;

        FileContentsRequest::Range {
            stream_id,
            file_idx: list_index as usize,
            offset,
            length,
        }
    } else {
        return vec![Err(CliprdrError::InvalidRequest {
            description: format!("got invalid FileContentsRequest, dw_flats: {dw_flags}"),
        })];
    };

    let mut current = CLIP_FILES.lock();
    let mut retired = RETIRED_CLIP_FILES.lock();
    let current_ptr: *const ClipFiles = &*current;
    let Some(clip_files) = select_clip_files(&mut current, &mut retired, conn_id, clip_data_id)
    else {
        return vec![Err(CliprdrError::InvalidRequest {
            description: format!(
                "file list {:?} is not available to conn: {}",
                clip_data_id, conn_id
            ),
        })];
    };
    if !std::ptr::eq(&*clip_files, current_ptr) {
        if let Err(e) = clip_files.check_retired_file(&fcr) {
            return vec![Err(e)];
        }
    }
    let mut res = vec![];
    if let Some(files_res) = clip_files.get_files_for_audit(&fcr) {
        res.push(Ok(files_res));
    }
    res.push(clip_files.serve_file_contents(conn_id, fcr));
    res
}

pub fn sync_files(files: &[String]) -> Result<(), CliprdrError> {
    // Dedup: skip the rebuild only when paths + sizes + mtimes match and no dir is
    // selected (a dir's own mtime doesn't change when a file inside it is edited).
    let current = fingerprint(files);
    let mut files_lock = CLIP_FILES.lock();
    if files_lock.files == files
        && files_lock.sigs == current
        && !current.iter().any(|sig| sig.is_dir)
    {
        return Ok(());
    }
    // Build aside, so a failure leaves the current list in place.
    let mut next = ClipFiles::default();
    next.sync_files(files, current)?;
    next.build_file_list_pdu()?;
    let replaced = std::mem::replace(&mut *files_lock, next);
    retire_if_served(replaced);
    Ok(())
}

pub fn get_file_list_pdu(conn_id: i32) -> Vec<u8> {
    let mut clip_files = CLIP_FILES.lock();
    if !clip_files.files_pdu.is_empty() && !clip_files.served_to.contains(&conn_id) {
        clip_files.served_to.push(conn_id);
    }
    clip_files.files_pdu.clone()
}

#[cfg(test)]
#[path = "serv_files_tests.rs"]
mod sig_test;
