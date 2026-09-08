# tehillim-data

## Overview

This repository stores the materialized outputs of the Tehillim evaluation pipeline. It preserves benchmark tables, observation-level records, trajectory profiles, and interface payloads produced by [tehillim-benchmarks](https://github.com/rdtaylorjr/tehillim-benchmarks) from representations in [tehillim-embeddings](https://github.com/rdtaylorjr/tehillim-embeddings). It separates large derived artifacts from the code that creates and interprets them.

## Data

The current checkout contains 322 CSV, Parquet, and JSON result artifacts totaling about 4.45 GB. The count excludes repository metadata such as `package.json`. Paths use Hive-style partitions:

```
benchmark={parallelism,genre,trajectory}/domain={lexical,semantic,morphology,syntax}/stage={...}/
```

`parallelism` and `genre` each provide `raw` CSV outputs, `detail` observation-level Parquet records, and `master` long and wide reports. Where available, `shuffle_control` holds summaries of the lexical order-shuffle control. Parallelism detail records preserve group identifiers, annotation type and signature, source and target node spans, similarity, calibration, and directional ranks. Genre detail records preserve psalm pairs, source genre labels, similarity, and calibrated scores. The morphology parallelism detail file contains 263,070 rows, while its long master report contains 18,099 metric rows.

The partition inventory contains 41 parallelism, 34 genre, 246 trajectory, and one archived-control artifact. The parallelism master reports contain 766 model rows across the four domains. The genre master reports contain 222. These counts describe stored rows, including historical and intermediate results. They do not identify the subset exported to the public interface.

`trajectory` stores per-model profile shards and a `trajectory_distances.parquet` file for each representation domain, alongside raw validation tables and JSON summaries for the interface. The morphology trajectory-distance table contains 628,482 psalm-pair rows and five distance measures: content, self-similarity structure, adjacent similarity, step magnitude, and turning angle.

The source vectors, licensed Logos-derived annotations, and source genre CSV do not reside here. These outputs therefore preserve the computation's observable products rather than a complete archival substitute for its inputs.

## Methodology

The repository does not calculate metrics. Its partition layout records the analytic provenance of results produced in `tehillim-benchmarks`: the benchmark task, representation domain, and processing stage remain visible in each path. Raw files retain outputs from individual procedures. Detail files retain the observations from which a result can be inspected. Master files reshape compatible measures into long and wide analytic tables. Profile shards enable interrupted trajectory runs to resume without recomputing completed model and psalm combinations.

This structure distinguishes a result table from the observations and decisions that produced it. A row remains conditioned by the BHSA linguistic database, Logos-derived labels, representation construction, selection rules, and inferential procedure documented in the producing repositories. Partition names expose these conditions without converting them into claims about Hebrew poetic form.

## Results

The result corpus covers parallelism retrieval, genre discrimination, and trajectory analyses over lexical, morphology, syntax, and semantic representation domains. The master tables carry model identity, text variant, scope, metric source, value, and both Benjamini-Hochberg and Benjamini-Yekutieli adjusted values. The corpus makes it possible to compare metrics, inspect individual observations, and identify missing domains or stages.

The current public interface reports 148 parallelism variants and 222 genre variants. This checkout contains the 222 genre models, while its 766 parallelism models include a larger set of stored outputs. Paths and schemas provide no release mapping between the interface payloads and these files. A stored result can therefore be inspected, yet its presence alone does not establish that the interface displays it.

## Limitations

The artifacts are derived data. Their values cannot be read independently of the code version, input vector files, external annotations, and run configuration that generated them. The repository does not yet carry a versioned manifest that fixes this artifact count and file inventory. Sampled Parquet schemas carry pandas serialization metadata only, with no source revision, input fingerprint, configuration identifier, or generation time. Some stages are intentionally absent. Trajectory has no joined master report or dedicated order-shuffle summary. Morphology and syntax shuffle variants were scored as ordinary rows in some historical outputs, while the lexical domain stores dedicated control summaries. The morphology sparse signature-trigram representation is absent from the dense-only scoring outputs in this checkout.

The `archive=shuffle_control_n30` partition records an earlier 30-draw lexical control. It remains available for provenance and should not be combined with the current 1,000-draw control as though both had the same inferential resolution.

A future release should include a versioned manifest with checksums, upstream code and corpus revisions, input identifiers, seeds, and configuration values for every partition. Until then, a path establishes the type of result and does not establish a complete provenance record for a particular numerical value.

## Reproducibility

Regeneration requires the matching revision of `tehillim-benchmarks`, the relevant `tehillim-embeddings` vectors, permitted Logos-derived annotation access, the runtime genre CSV, and a compatible Python environment. Scoring scripts write deterministic partition names and retain model and variant identifiers. Cached scripts can skip model files already recorded in a target output path. A reproducible release also requires a manifest that maps each public payload and report to exact input and code revisions. Re-running into a new checkout is safer for an audit because it leaves the checked results unchanged.

## Installation

No installation is required to inspect the data. Parquet readers such as PyArrow, DuckDB, or pandas can read the tables.

## Usage

Read a master table with PyArrow:

```python
import pyarrow.parquet as pq

table = pq.read_table(
    "benchmark=parallelism/domain=morphology/stage=master/model_metrics_long.parquet"
)
print(table.schema)
```

## References

Logos Bible Software. [*Psalms Explorer Dataset*](https://www.logos.com/product/54188/psalms-explorer-dataset).

Andersen, Francis I., and A. Dean Forbes. “Problems in Taxonomy and Lemmatization.” Pages 37-50 in *Proceedings of the First International Colloquium: Bible and the Computer: The Text*. Paris-Geneva: Champion-Slatkine, 1986.

Bosman, Hendrik Jan, and Constantijn J. Sikkel. “A Discourse on Method: Basic Parameters of Computer-Assisted Linguistic Analysis on Word Level.” Pages 85-113 in *Corpus Linguistics and Textual History: A Computer-Assisted Interdisciplinary Approach to the Peshitta*. Assen: Van Gorcum, 2006.

Moreau, Luc, and Simon Miles, eds. 2013. [*PROV-DM: The PROV Data Model*](https://www.w3.org/TR/prov-dm/). W3C Recommendation.

Roorda, Dirk, Christiaan Erwich, Cody Kingham, and SeHoon Park. 2023. [*ETCBC/bhsa*](https://github.com/ETCBC/bhsa).

Roorda, Dirk. [“The Hebrew Bible as Data: Laboratory, Sharing, Experiences.”](https://doi.org/10.48550/arXiv.1501.01866) 2015.

Roorda, Dirk. [“Text-Fabric: Handling Biblical Data with IKEA Logistics.”](https://doi.org/10.7146/hn.v5i2.142740) *HIPHIL Novum* 5.2 (2019): 126-135.

Wilkinson, Mark D., Michel Dumontier, I. J. Aalbersberg, Gabrielle Appleton, Myles Axton, Arie Baak, Niklas Blomberg, et al. 2016. [“The FAIR Guiding Principles for Scientific Data Management and Stewardship.”](https://doi.org/10.1038/sdata.2016.18) *Scientific Data* 3: 160018.

## License

MIT. The Logos-derived annotation source and BHSA data have separate terms of use.
