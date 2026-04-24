# CROCUS-UES3 Scaffold - Container Architecture

## Overview

This scaffold provides a **service-per-container architecture** for the CROCUS-UES3 urban CFD simulation framework. Each service (city4cfd, crocus-tools, openfoam) is encapsulated in its own Apptainer container with source code in its own git repository.

## Key Design Principle

**Source code is encapsulated inside containers at build time, NOT bind-mounted at runtime.**

- Source code lives in git repos (e.g., `wangsen992/crocus-tools`, `wangsen992/openfoam-ext`)
- At container build time, source is cloned from git into the container image
- At runtime, only **data** (simulation cases, input/output) is bind-mounted
- This ensures reproducibility and self-contained containers

## Directory Structure

```
crocus-ues3-scaffold/
└── containers/
    ├── city4cfd/           # Pre-built mesh generator
    │   ├── city4cfd.def    # Apptainer definition
    │   ├── build.sh         # Build/pull script
    │   ├── run.sh          # Runtime wrapper
    │   ├── images/         # Compiled SIF images
    │   └── overlay/        # Persistent overlay (compiled code, cache)
    │
    ├── crocus-tools/        # Python preprocessing tools
    │   ├── python.def
    │   ├── build.sh
    │   ├── run.sh
    │   ├── images/
    │   └── overlay/
    │
    └── openfoam/           # ESI OpenFOAM + custom solvers
        ├── openfoam.def
        ├── build.sh
        ├── run.sh
        ├── images/
        └── overlay/
```

## Configuration

Each `run.sh` script accepts a `CROCUS_ROOT` environment variable to specify the project root:

```bash
# Example: run from any directory
CROCUS_ROOT=/path/to/CROCUS-UES3 ./containers/city4cfd/run.sh city4cfd --help

# Or export it for convenience
export CROCUS_ROOT=/scratch365/swang18/Workspace/Projects/CROCUS/CROCUS-UES3
./containers/city4cfd/run.sh city4cfd --help
```

If not set, scripts default to `../..` relative to the script location (assuming scaffold is nested in project).

## Environment Check

Run `check_env.sh` to verify your environment is properly configured:

```bash
# Check configuration
./check_env.sh

# Check with verbose output
./check_env.sh --verbose

# Auto-create missing directories
./check_env.sh --fix
```

## Three Services

### 1. city4cfd
- **Purpose**: Building and terrain mesh generation for urban CFD
- **Base Image**: `tudelft3d/city4cfd:latest` (pre-built Docker)
- **Source Repo**: https://github.com/tudelft3d/City4CFD (external, not our fork)
- **Build Time**: ~1 minute (just pulls pre-built image)

### 2. crocus-tools
- **Purpose**: Python preprocessing tools (LAS, geometry, canopy processing)
- **Base Image**: `python:3.11-slim` + dependencies
- **Source Repo**: https://github.com/wangsen992/crocus-tools
- **Build Time**: ~5 minutes
- **Overlay**: For pip-installed packages, not source

### 3. openfoam
- **Purpose**: ESI OpenFOAM-v2312 with custom solvers
- **Base Image**: `openfoam/openfoam2312:latest`
- **Source Repo**: https://github.com/wangsen992/openfoam-ext
- **Build Time**: ~60-90 minutes (compilation)
- **Overlay**: For compiled solvers and build artifacts

## Workflow

### At Build Time (Source Encapsulated)
```
git clone https://github.com/wangsen992/crocus-tools.git /opt/crocus-tools
pip install -e /opt/crocus-tools

git clone https://github.com/wangsen992/openfoam-ext.git /opt/openfoam-ext
cd /opt/openfoam-ext && ./Allwmake
```

### At Runtime (Data Bindings Only)
```
/data  → CROCUS_ROOT (project root)
/run   → $CROCUS_ROOT/run/ (simulation cases, rw)
/cases → $CROCUS_ROOT/cases/ (symlinks)
```

## Quick Start

### Set Project Root
```bash
export CROCUS_ROOT=/path/to/CROCUS-UES3
```

### Build city4cfd (fastest)
```bash
cd containers/city4cfd && ./build.sh
```

### Build crocus-tools
```bash
cd containers/crocus-tools && ./build.sh
```

### Build openfoam (slowest, ~60-90 min)
```bash
cd containers/openfoam && ./build.sh
```

### Test
```bash
./containers/city4cfd/run.sh city4cfd --help
./containers/crocus-tools/run.sh crocus --help
./containers/openfoam/run.sh foamVersion
```

## Standalone Repos

Each service has its own git repository for independent development:

| Service | Repo | Source Code |
|---------|------|-------------|
| `city4cfd` | https://github.com/tudelft3d/City4CFD (upstream) | city4cfd meshing tool |
| `crocus-tools` | https://github.com/wangsen992/crocus-tools | Python preprocessing |
| `openfoam-ext` | https://github.com/wangsen992/openfoam-ext | Custom OpenFOAM solvers |

## Build Script Options

Each `build.sh` supports:
- `--check` - Check if image exists, build if missing (default)
- `--rebuild` - Force rebuild from scratch
- `--pull` - Force pull latest (city4cfd only)
- `--help` - Show help

## Data Bindings

All containers bind-mount only data (NO source code):

| Container Path | Host Path | Purpose |
|---------------|-----------|---------|
| `/data` | CROCUS_ROOT/ | Project root |
| `/run` | $CROCUS_ROOT/run/ | Simulation cases (rw) |
| `/cases` | $CROCUS_ROOT/cases/ | Case symlinks |

## Overlay Persistence

The `overlay/` directories provide persistent writable layers for:

| Service | Overlay Contents |
|---------|------------------|
| `city4cfd` | None (pre-built, no changes) |
| `crocus-tools` | pip-installed packages |
| `openfoam` | Compiled solver binaries, build artifacts |

## Next Steps

1. Review this scaffold structure
2. Create GitHub repos for `crocus-tools` and `openfoam-ext`
3. Push source code to respective repos
4. Update CROCUS-UES3 `.gitmodules`
5. Build and test each container