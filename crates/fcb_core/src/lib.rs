pub mod config;
pub mod crypto;
pub mod manifest;
pub mod server_api;
pub mod state;

use std::path::PathBuf;

pub type Result<T> = std::result::Result<T, Error>;

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("{0}")]
    Message(String),
    #[error(transparent)]
    Io(#[from] std::io::Error),
    #[error(transparent)]
    Json(#[from] serde_json::Error),
    #[error(transparent)]
    Http(#[from] Box<ureq::Error>),
}

pub fn fcb_dir() -> PathBuf {
    PathBuf::from(".fcb")
}

pub fn err(message: impl Into<String>) -> Error {
    Error::Message(message.into())
}

