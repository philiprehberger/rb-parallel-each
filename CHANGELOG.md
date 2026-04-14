# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this gem adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-04-14

### Added

- `ParallelEach.reject` for parallel inverse filtering with order preservation
- `ParallelEach.find` for parallel search with short-circuit behavior
- `ParallelEach.all?` for parallel check that all elements satisfy a condition

## [0.2.1] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.2.0] - 2026-03-31

### Added

- `ParallelEach.map_with_index` for parallel map with index access
- `ParallelEach.each_with_index` for parallel iteration with index
- `ParallelEach.none?` as complement to `any?`
- `ParallelEach.count` for parallel counting of matching elements
- `ParallelEach.reduce` for sequential reduction over collection
- GitHub issue templates, PR template, and Dependabot configuration

### Changed

- README restructured with all 8 standard badges and Support section

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

[Unreleased]: https://github.com/philiprehberger/rb-parallel-each/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/philiprehberger/rb-parallel-each/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/philiprehberger/rb-parallel-each/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/philiprehberger/rb-parallel-each/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/philiprehberger/rb-parallel-each/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/philiprehberger/rb-parallel-each/releases/tag/v0.1.0
