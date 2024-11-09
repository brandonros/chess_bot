use pleco::{bots::{AlphaBetaSearcher, IterativeSearcher, JamboreeSearcher, MiniMaxSearcher, ParallelMiniMaxSearcher}, tools::Searcher, Board};
use simple_error::{box_err, SimpleResult};

use crate::structs::{GetBestMoveRequest, GetBestMoveResponse};

pub async fn get_best_move(request: GetBestMoveRequest) -> SimpleResult<GetBestMoveResponse> {
    // build board
    let board = Board::from_fen(&request.fen).map_err(|err| box_err!(format!("failed to parse fen: {err:?}")))?;

    // get best move based on engine type
    let best_move = match request.engine.as_str() {
        "pleco:alpha-beta" => AlphaBetaSearcher::best_move(board, request.depth),
        "pleco:minimax" => MiniMaxSearcher::best_move(board, request.depth),
        "pleco:parallel-minimax" => ParallelMiniMaxSearcher::best_move(board, request.depth),
        "pleco:jamboree" => JamboreeSearcher::best_move(board, request.depth),
        "pleco:iterative" => IterativeSearcher::best_move(board, request.depth),
        _ => return Err(box_err!("invalid engine type"))
    };

    // build response
    let response_body = GetBestMoveResponse { best_move: format!("{best_move}") };

    // return
    Ok(response_body)
}
