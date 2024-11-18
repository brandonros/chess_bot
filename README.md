# chess_engine_api

Rust JSON API over chess move scoring engine

## Quick Start

```shell
cargo run
curl --verbose -X POST -H 'Content-Type: application/json' http://localhost:8080/move/best -d '{
  "engine": "rustic",
  "depth": 6,
  "fen": "rnbqkbnr/pp1pppp1/8/2p4p/4P3/2P5/PP1P1PPP/RNBQKBNR w KQkq h6 0 3"
}'
```

## API Reference

### Get Best Move

Returns the best chess move for a given position according to the specified engine.

**Endpoint:** `POST /move/best`

**Request:**
```json
{
  "engine": "rustic",
  "depth": 6,
  "fen": "rnbqkbnr/pp1pppp1/8/2p4p/4P3/2P5/PP1P1PPP/RNBQKBNR w KQkq h6 0 3"
}
```

**Response:**
```json
{
  "best_move": "e4e5"
}
```

## Credits

- Chess analysis powered by [Rustic](https://github.com/mvanthoor/rustic)
