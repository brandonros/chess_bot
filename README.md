# chess_engine_api

Rust JSON API over chess move scoring engine

## How to use

```shell
curl --verbose -X POST -H 'Content-Type: application/json' https://chess-engine-api.debian-k3s/move/best -d '{
  "engine": "rustic",
  "depth": 6,
  "fen": "rnbqkbnr/pp1pppp1/8/2p4p/4P3/2P5/PP1P1PPP/RNBQKBNR w KQkq h6 0 3"
}'
```
