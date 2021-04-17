{-# LANGUAGE CPP #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
#ifdef TRUSTWORTHY
{-# LANGUAGE Trustworthy #-}
#endif
-----------------------------------------------------------------------------
-- |
-- Module      :  Control.Lens.Action.Reified
-- Copyright   :  (C) 2012-14 Edward Kmett
-- License     :  BSD-style (see the file LICENSE)
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  experimental
-- Portability :  non-portable
--
----------------------------------------------------------------------------
module Control.Lens.Action.Reified where

import Control.Applicative
import Control.Arrow
import qualified Control.Category as Cat
import Control.Lens hiding ((<.>))
import Control.Monad
import Control.Monad.Reader.Class
import Data.Functor.Contravariant
import Data.Functor.Bind
import Data.Functor.Plus
import Data.Profunctor
#if !(MIN_VERSION_base(4,11,0))
import Data.Semigroup
#endif

import Control.Lens.Action

------------------------------------------------------------------------------
-- MonadicFold
------------------------------------------------------------------------------

-- | Reify a 'MonadicFold' so it can be stored safely in a container.
--
newtype ReifiedMonadicFold m s a = MonadicFold { runMonadicFold :: MonadicFold m s a }

instance Profunctor (ReifiedMonadicFold m) where
  dimap f g l = MonadicFold (to f . runMonadicFold l . to g)
  {-# INLINE dimap #-}
  rmap g l = MonadicFold (runMonadicFold l . to g)
  {-# INLINE rmap #-}
  lmap f l = MonadicFold (to f . runMonadicFold l)
  {-# INLINE lmap #-}

instance Strong (ReifiedMonadicFold m) where
  first' l = MonadicFold $ \f (s,c) ->
    phantom $ runMonadicFold l (dimap (flip (,) c) phantom f) s
  {-# INLINE first' #-}
  second' l = MonadicFold $ \f (c,s) ->
    phantom $ runMonadicFold l (dimap ((,) c) phantom f) s
  {-# INLINE second' #-}

instance Choice (ReifiedMonadicFold m) where
  left' (MonadicFold l) = MonadicFold $
    to tuplify.beside (folded.l.to Left) (folded.to Right)
    where
      tuplify (Left lval) = (Just lval,Nothing)
      tuplify (Right rval) = (Nothing,Just rval)
  {-# INLINE left' #-}

instance Cat.Category (ReifiedMonadicFold m) where
  id = MonadicFold id
  l . r = MonadicFold (runMonadicFold r . runMonadicFold l)
  {-# INLINE (.) #-}

instance Arrow (ReifiedMonadicFold m) where
  arr f = MonadicFold (to f)
  {-# INLINE arr #-}
  first = first'
  {-# INLINE first #-}
  second = second'
  {-# INLINE second #-}

instance ArrowChoice (ReifiedMonadicFold m) where
  left = left'
  {-# INLINE left #-}
  right = right'
  {-# INLINE right #-}

instance ArrowApply (ReifiedMonadicFold m) where
  app = MonadicFold $ \cHandler (argFold,b) ->
     runMonadicFold (pure b >>> argFold) cHandler (argFold,b)
  {-# INLINE app #-}

instance Functor (ReifiedMonadicFold m s) where
  fmap f l = MonadicFold (runMonadicFold l.to f)
  {-# INLINE fmap #-}

instance Apply (ReifiedMonadicFold m s) where
  mf <.> ma = mf &&& ma >>> (MonadicFold $ to (uncurry ($)))
  {-# INLINE (<.>) #-}

instance Applicative (ReifiedMonadicFold m s) where
  pure a = MonadicFold $ folding $ \_ -> [a]
  {-# INLINE pure #-}
  mf <*> ma = mf <.> ma
  {-# INLINE (<*>) #-}

instance Alternative (ReifiedMonadicFold m s) where
  empty = MonadicFold ignored
  {-# INLINE empty #-}
  MonadicFold ma <|> MonadicFold mb = MonadicFold $ to (\x->(x,x)).beside ma mb
  {-# INLINE (<|>) #-}

instance Bind (ReifiedMonadicFold m s) where
  ma >>- f = ((ma >>^ f) &&& returnA) >>> app
  {-# INLINE (>>-) #-}

instance Monad (ReifiedMonadicFold m s) where
#if !(MIN_VERSION_base(4,11,0))
  return a = MonadicFold $ folding $ \_ -> [a]
  {-# INLINE return #-}
#endif
  ma >>= f = ((ma >>^ f) &&& returnA) >>> app
  {-# INLINE (>>=) #-}

instance MonadReader s (ReifiedMonadicFold m s) where
  ask = returnA
  {-# INLINE ask #-}
  local f ma = f ^>> ma
  {-# INLINE local #-}

instance MonadPlus (ReifiedMonadicFold m s) where
  mzero = empty
  {-# INLINE mzero #-}
  mplus = (<|>)
  {-# INLINE mplus #-}

instance Semigroup (ReifiedMonadicFold m s a) where
  (<>) = (<|>)
  {-# INLINE (<>) #-}

instance Monoid (ReifiedMonadicFold m s a) where
  mempty = MonadicFold ignored
  {-# INLINE mempty #-}
#if !(MIN_VERSION_base(4,11,0))
  mappend = (<|>)
  {-# INLINE mappend #-}
#endif

instance Alt (ReifiedMonadicFold m s) where
  (<!>) = (<|>)
  {-# INLINE (<!>) #-}

instance Plus (ReifiedMonadicFold m s) where
  zero = MonadicFold ignored
  {-# INLINE zero #-}

