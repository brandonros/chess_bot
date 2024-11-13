mod routes;
mod structs;
mod chess;

use std::sync::Arc;

use http_server::{HttpServer, Router};
use simple_error::SimpleResult;
use smol::{Executor, MainExecutor};

async fn async_main(executor: Arc<Executor<'static>>) -> SimpleResult<()> {
    // logging
    env_logger::init();

    // settings
    let host = "0.0.0.0";
    let port = 8080;

    // build router
    let mut router = Router::new(executor.clone());
    router.add_route("GET", "/ping", Arc::new(move |executor, req| Box::pin(routes::get_ping(executor, req))));
    router.add_route("POST", "/move/best", Arc::new(move |executor, req| Box::pin(routes::get_best_move(executor, req))));
    let router = Arc::new(router);

    // run server
    HttpServer::run_server(executor, host, port, router).await
}

fn main() -> SimpleResult<()> {
    Arc::<Executor>::with_main(|ex| smol::block_on(async_main(ex.clone())))
}