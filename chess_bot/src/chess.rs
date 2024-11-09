use std::sync::{Arc, Mutex};

use pleco::{bots::{AlphaBetaSearcher, IterativeSearcher, JamboreeSearcher, MiniMaxSearcher, ParallelMiniMaxSearcher}, tools::Searcher};
use rustic::{engine::defs::{Information, SearchData, Verbosity, TT}, movegen::MoveGenerator, search::defs::{GameTime, SearchControl, SearchMode, SearchParams, SearchReport}};
use simple_error::{box_err, SimpleResult};

use crate::structs::{GetBestMoveRequest, GetBestMoveResponse};

pub async fn get_best_move(request: GetBestMoveRequest) -> SimpleResult<GetBestMoveResponse> {
    // get best move based on engine type
    let best_move = match request.engine.as_str() {
        "pleco:alpha-beta" => {
            let board = pleco::Board::from_fen(&request.fen).map_err(|err| box_err!(format!("failed to parse fen: {err:?}")))?;
            let best_move = AlphaBetaSearcher::best_move(board, request.depth);
            format!("{best_move}")
        },
        "pleco:minimax" => {
            let board = pleco::Board::from_fen(&request.fen).map_err(|err| box_err!(format!("failed to parse fen: {err:?}")))?;
            let best_move = MiniMaxSearcher::best_move(board, request.depth);
            format!("{best_move}")
        },
        "pleco:parallel-minimax" => {
            let board = pleco::Board::from_fen(&request.fen).map_err(|err| box_err!(format!("failed to parse fen: {err:?}")))?;
            let best_move = ParallelMiniMaxSearcher::best_move(board, request.depth);
            format!("{best_move}")
        },
        "pleco:jamboree" => {
            let board = pleco::Board::from_fen(&request.fen).map_err(|err| box_err!(format!("failed to parse fen: {err:?}")))?;
            let best_move = JamboreeSearcher::best_move(board, request.depth);
            format!("{best_move}")
        },
        "pleco:iterative" => {
            let board = pleco::Board::from_fen(&request.fen).map_err(|err| box_err!(format!("failed to parse fen: {err:?}")))?;
            let best_move = IterativeSearcher::best_move(board, request.depth);
            format!("{best_move}")
        },
        "rustic" => {
            // setup board
            let mut board = rustic::board::Board::new();
            board.fen_setup(Some(&request.fen)).expect("failed to setup board from fen");
            let board = Arc::new(Mutex::new(board));
            // setup move generator
            let move_generator = Arc::new(MoveGenerator::new());
            // setup transposition table
            let tt_size = 32; // TODO: not sure
            let transposition_table = Arc::new(Mutex::new(TT::<SearchData>::new(tt_size)));
            // setup search
            let mut search = rustic::search::Search::new();
            let (info_tx, info_rx) = crossbeam_channel::unbounded::<Information>();
            search.init(
                info_tx,
                board,
                move_generator,
                transposition_table
            );
            // start search
            search.send(SearchControl::Start(SearchParams {
                depth: request.depth as i8,
                game_time: GameTime::new(0, 0, 0, 0, None),
                move_time: 0,
                nodes: 0,
                search_mode: SearchMode::Depth,
                verbosity: Verbosity::Full,
            }));
            // wait for best move
            let best_move = loop {
                let info = info_rx.recv().expect("failed to receive info");
                let search_report = match info {
                    Information::Search(search_report) => search_report,
                    _ => return Err(box_err!("expected search report"))
                };
                match search_report {
                    SearchReport::Finished(best_move) => {
                        log::info!("search finished");
                        break best_move
                    },
                    SearchReport::SearchSummary(_search_summary) => {
                        log::info!("search summary");
                    }
                    SearchReport::SearchCurrentMove(_search_current_move) => {
                        log::info!("search current move");
                    }
                    SearchReport::SearchStats(_search_stats) => {
                        log::info!("search stats");
                    }
                    SearchReport::Ready => {
                        log::info!("search ready");
                    }
                }
            };
            // format best move
            let best_move = format!("{best_move}");

            // TODO: stop + cleanup
            /*search.send(SearchControl::Stop);
            search.shutdown(); // TODO: blocks?
            drop(search);
            drop(info_rx);*/

            // return
            best_move
        },
        _ => return Err(box_err!("invalid engine type"))
    };

    // build response
    let response_body = GetBestMoveResponse { best_move: format!("{best_move}") };

    // return
    Ok(response_body)
}
