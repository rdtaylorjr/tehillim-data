# One command regenerates the whole project: representations, benchmarks, comparisons, payloads.
from pathlib import Path

HERE = Path(str(workflow.current_basedir)).resolve()
REPOS = HERE.parent
EMBEDDINGS = REPOS / "tehillim-embeddings"
BENCHMARK = REPOS / "tehillim-benchmark"
COMPARE = REPOS / "tehillim-compare"
GUNKEL = REPOS / "tehillim-gunkel"

GENRE_CSV = Path(config.get("genre_csv", REPOS / "tehillim-logos/source/psalms-browser.csv"))
GUNKEL_CSV = Path(config.get("gunkel_csv", GUNKEL / "tables/gunkel.csv"))
UI_ROOT = Path(config.get("ui_root", REPOS / "tehillim"))
GPU = int(config.get("gpu", 0))
WORKERS = int(config.get("workers", 4))


module embeddings:
    snakefile:
        str(EMBEDDINGS / "Snakefile")
    config:
        {
            "data_root": str(EMBEDDINGS / "data"),
            "config_root": str(EMBEDDINGS / "config"),
            "gpu": GPU,
        }


use rule * from embeddings as embeddings_*


module benchmark:
    snakefile:
        str(BENCHMARK / "Snakefile")
    config:
        {
            "data_root": str(HERE),
            "embeddings_root": str(EMBEDDINGS / "data"),
            "config_root": str(EMBEDDINGS / "config"),
            "genre_csv": str(GENRE_CSV),
            "gunkel_csv": str(GUNKEL_CSV),
            "ui_root": str(UI_ROOT),
            "workers": WORKERS,
        }


use rule * from benchmark as benchmark_*


module compare:
    snakefile:
        str(COMPARE / "Snakefile")
    config:
        {
            "data_root": str(HERE),
            "embeddings_root": str(EMBEDDINGS / "data"),
            "ui_root": str(UI_ROOT),
            "workers": WORKERS,
        }


use rule * from compare as compare_*


rule all:
    default_target: True
    input:
        rules.embeddings_all.input,
        rules.benchmark_all.input,
        rules.compare_all.input,
    shell:
        "cd {EMBEDDINGS} && .venv/bin/python -m core.driver manifest --data-root data --config-root config"
        " && cd {BENCHMARK} && .venv/bin/python -m library.driver manifest"
        " --data-root {HERE} --embeddings-root {EMBEDDINGS}/data --config-root {EMBEDDINGS}/config"
        " --genre-csv {GENRE_CSV} --gunkel-csv {GUNKEL_CSV} --ui-root {UI_ROOT}"
        " --workers {WORKERS} --log-root {HERE}/logs"
        " && cd {COMPARE} && .venv/bin/python -m tehillim_compare.driver manifest"
        " --data-root {HERE} --embeddings-root {EMBEDDINGS}/data --ui-root {UI_ROOT}"
        " --workers {WORKERS} --log-root {HERE}/logs"
