{-# LANGUAGE CPP #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FunctionalDependencies #-}
#ifdef TRUSTWORTHY
{-# LANGUAGE Trustworthy #-}
#endif
-----------------------------------------------------------------------------
-- |
-- Module      :  Control.Lens.Internal.Action
-- Copyright   :  (C) 2012-2014 Edward Kmett
-- License     :  BSD-style (see the file LICENSE)
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  provisional
-- Portability :  non-portable
--
----------------------------------------------------------------------------
module Control.Lens.Action.Internal
  (
  -- ** Actions
    Effective(..)
  , Effect(..)
  ) where

import Control.Applicative
import Control.Applicative.Backwards
import Control.Monad
import Data.Functor.Bind
import Data.Functor.Contravariant
import Data.Functor.Identity
import Data.Profunctor.Unsafe
import Data.Semigroup

import Control.Lens.Internal.Getter

-------------------------------------------------------------------------------
-- Programming with Effects
-------------------------------------------------------------------------------

-- | An 'Effective' 'Functor' ignores its argument and is isomorphic to a 'Monad' wrapped around a value.
--
-- That said, the 'Monad' is possibly rather unrelated to any 'Applicative' structure.
class (Monad m, Functor f, Contravariant f) => Effective m r f | f -> m r where
  effective :: m r -> f a
  ineffective :: f a -> m r

instance Effective m r f => Effective m (Dual r) (Backwards f) where
  effective = Backwards . effective . liftM getDual
  {-# INLINE effective #-}
  ineffective = liftM Dual . ineffective . forwards
  {-# INLINE ineffective #-}

instance Effective Identity r (Const r) where
  effective = Const #. runIdentity
  {-# INLINE effective #-}
  ineffective = Identity #. getConst
  {-# INLINE ineffective #-}

instance Effective m r f => Effective m r (AlongsideLeft f b) where
  effective = AlongsideLeft . effective
  {-# INLINE effective #-}
  ineffective = ineffective . getAlongsideLeft
  {-# INLINE ineffective #-}

instance Effective m r f => Effective m r (AlongsideRight f b) where
  effective = AlongsideRight . effective
  {-# INLINE effective #-}
  ineffective = ineffective . getAlongsideRight
  {-# INLINE ineffective #-}

------------------------------------------------------------------------------
-- Effect
------------------------------------------------------------------------------

-- | Wrap a monadic effect with a phantom type argument.
newtype Effect m r a = Effect { getEffect :: m r }
-- type role Effect representational nominal phantom

instance Functor (Effect m r) where
  fmap _ (Effect m) = Effect m
  {-# INLINE fmap #-}

instance Contravariant (Effect m r) where
  contramap _ (Effect m) = Effect m
  {-# INLINE contramap #-}

instance Monad m => Effective m r (Effect m r) where
  effective = Effect
  {-# INLINE effective #-}
  ineffective = getEffect
  {-# INLINE ineffective #-}

instance (Apply m, Semigroup r) => Semigroup (Effect m r a) where
  Effect ma <> Effect mb = Effect (liftF2 (<>) ma mb)
  {-# INLINE (<>) #-}

instance (Monad m, Monoid r) => Monoid (Effect m r a) where
  mempty = Effect (return mempty)
  {-# INLINE mempty #-}
  Effect ma `mappend` Effect mb = Effect (liftM2 mappend ma mb)
  {-# INLINE mappend #-}

instance (Apply m, Semigroup r) => Apply (Effect m r) where
  Effect ma <.> Effect mb = Effect (liftF2 (<>) ma mb)
  {-# INLINE (<.>) #-}

instance (Applicative m, Monoid r) => Applicative (Effect m r) where
  pure _ = Effect (return mempty)
  {-# INLINE pure #-}
  Effect ma <*> Effect mb = Effect (liftA2 mappend ma mb)
  {-# INLINE (<*>) #-}
