# tehillim-data

Benchmark result data produced by [tehillim-evaluate](https://github.com/rdtaylorjr/tehillim-evaluate),
scoring the vectors from [tehillim-representations](https://github.com/rdtaylorjr/tehillim-representations)
against Psalms parallelism and genre annotations. Kept in a separate repo from the code that
produces it, since result parquet files run tens of megabytes each and bloat a code repo's clone
size and history.

## Layout

Hive-partitioned the same way as `tehillim-representations`'s `data/type=X/unit=Y/construction=Z/`:
`benchmark={parallelism,genre,trajectory}/family={lexical,semantic,morphological,phrase}/stage=W/...`.

* `benchmark=parallelism/family={lexical,semantic,morphological,phrase}/`: `stage=raw`
  (retrieval-pair AP/AUC/calibration CSVs), `stage=detail` (per-observation Parquet export),
  `stage=master` (the joined final Parquet report), `stage=shuffle_control` (order-shuffle-null
  control CSV, where present).
* `benchmark=genre/family={lexical,semantic,morphological,phrase}/`: `stage=raw`
  (genre-discrimination AP/AUC/calibration CSVs, per-genre breakdown, bootstrap CIs), `stage=detail`
  (per-pair detail Parquet), `stage=master` (the joined final report), `stage=shuffle_control`
  (order-shuffle-null control CSV, where present).
* `benchmark=trajectory/family={lexical,semantic,morphological,phrase}/`: `stage=profiles`
  (per-model, per-psalm content/structural profiles and the pairwise distance Parquet derived from
  them), `stage=raw` (the pooled and per-genre genre-validation permutation test CSVs), `stage=ui`
  (`ui_rows.json`/`ui_rows_by_genre.json`, `tehillim-evaluate`'s `export_ui_rows` output). No
  `master` or `shuffle_control` stage: trajectory has no joined report and no order-shuffle-null
  control.
* `ui_lexical.json`, `ui_semantic.json`, `ui_morphology.json`, `ui_syntax.json`: the family
  payloads `tehillim-evaluate`'s `ui_export.export` produces, rendered by
  [tehillim-ui](https://github.com/rdtaylorjr/tehillim-ui)'s results page.
  The UI's family names (`morphology`, `syntax`) differ from `tehillim-representations`'s
  package/directory names (`morphological`, `phrase`) on purpose: the UI groups families by
  linguistic level for presentation, while this repo's directories mirror
  `tehillim-representations`'s own `type=`/`src/` naming for the data that actually produced them.
  `ui_export.export`'s shuffle-control exclusion (`build_family_data`) strips every
  `_shuffleNN`-suffixed model from all six of a family's UI tables, so none of these files ever
  carry the order-shuffle-null variants as if they were real, rankable models.

`family=morphological` and `family=phrase` have no `stage=shuffle_control`: their order-shuffle-null
variants (`construction=*_shuffleNN` in `tehillim-representations`) are scored as ordinary rows in
`stage=raw`/`stage=master` alongside the real embeddings, rather than through a dedicated
`order_shuffle_result` summary script, so `delta_order`/p are computed ad hoc from those rows
rather than persisted as their own file. `family=morphological` also excludes the `morph_signature`
trigram construction (`tehillim-representations`' sparse `node_id`/`indices`/`values` schema),
since the scoring scripts that produced this checkout's `family=morphological` data read only the
dense schema; `family=phrase` has no sparse construction to exclude (its largest signature-trigram
family, dim 14,424, is stored dense throughout).

`stage=master`'s Parquet files no longer duplicate `stage=detail`'s (the detail Parquet files used
to be copied into `master/` as well; `build_master_report.py` in both `parallelism` and `genre`
stopped doing that once `detail` and `master` sat side by side in the same checkout, since copying
them added no benefit `detail/` didn't already provide).

The order-shuffle-null control's *embeddings* (the shuffled vectors themselves, not the CSV
summary) live in `tehillim-representations`'s
`data/type=lexical/unit=homograph/construction=*_shuffleNN/`, alongside the main lexical data,
since they're generated data of the same kind, not a benchmark result.

## Regenerating

Every file here is produced by scripts in `tehillim-evaluate`. See that repo's README for the
exact commands per benchmark. Scoring scripts cache by default, a script skips any model already
present in the `--output` path, so pointing them back at this checkout only scores models
missing from it.

## Family

* [tehillim-evaluate](https://github.com/rdtaylorjr/tehillim-evaluate): the benchmark code that
  produces this data
* [tehillim-ui](https://github.com/rdtaylorjr/tehillim-ui): the results page that renders the
  `ui_*.json` files here
* [tehillim-representations](https://github.com/rdtaylorjr/tehillim-representations): the embedding
  vectors scored here

## License

MIT

## Author

* [Russell D. Taylor Jr.](mailto:rdtaylorjr@gatech.edu)
