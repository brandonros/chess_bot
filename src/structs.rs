use miniserde::{Deserialize, Serialize};

#[derive(Deserialize)]
pub struct GetBestMoveRequest {
    pub engine: String,
    pub fen: String,
    pub depth: u16,
}

#[derive(Serialize)]
pub struct GetBestMoveResponse {
    pub best_move: String,
}
