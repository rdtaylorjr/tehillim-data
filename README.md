# tehillim-data

Benchmark result data produced by [tehillim-benchmarks](https://github.com/rdtaylorjr/tehillim-benchmarks),
scoring the vectors from [tehillim-embeddings](https://github.com/rdtaylorjr/tehillim-embeddings)
against Psalms parallelism and genre annotations. Kept in a separate repo from the code that
produces it, since result parquet files run tens of megabytes each and bloat a code repo's clone
size and history.

## Layout

Hive-partitioned the same way as `tehillim-embeddings`'s `data/domain=X/unit=Y/construction=Z/`:
`benchmark={parallelism,genre,trajectory}/domain={lexical,semantic,morphology,syntax}/stage=W/...`.

* `benchmark=parallelism/domain={lexical,semantic,morphology,syntax}/`: `stage=raw`
  (retrieval-pair AP/AUC/calibration CSVs), `stage=detail` (per-observation Parquet export),
  `stage=master` (the joined final Parquet report), `stage=shuffle_control` (order-shuffle-null
  control CSV, where present).
* `benchmark=genre/domain={lexical,semantic,morphology,syntax}/`: `stage=raw`
  (genre-discrimination AP/AUC/calibration CSVs, per-genre breakdown, bootstrap CIs), `stage=detail`
  (per-pair detail Parquet), `stage=master` (the joined final report), `stage=shuffle_control`
  (order-shuffle-null control CSV, where present).
* `benchmark=trajectory/domain={lexical,semantic,morphology,syntax}/`: `stage=profiles`
  (per-model, per-psalm content/structural profiles and the pairwise distance Parquet derived from
  them), `stage=raw` (the pooled and per-genre genre-validation permutation test CSVs), `stage=ui`
  (`ui_rows.json`/`ui_rows_by_genre.json`, `tehillim-benchmarks`'s `export_ui_rows` output). No
  `master` or `shuffle_control` stage: trajectory has no joined report and no order-shuffle-null
  control.

The domain payloads `ui_export.export` produces are published to
[tehillim-react](https://github.com/rdtaylorjr/tehillim-react) rather than stored here: one core
file per domain plus a per-metric file for the per-genre trajectory rows, which the site fetches
only when that view is opened. Their domain names (`morphology`, `syntax`) match
`tehillim-embeddings`'s `domain=`/`src/` naming for the data that produced them, and
`build_domain_data`'s shuffle-control exclusion strips every `_shuffleNN`-suffixed model from all
six tables, so no payload carries an order-shuffle-null variant as a rankable model.

`domain=morphology` and `domain=syntax` have no `stage=shuffle_control`: their order-shuffle-null
variants (`construction=*_shuffleNN` in `tehillim-embeddings`) are scored as ordinary rows in
`stage=raw`/`stage=master` alongside the real embeddings, rather than through a dedicated
`order_shuffle_result` summary script, so `delta_order`/p are computed ad hoc from those rows
rather than persisted as their own file. `domain=morphology` also excludes the `morph_signature`
trigram construction (`tehillim-embeddings`' sparse `node_id`/`indices`/`values` schema),
since the scoring scripts that produced this checkout's `domain=morphology` data read only the
dense schema; `domain=syntax` has no sparse construction to exclude (its largest signature-trigram
family, dim 14,424, is stored dense throughout).

`stage=master`'s Parquet files no longer duplicate `stage=detail`'s (the detail Parquet files used
to be copied into `master/` as well; `build_master_report.py` in both `parallelism` and `genre`
stopped doing that once `detail` and `master` sat side by side in the same checkout, since copying
them added no benefit `detail/` didn't already provide).

The order-shuffle-null control's *embeddings* (the shuffled vectors themselves, not the CSV
summary) live in `tehillim-embeddings`'s
`data/domain=lexical/unit=homograph/construction=*_shuffleNN/`, alongside the main lexical data,
since they're generated data of the same kind, not a benchmark result.

## Regenerating

Every file here is produced by scripts in `tehillim-benchmarks`. See that repo's README for the
exact commands per benchmark. Scoring scripts cache by default, a script skips any model already
present in the `--output` path, so pointing them back at this checkout only scores models
missing from it.

## Data sources

The parallelism and genre classifications reflected in this repo's benchmark outputs (`parallel_*`
BHSA features and the genre-classification data) are derived from the Logos Psalms Explorer
Dataset, used with permission. Full citation in
[tehillim-benchmarks](https://github.com/rdtaylorjr/tehillim-benchmarks)'s README.

## Family

* [tehillim-benchmarks](https://github.com/rdtaylorjr/tehillim-benchmarks): the benchmark code that
  produces this data
* [tehillim-react](https://github.com/rdtaylorjr/tehillim-react): the results site, which carries
  and renders the domain payloads
* [tehillim-embeddings](https://github.com/rdtaylorjr/tehillim-embeddings): the embedding
  vectors scored here

## License

MIT

## Author

* [Russell D. Taylor Jr.](mailto:rdtaylorjr@gatech.edu)
