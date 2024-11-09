use std::sync::Arc;

use http::{Request, Response, StatusCode, Version};
use simple_error::SimpleResult;
use smol::Executor;

use crate::chess;
use crate::structs::GetBestMoveRequest;

pub async fn get_ping(_executor: Arc<Executor<'static>>, request: Request<Vec<u8>>) -> SimpleResult<Response<String>> {
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

pub async fn get_best_move(_executor: Arc<Executor<'static>>, request: Request<Vec<u8>>) -> SimpleResult<Response<String>> {
    // log
    log::info!("get_best_move: {:?}", request);

    // parse request body
    let request_body = request.body();
    let request_body_string = std::str::from_utf8(request_body)?;
    let parsed_request: GetBestMoveRequest = miniserde::json::from_str(request_body_string)?;

    // get best move
    let response_body = chess::get_best_move(parsed_request).await?;

    // build response
    let response_body_string = miniserde::json::to_string(&response_body);
    let response = Response::builder()
        .status(StatusCode::OK)
        .version(Version::HTTP_11)
        .header("Content-Type", "application/json")
        .body(response_body_string)?;

    // return
    Ok(response)
}
