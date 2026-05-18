<div align="center">

<img alt="simplemem_logo" src="https://github.com/user-attachments/assets/6ea54ad1-e007-442c-99d7-1174b10d1fec" width="450">

## SimpleMem — Efficient Lifelong Memory for LLM Agents

[![arXiv](https://img.shields.io/badge/arXiv-2601.02553-b31b1b?style=flat&labelColor=555)](https://arxiv.org/abs/2601.02553)
[![License](https://img.shields.io/github/license/aiming-lab/SimpleMem?style=flat&label=license&labelColor=555&color=2EA44F)](LICENSE)

</div>

Store, compress, and retrieve long-term memories with semantic lossless compression. One unified Python package; auto-routing between text and multimodal (image / audio / video) backends.

---

## 🚀 Quick Start

```python
from simplemem import SimpleMem

mem = SimpleMem()  # auto mode — backend chosen by first call

mem.add_dialogue(
    "Alice",
    "Bob, let's meet at Starbucks tomorrow at 2pm",
    "2025-11-15T14:30:00",
)
mem.add_dialogue(
    "Bob",
    "Sure, I'll bring the market analysis report",
    "2025-11-15T14:31:00",
)
mem.finalize()

answer = mem.ask("When and where will Alice and Bob meet?")
# → "16 November 2025 at 2:00 PM at Starbucks"
```

The first method you call selects the backend:

| First call | Backend |
|:--|:--|
| `add_dialogue()` | Text (SimpleMem) |
| `add_text()` / `add_image()` / `add_audio()` / `add_video()` | Multimodal (Omni-SimpleMem) |

For explicit control:

```python
from simplemem import create
mem = create(mode="text")   # or mode="omni"
```

### Tune retrieval (quick API)

Tune retrieval hyperparameters offline on your own dev set, then deploy the
resulting `Config` for inference:

```python
import simplemem
from simplemem import SimpleMem, load_config

dev_questions = [
    ("When is the meeting?", "2pm tomorrow"),
    ("What should Bob prepare?", "quarterly report and client feedback"),
]
config = simplemem.optimize(mem, dev_questions, max_rounds=3)
config.save("my_config.json")

# Later, deploy with optimized config
config = load_config("my_config.json")
mem = SimpleMem(config=config)
```

This is a thin convenience wrapper around EvolveMem's diagnosis loop. It runs
an LLM-driven Evaluate → Diagnose → Propose → Guard cycle on your
`dev_questions` and can toggle global retrieval flags (top_k, fusion mode,
answer verification, reflection rounds, entity swap, ...) based on which
questions the current config gets wrong.

For the full standalone EvolveMem with benchmark adapters and per-category
overrides, see `EvolveMem/README.md`.

---

## 📦 Installation

Requirements: **Python 3.10+** and an OpenAI-compatible API key.

```bash
git clone https://github.com/aiming-lab/SimpleMem.git
cd SimpleMem

pip install -e .                  # default: text + multimodal + evolver
pip install -e ".[server]"        # + MCP / HTTP server (mcp, fastapi, ...)
pip install -e ".[all]"           # everything, including dev tools

cp config.py.example config.py
# Edit config.py with your API key and (optional) base URL.
```

---

## 📋 TODO (refactor handoff)

Outstanding items from the `simplemem/` package merge. Drop these as fast as work lands; they're not visible to users of the text path but matter for finishing the unified package.

### 🟡 Non-blocking — legacy top-level dirs left in place

The pre-refactor sources (`models/`, `utils/`, `database/`, `core/`, `OmniSimpleMem/`) still sit at the repo root and are imported by `main.py`, `test_locomo10.py`, `tests/`, `cross/`, `SKILL/`, `MCP/`, and `simplemem/integrations/*`. They were intentionally **not** deleted in this pass to avoid breaking those entry points. To finish cleaning up:

- [ ] Rewrite each of the above to import from `simplemem.core.*` / `simplemem.multimodal` instead of the top-level paths.
- [ ] Delete the legacy top-level dirs once nothing depends on them.

Note: `EvolveMem/` is **intentionally kept** at the repo root as the self-contained, full EvolveMem standalone version with benchmark adapters and per-category overrides. See `EvolveMem/README.md`. It is not on the cleanup list.

### 🟢 Done in this refactor pass (for context)

- `simplemem/` unified package: router (`SimpleMem` / `create` / `list_modes`), `optimize`, `Config`, `load_config` — all importable.
- Text path validated end-to-end against `examples/quickstart.py` (Qwen3-Embedding-0.6B + LanceDB + Tantivy FTS).
- `simplemem/core/settings.py` reads user's `config.py` first, then env vars, then built-in defaults.
- `simplemem/multimodal/` imports rewritten from `omni_memory.*` to `simplemem.multimodal.*` (38 files).
- `simplemem/evolver/optimize.py` import path corrected (`simplemem.optimizer` → `simplemem.evolver`) and the stale `from evolvemem.multi_retriever import …` in `evolution.py` was retargeted to `simplemem.evolver.multi_retriever`.
- `setup.py` with `install_requires` grounded in `MCP/requirements.txt`, `OmniSimpleMem/setup.py`, and commit `9686aa5`'s canonical `pyproject.toml`. `pip install --dry-run -e .` and `-e ".[server]"` both resolve cleanly.
- `simplemem/config.py`, `simplemem/evolver/config.py`, `simplemem/multimodal/core/config.py` added in `d59fa45` (root-cause was an over-broad `.gitignore` rule; fixed there too). All `simplemem.*` subpackages now import cleanly.
- `EvolveMem/evolvemem/config.py` added (defaults matching MetaMem `99cd447`). The standalone `python EvolveMem/run_evolution.py` entry point now imports and bootstraps without errors.
- `simplemem/evolver/optimize.py` rewritten as a real degraded-mode wrapper over `EvolutionEngine.evolve()`. Smoke-tested end-to-end against a 3-dialogue / 3-question dev set on Azure gpt-4o-mini + MiniLM embedder.

---

## 📝 Citation

If you use SimpleMem in your research, please cite:

```bibtex
@article{simplemem2026,
  title={SimpleMem: Efficient Lifelong Memory for LLM Agents},
  author={Liu, Jiaqi and Su, Yaofeng and Xia, Peng and Zhou, Yiyang and Han, Siwei and  Zheng, Zeyu and Xie, Cihang and Ding, Mingyu and Yao, Huaxiu},
  journal={arXiv preprint arXiv:2601.02553},
  year={2026},
  url={https://arxiv.org/abs/2601.02553}
}
```

```bibtex
@article{evolvemem2026,
  title={EvolveMem: Self-Evolving Memory Architecture via AutoResearch for LLM Agents},
  author={Liu, Jiaqi and Ye, Xinyu and Xia, Peng and Zheng, Zeyu and Xie, Cihang and Ding, Mingyu and Yao, Huaxiu},
  journal={arXiv preprint arXiv:2605.13941},
  year={2026},
  url={https://arxiv.org/abs/2605.13941}
}
```

```bibtex
@article{omnisimplemem2026,
  title   = {Omni-SimpleMem: Autoresearch-Guided Discovery of Lifelong Multimodal Agent Memory},
  author  = {Liu, Jiaqi and Ling, Zipeng and Qiu, Shi and Liu, Yanqing and Han, Siwei and Xia, Peng and Tu, Haoqin and Zheng, Zeyu and Xie, Cihang and Fleming, Charles and Ding, Mingyu and Yao, Huaxiu},
  journal = {arXiv preprint arXiv:2604.01007},
  year    = {2026},
}
```

---

## 📄 License

MIT — see [LICENSE](LICENSE).
