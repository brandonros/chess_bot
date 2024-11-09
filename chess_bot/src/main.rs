use std::sync::Arc;

use http::{Request, Response, StatusCode, Version};
use http_server::{HttpServer, Router};
use miniserde::{Deserialize, Serialize};
use pleco::{bots::{AlphaBetaSearcher, IterativeSearcher, JamboreeSearcher, MiniMaxSearcher, ParallelMiniMaxSearcher}, tools::Searcher, Board};
use simple_error::{box_err, SimpleResult};
use smol::{Executor, MainExecutor};

#[derive(Deserialize)]
struct GetBestMoveRequest {
    engine: String,
    fen: String,
    depth: u16,
}

#[derive(Serialize)]
struct GetBestMoveResponse {
    best_move: String,
}

async fn get_ping(_executor: Arc<Executor<'static>>, request: Request<Vec<u8>>) -> SimpleResult<Response<String>> {
    // log
    log::info!("get_ping: {:?}", request);

    // build response
    let response = Response::builder()
        .status(StatusCode::OK)
        .version(Version::HTTP_11)
        .header("Content-Type", "text/plain")
        .body("pong".to_string())?;

    // return
    Ok(response)
}

async fn get_best_move(_executor: Arc<Executor<'static>>, request: Request<Vec<u8>>) -> SimpleResult<Response<String>> {
    // log
    log::info!("get_best_move: {:?}", request);

    // parse request body
    let request_body = request.body();
    let request_body_string = std::str::from_utf8(request_body)?;
    let parsed_request: GetBestMoveRequest = miniserde::json::from_str(request_body_string)?;

    // build board
    let board = Board::from_fen(&parsed_request.fen).map_err(|err| box_err!(format!("failed to parse fen: {err:?}")))?;

    // get best move based on engine type
    let best_move = match parsed_request.engine.as_str() {
        "pleco:alpha-beta" => AlphaBetaSearcher::best_move(board, parsed_request.depth),
        "pleco:minimax" => MiniMaxSearcher::best_move(board, parsed_request.depth),
        "pleco:parallel-minimax" => ParallelMiniMaxSearcher::best_move(board, parsed_request.depth),
        "pleco:jamboree" => JamboreeSearcher::best_move(board, parsed_request.depth),
        "pleco:iterative" => IterativeSearcher::best_move(board, parsed_request.depth),
        _ => return Err(box_err!("invalid engine type"))
    };

    // build response
    let response_body = GetBestMoveResponse { best_move: format!("{best_move}") };
    let response_body_string = miniserde::json::to_string(&response_body);
    let response = Response::builder()
        .status(StatusCode::OK)
        .version(Version::HTTP_11)
        .header("Content-Type", "application/json")
        .body(response_body_string)?;

    // return
    Ok(response)
}

async fn async_main(executor: Arc<Executor<'static>>) -> SimpleResult<()> {
    // logging
    env_logger::init();

    // settings
    let host = "0.0.0.0";
    let port = 8080;

    // build router
    let mut router = Router::new(executor.clone());
    router.add_route("GET", "/ping", Arc::new(move |executor, req| Box::pin(get_ping(executor, req))));
    router.add_route("POST", "/chess/best-move", Arc::new(move |executor, req| Box::pin(get_best_move(executor, req))));
    let router = Arc::new(router);

    // run server
    HttpServer::run_server(executor, host, port, router).await
}

fn main() -> SimpleResult<()> {
    Arc::<Executor>::with_main(|ex| smol::block_on(async_main(ex.clone())))
}
