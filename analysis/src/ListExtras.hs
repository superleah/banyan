{-# LANGUAGE NoImplicitPrelude #-}

module ListExtras
  ( invariant
  , shortest
  , shortest2
  , withSentinel
  ) where

import           Prelude   as UnsafePartial (tail)
import           Protolude

{-| `invariant f` is the *mathematical fixed point of f, i.e. the element x s.t.
f x == x.

Cf. `Data.function.fix`, which returns the *least-defined* fixed point.
-}
invariant :: Eq a => (a -> a) -> a -> a
invariant fn a =
  let b = fn a
  in if a == b
       then a
       else invariant fn b

-- | Apply each function to a value; return the shortest result
shortest :: Foldable f => [a -> f b] -> a -> f b
shortest funcs x = minimumBy (compare `on` length) $ funcs <*> [x]

shortest2 :: Foldable f => [a -> b -> f c] -> a -> b -> f c
shortest2 f =
  curry $ shortest $ fmap uncurry f

{-| Append a sentinel to each end of a list, apply the function, and remove the
first and last element of the result.

    withSentinel 'a' f "bcd" == head . init . f "abcda"
    withSentinel s id == id
-}
withSentinel :: a -> ([a] -> [b]) -> [a] -> [b]
withSentinel s func =
  let eachEnd f = f . reverse . f . reverse
  in eachEnd UnsafePartial.tail . func . eachEnd (s :)
