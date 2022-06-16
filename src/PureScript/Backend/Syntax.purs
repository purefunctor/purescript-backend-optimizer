module PureScript.Backend.Syntax where

import Prelude

import Data.Array.NonEmpty (NonEmptyArray)
import Data.Maybe (Maybe)
import Data.Newtype (class Newtype)
import Data.Traversable (class Foldable, class Traversable, foldMap, foldlDefault, foldrDefault, sequenceDefault, traverse)
import Data.Tuple (Tuple)
import PureScript.CoreFn (Ident, Literal(..), Prop, Qualified)

data BackendSyntax a
  = Var (Qualified Ident)
  | Local (Maybe Ident) Level
  | Lit (Literal a)
  | App a (NonEmptyArray a)
  | Abs (NonEmptyArray (Tuple (Maybe Ident) Level)) a
  | UncurriedApp a (Array a)
  | UncurriedAbs (Array (Tuple (Maybe Ident) Level)) a
  | UncurriedEffectApp a (Array a)
  | UncurriedEffectAbs (Array (Tuple (Maybe Ident) Level)) a
  | Accessor a BackendAccessor
  | Update a (Array (Prop a))
  | CtorSaturated (Qualified Ident) Ident (Array (Tuple Ident a))
  | CtorDef Ident (Array Ident)
  | LetRec Level (Array (Tuple Ident a)) a
  | Let (Maybe Ident) Level a a
  | EffectBind (Maybe Ident) Level a a
  | EffectPure a
  | Branch (Array (Pair a)) (Maybe a)
  | PrimOp (BackendOperator a)
  | Fail String

newtype Level = Level Int

derive newtype instance Eq Level
derive newtype instance Ord Level
derive instance Newtype Level _

data Pair a = Pair a a

data BackendAccessor
  = GetProp String
  | GetIndex Int
  | GetOffset Int

derive instance Eq BackendAccessor
derive instance Ord BackendAccessor

data BackendOperator a
  = Op1 BackendOperator1 a
  | Op2 BackendOperator2 a a

data BackendOperator1
  = OpBooleanNot
  | OpIntBitNot
  | OpIntNegate
  | OpNumberNegate
  | OpArrayLength
  | OpIsTag (Qualified Ident)

data BackendOperator2
  = OpBooleanAnd
  | OpBooleanOr
  | OpBooleanOrd BackendOperatorOrd
  | OpCharOrd BackendOperatorOrd
  | OpIntBitAnd
  | OpIntBitOr
  | OpIntBitShiftLeft
  | OpIntBitShiftRight
  | OpIntBitXor
  | OpIntBitZeroFillShiftRight
  | OpIntNum BackendOperatorNum
  | OpIntOrd BackendOperatorOrd
  | OpNumberNum BackendOperatorNum
  | OpNumberOrd BackendOperatorOrd
  | OpStringAppend
  | OpStringOrd BackendOperatorOrd

data BackendOperatorNum
  = OpAdd
  | OpDivide
  | OpMultiply
  | OpSubtract

data BackendOperatorOrd
  = OpEq
  | OpNotEq
  | OpGt
  | OpGte
  | OpLt
  | OpLte

derive instance Functor BackendSyntax

instance Foldable BackendSyntax where
  foldr a = foldrDefault a
  foldl a = foldlDefault a
  foldMap f = case _ of
    Var _ -> mempty
    Local _ _ -> mempty
    Lit lit ->
      case lit of
        LitArray as -> foldMap f as
        LitRecord as -> foldMap (foldMap f) as
        _ -> mempty
    App a bs -> f a <> foldMap f bs
    Abs _ b -> f b
    UncurriedApp a bs -> f a <> foldMap f bs
    UncurriedAbs _ b -> f b
    UncurriedEffectApp a bs -> f a <> foldMap f bs
    UncurriedEffectAbs _ b -> f b
    Accessor a _ -> f a
    Update a bs -> f a <> foldMap (foldMap f) bs
    LetRec _ as b -> foldMap (foldMap f) as <> f b
    Let _ _ b c -> f b <> f c
    EffectBind _ _ b c -> f b <> f c
    EffectPure a -> f a
    Branch as b -> foldMap (foldMap f) as <> foldMap f b
    PrimOp a -> foldMap f a
    CtorSaturated _ _ cs -> foldMap (foldMap f) cs
    CtorDef _ _ -> mempty
    Fail _ -> mempty

instance Traversable BackendSyntax where
  sequence a = sequenceDefault a
  traverse f = case _ of
    Var a ->
      pure (Var a)
    Local a b ->
      pure (Local a b)
    Lit lit ->
      case lit of
        LitInt a -> pure (Lit (LitInt a))
        LitNumber a -> pure (Lit (LitNumber a))
        LitString a -> pure (Lit (LitString a))
        LitChar a -> pure (Lit (LitChar a))
        LitBoolean a -> pure (Lit (LitBoolean a))
        LitArray as -> Lit <<< LitArray <$> traverse f as
        LitRecord as -> Lit <<< LitRecord <$> traverse (traverse f) as
    App a bs ->
      App <$> f a <*> traverse f bs
    Abs as b ->
      Abs as <$> f b
    UncurriedApp a bs ->
      UncurriedApp <$> f a <*> traverse f bs
    UncurriedAbs as b ->
      UncurriedAbs as <$> f b
    UncurriedEffectApp a bs ->
      UncurriedEffectApp <$> f a <*> traverse f bs
    UncurriedEffectAbs as b ->
      UncurriedEffectAbs as <$> f b
    Accessor a b ->
      flip Accessor b <$> f a
    Update a bs ->
      Update <$> f a <*> traverse (traverse f) bs
    CtorDef a bs ->
      pure (CtorDef a bs)
    CtorSaturated a b cs ->
      CtorSaturated a b <$> traverse (traverse f) cs
    LetRec lvl as b ->
      LetRec lvl <$> traverse (traverse f) as <*> f b
    Let ident lvl b c ->
      Let ident lvl <$> f b <*> f c
    EffectBind ident lvl b c ->
      EffectBind ident lvl <$> f b <*> f c
    EffectPure a ->
      EffectPure <$> f a
    Branch as b ->
      Branch <$> traverse (traverse f) as <*> traverse f b
    PrimOp a ->
      PrimOp <$> traverse f a
    Fail a ->
      pure (Fail a)

derive instance Functor Pair

instance Foldable Pair where
  foldl f acc (Pair a b) = f (f acc a) b
  foldr f acc (Pair a b) = f a (f b acc)
  foldMap f (Pair a b) = f a <> f b

instance Traversable Pair where
  sequence a = sequenceDefault a
  traverse f (Pair a b) = Pair <$> f a <*> f b

derive instance Functor BackendOperator

instance Foldable BackendOperator where
  foldr a = foldrDefault a
  foldl a = foldlDefault a
  foldMap f = case _ of
    Op1 _ a -> f a
    Op2 _ a b -> f a <> f b

instance Traversable BackendOperator where
  sequence a = sequenceDefault a
  traverse f = case _ of
    Op1 a b -> Op1 a <$> f b
    Op2 a b c -> Op2 a <$> f b <*> f c

class HasSyntax a where
  syntaxOf :: a -> Maybe (BackendSyntax a)
