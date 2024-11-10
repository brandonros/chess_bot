mod routes;
mod structs;
mod chess;

use std::sync::Arc;

use http_server::{HttpServer, Router};
use opentelemetry_otlp::WithExportConfig as _;
use simple_error::SimpleResult;
use smol::{Executor, MainExecutor};

use opentelemetry_sdk::trace::TracerProvider;
use opentelemetry::trace::TracerProvider as _;
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::Registry;

async fn async_main(executor: Arc<Executor<'static>>) -> SimpleResult<()> {    
    // tracing
    let traces_endpoint = "http://tempo.node.external/v1/traces";
    let otlp_exporter = opentelemetry_otlp::SpanExporterBuilder::Http(
        opentelemetry_otlp::new_exporter()
            .http()
            .with_endpoint(traces_endpoint),
    )
    .build_span_exporter()?;
    let provider = TracerProvider::builder()
        .with_simple_exporter(otlp_exporter)
        .build();
    let tracer = provider.tracer("chess-bot");
    let tracing_layer = tracing_opentelemetry::layer().with_tracer(tracer);

    // logging
    let fmt_layer = tracing_subscriber::fmt::layer();

    // metrics
    /*let builder = metrics_exporter_prometheus::PrometheusBuilder::new();
    builder
        .install()
        .expect("failed to install Prometheus recorder");
    metrics::gauge!("testing").set(42.0);*/

    // registry
    let registry = Registry::default()
        .with(fmt_layer)
        .with(tracing_layer);
    tracing::subscriber::set_global_default(registry)?;

    // settings
    let host = "0.0.0.0";
    let port = 8080;

    // build router
    let mut router = Router::new(executor.clone());
    router.add_route("GET", "/ping", Arc::new(move |executor, req| Box::pin(routes::get_ping(executor, req))));
    router.add_route("POST", "/chess/best-move", Arc::new(move |executor, req| Box::pin(routes::get_best_move(executor, req))));
    let router = Arc::new(router);

    // run server
    HttpServer::run_server(executor, host, port, router).await
}

fn main() -> SimpleResult<()> {
    Arc::<Executor>::with_main(|ex| smol::block_on(async_main(ex.clone())))
}
