# tehillim-data

Benchmark result data produced by [tehillim-evaluate](https://github.com/rdtaylorjr/tehillim-evaluate),
scoring the vectors from [tehillim-representations](https://github.com/rdtaylorjr/tehillim-representations)
against Psalms parallelism and genre annotations. Kept in its own repo, separate from the code that
produces it, since result parquet files run tens of megabytes each and bloat a code repo's clone
size and history.

## Layout

* `parallelism/{lexical,semantic}/`: retrieval-pair AP/AUC/calibration CSVs, per-observation detail
  parquet, and the joined master Parquet report, one tree per representation family.
* `genre/{lexical,semantic}/`: genre-discrimination AP/AUC/calibration CSVs, per-genre breakdown,
  bootstrap CIs, per-pair detail parquet, and the joined master report.
* `trajectory/{lexical,semantic}/`: per-psalm content/structural profiles, pairwise distances, the
  pooled and per-genre genre-validation permutation test results.
* `dashboard_lexical.json`, `dashboard_semantic.json`: the two family payloads
  `tehillim-evaluate`'s `dashboard.export` produces, spliced into the results dashboard.

## Regenerating

Every file here is produced by scripts in `tehillim-evaluate`. See that repo's README for the
exact commands per benchmark. Scoring scripts cache by default, a script skips any model already
present in its own `--output` path, so pointing them back at this checkout only scores models
missing from it.

## Family

* [tehillim-evaluate](https://github.com/rdtaylorjr/tehillim-evaluate): the benchmark code that
  produces this data
* [tehillim-representations](https://github.com/rdtaylorjr/tehillim-representations): the embedding
  vectors scored here

## License

MIT

## Author

* [Russell D. Taylor Jr.](mailto:rdtaylorjr@gatech.edu)
