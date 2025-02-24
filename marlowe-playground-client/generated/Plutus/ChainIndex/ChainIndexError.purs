-- File auto generated by purescript-bridge! --
module Plutus.ChainIndex.ChainIndexError where

import Prelude

import Control.Lazy (defer)
import Control.Monad.Freer.Extras.Beam (BeamError)
import Data.Argonaut (encodeJson, jsonNull)
import Data.Argonaut.Decode (class DecodeJson)
import Data.Argonaut.Decode.Aeson ((</$\>), (</*\>), (</\>))
import Data.Argonaut.Decode.Aeson as D
import Data.Argonaut.Encode (class EncodeJson)
import Data.Argonaut.Encode.Aeson ((>$<), (>/\<))
import Data.Argonaut.Encode.Aeson as E
import Data.Generic.Rep (class Generic)
import Data.Lens (Iso', Lens', Prism', iso, prism')
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Lens.Record (prop)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.Show.Generic (genericShow)
import Data.Tuple.Nested ((/\))
import Plutus.ChainIndex.Types (Point, Tip)
import Type.Proxy (Proxy(Proxy))

data ChainIndexError
  = InsertionFailed InsertUtxoFailed
  | RollbackFailed RollbackFailed
  | ResumeNotSupported
  | QueryFailedNoTip
  | BeamEffectError BeamError

derive instance Eq ChainIndexError

instance Show ChainIndexError where
  show a = genericShow a

instance EncodeJson ChainIndexError where
  encodeJson = defer \_ -> case _ of
    InsertionFailed a -> E.encodeTagged "InsertionFailed" a E.value
    RollbackFailed a -> E.encodeTagged "RollbackFailed" a E.value
    ResumeNotSupported -> encodeJson
      { tag: "ResumeNotSupported", contents: jsonNull }
    QueryFailedNoTip -> encodeJson
      { tag: "QueryFailedNoTip", contents: jsonNull }
    BeamEffectError a -> E.encodeTagged "BeamEffectError" a E.value

instance DecodeJson ChainIndexError where
  decodeJson = defer \_ -> D.decode
    $ D.sumType "ChainIndexError"
    $ Map.fromFoldable
        [ "InsertionFailed" /\ D.content (InsertionFailed <$> D.value)
        , "RollbackFailed" /\ D.content (RollbackFailed <$> D.value)
        , "ResumeNotSupported" /\ pure ResumeNotSupported
        , "QueryFailedNoTip" /\ pure QueryFailedNoTip
        , "BeamEffectError" /\ D.content (BeamEffectError <$> D.value)
        ]

derive instance Generic ChainIndexError _

--------------------------------------------------------------------------------

_InsertionFailed :: Prism' ChainIndexError InsertUtxoFailed
_InsertionFailed = prism' InsertionFailed case _ of
  (InsertionFailed a) -> Just a
  _ -> Nothing

_RollbackFailed :: Prism' ChainIndexError RollbackFailed
_RollbackFailed = prism' RollbackFailed case _ of
  (RollbackFailed a) -> Just a
  _ -> Nothing

_ResumeNotSupported :: Prism' ChainIndexError Unit
_ResumeNotSupported = prism' (const ResumeNotSupported) case _ of
  ResumeNotSupported -> Just unit
  _ -> Nothing

_QueryFailedNoTip :: Prism' ChainIndexError Unit
_QueryFailedNoTip = prism' (const QueryFailedNoTip) case _ of
  QueryFailedNoTip -> Just unit
  _ -> Nothing

_BeamEffectError :: Prism' ChainIndexError BeamError
_BeamEffectError = prism' BeamEffectError case _ of
  (BeamEffectError a) -> Just a
  _ -> Nothing

--------------------------------------------------------------------------------

data InsertUtxoFailed
  = DuplicateBlock Tip
  | InsertUtxoNoTip

derive instance Eq InsertUtxoFailed

instance Show InsertUtxoFailed where
  show a = genericShow a

instance EncodeJson InsertUtxoFailed where
  encodeJson = defer \_ -> case _ of
    DuplicateBlock a -> E.encodeTagged "DuplicateBlock" a E.value
    InsertUtxoNoTip -> encodeJson { tag: "InsertUtxoNoTip", contents: jsonNull }

instance DecodeJson InsertUtxoFailed where
  decodeJson = defer \_ -> D.decode
    $ D.sumType "InsertUtxoFailed"
    $ Map.fromFoldable
        [ "DuplicateBlock" /\ D.content (DuplicateBlock <$> D.value)
        , "InsertUtxoNoTip" /\ pure InsertUtxoNoTip
        ]

derive instance Generic InsertUtxoFailed _

--------------------------------------------------------------------------------

_DuplicateBlock :: Prism' InsertUtxoFailed Tip
_DuplicateBlock = prism' DuplicateBlock case _ of
  (DuplicateBlock a) -> Just a
  _ -> Nothing

_InsertUtxoNoTip :: Prism' InsertUtxoFailed Unit
_InsertUtxoNoTip = prism' (const InsertUtxoNoTip) case _ of
  InsertUtxoNoTip -> Just unit
  _ -> Nothing

--------------------------------------------------------------------------------

data RollbackFailed
  = RollbackNoTip
  | TipMismatch
      { foundTip :: Tip
      , targetPoint :: Point
      }
  | OldPointNotFound Point

derive instance Eq RollbackFailed

instance Show RollbackFailed where
  show a = genericShow a

instance EncodeJson RollbackFailed where
  encodeJson = defer \_ -> case _ of
    RollbackNoTip -> encodeJson { tag: "RollbackNoTip", contents: jsonNull }
    TipMismatch { foundTip, targetPoint } -> encodeJson
      { tag: "TipMismatch"
      , foundTip: flip E.encode foundTip E.value
      , targetPoint: flip E.encode targetPoint E.value
      }
    OldPointNotFound a -> E.encodeTagged "OldPointNotFound" a E.value

instance DecodeJson RollbackFailed where
  decodeJson = defer \_ -> D.decode
    $ D.sumType "RollbackFailed"
    $ Map.fromFoldable
        [ "RollbackNoTip" /\ pure RollbackNoTip
        , "TipMismatch" /\
            ( TipMismatch <$> D.object "TipMismatch"
                { foundTip: D.value :: _ Tip
                , targetPoint: D.value :: _ Point
                }
            )
        , "OldPointNotFound" /\ D.content (OldPointNotFound <$> D.value)
        ]

derive instance Generic RollbackFailed _

--------------------------------------------------------------------------------

_RollbackNoTip :: Prism' RollbackFailed Unit
_RollbackNoTip = prism' (const RollbackNoTip) case _ of
  RollbackNoTip -> Just unit
  _ -> Nothing

_TipMismatch :: Prism' RollbackFailed { foundTip :: Tip, targetPoint :: Point }
_TipMismatch = prism' TipMismatch case _ of
  (TipMismatch a) -> Just a
  _ -> Nothing

_OldPointNotFound :: Prism' RollbackFailed Point
_OldPointNotFound = prism' OldPointNotFound case _ of
  (OldPointNotFound a) -> Just a
  _ -> Nothing
