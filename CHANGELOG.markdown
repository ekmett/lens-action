0.2.5 [2021.02.17]
------------------
* Allow building with `lens-5.*`.
* The build-type has been changed from `Custom` to `Simple`.
  To achieve this, the `doctests` test suite has been removed in favor of using
  [`cabal-docspec`](https://github.com/phadej/cabal-extras/tree/master/cabal-docspec)
  to run the doctests.

0.2.4 [2019.09.13]
------------------
* Remove the use of `cpp-options: -traditional`. This should be unnecessary
  on all versions of GHC that `lens` supports, as modern GHCs already use
  `-traditional` internally during preprocessing. More critically, the use
  of `cpp-options: -traditional` breaks profiling builds on GHC 8.8
  (see https://gitlab.haskell.org/ghc/ghc/issues/17185).

0.2.3 [2018.01.18]
------------------
* Add an `Apply` context to the `Monoid` instance for `Effect`, allowing
  `lens-action` to build against `lens-4.16`.

0.2.2
-----
* Add a library dependency for the `doctests` test suite

0.2.1
-----
* Revamp `Setup.hs` to use `cabal-doctest`. This makes it build
  with `Cabal-2.0`, and makes the `doctest`s work with `cabal new-build` and
  sandboxes.

0.2.0.2
---
* Migrate to new `phantom` definition in `contravariant`

0.2.0.1
---
* Add `Control.Lens.Action.Type` to exposed-modules list.

0.2
---
* `profunctors-5` and `lens-4.10` support

0.1.0.1
---
* Add `Control.Lens.Action.Type` to exposed-modules list.

0.1
----
* Initial split from lens package
