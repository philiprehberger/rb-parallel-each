# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this gem adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-03-26

### Changed

- Fix README compliance (sponsor badge format, license link, quote style)

## [0.1.0] - 2026-03-26

### Added

- Initial release
- `ParallelEach.map` with ordered results and configurable thread pool
- `ParallelEach.each` for parallel iteration
- `ParallelEach.select` for parallel filtering
- `ParallelEach.flat_map` for parallel flat mapping
- `ParallelEach.any?` with short-circuit behavior
- Configurable concurrency (defaults to `Etc.nprocessors`)
- Error propagation re-raises the first exception encountered

[Unreleased]: https://github.com/philiprehberger/rb-parallel-each/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/philiprehberger/rb-parallel-each/releases/tag/v0.1.0
