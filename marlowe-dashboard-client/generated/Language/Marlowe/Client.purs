-- File auto generated by purescript-bridge! --
module Language.Marlowe.Client where

import Prelude

import Control.Lazy (defer)
import Data.Argonaut (encodeJson, jsonNull)
import Data.Argonaut.Decode (class DecodeJson)
import Data.Argonaut.Decode.Aeson ((</$\>), (</*\>), (</\>))
import Data.Argonaut.Decode.Aeson as D
import Data.Argonaut.Encode (class EncodeJson)
import Data.Argonaut.Encode.Aeson ((>$<), (>/\<))
import Data.Argonaut.Encode.Aeson as E
import Data.Array (nubEq)
import Data.Generic.Rep (class Generic)
import Data.Lens (Iso', Lens', Prism', iso, prism')
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Lens.Record (prop)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Monoid (class Monoid, mempty)
import Data.Newtype (class Newtype, unwrap)
import Data.Semigroup (class Semigroup, append)
import Data.Show.Generic (genericShow)
import Data.Tuple.Nested ((/\))
import Data.UUID.Argonaut (UUID)
import Language.Marlowe.Client.History (RolePayout)
import Language.Marlowe.Core.V1.Semantics.Types
  ( MarloweData
  , MarloweParams
  , TransactionError
  , TransactionInput
  )
import Plutus.Contract.Error (ContractError)
import Plutus.V1.Ledger.Address (Address)
import Type.Proxy (Proxy(Proxy))

newtype ContractHistory = ContractHistory
  { chParams :: MarloweParams
  , chInitialData :: MarloweData
  , chHistory :: Array TransactionInput
  , chAddress :: Address
  , chUnspentPayouts :: UnspentPayouts
  }

derive instance Eq ContractHistory

instance Show ContractHistory where
  show a = genericShow a

instance EncodeJson ContractHistory where
  encodeJson = defer \_ -> E.encode $ unwrap >$<
    ( E.record
        { chParams: E.value :: _ MarloweParams
        , chInitialData: E.value :: _ MarloweData
        , chHistory: E.value :: _ (Array TransactionInput)
        , chAddress: E.value :: _ Address
        , chUnspentPayouts: E.value :: _ UnspentPayouts
        }
    )

instance DecodeJson ContractHistory where
  decodeJson = defer \_ -> D.decode $
    ( ContractHistory <$> D.record "ContractHistory"
        { chParams: D.value :: _ MarloweParams
        , chInitialData: D.value :: _ MarloweData
        , chHistory: D.value :: _ (Array TransactionInput)
        , chAddress: D.value :: _ Address
        , chUnspentPayouts: D.value :: _ UnspentPayouts
        }
    )

derive instance Generic ContractHistory _

derive instance Newtype ContractHistory _

--------------------------------------------------------------------------------

_ContractHistory
  :: Iso' ContractHistory
       { chParams :: MarloweParams
       , chInitialData :: MarloweData
       , chHistory :: Array TransactionInput
       , chAddress :: Address
       , chUnspentPayouts :: UnspentPayouts
       }
_ContractHistory = _Newtype

--------------------------------------------------------------------------------

data EndpointResponse a e
  = EndpointSuccess UUID a
  | EndpointException UUID String e

derive instance (Eq a, Eq e) => Eq (EndpointResponse a e)

instance (Show a, Show e) => Show (EndpointResponse a e) where
  show a = genericShow a

instance (EncodeJson a, EncodeJson e) => EncodeJson (EndpointResponse a e) where
  encodeJson = defer \_ -> case _ of
    EndpointSuccess a b -> E.encodeTagged "EndpointSuccess" (a /\ b)
      (E.tuple (E.value >/\< E.value))
    EndpointException a b c -> E.encodeTagged "EndpointException" (a /\ b /\ c)
      (E.tuple (E.value >/\< E.value >/\< E.value))

instance (DecodeJson a, DecodeJson e) => DecodeJson (EndpointResponse a e) where
  decodeJson = defer \_ -> D.decode
    $ D.sumType "EndpointResponse"
    $ Map.fromFoldable
        [ "EndpointSuccess" /\ D.content
            (D.tuple $ EndpointSuccess </$\> D.value </*\> D.value)
        , "EndpointException" /\ D.content
            ( D.tuple $ EndpointException </$\> D.value </*\> D.value </*\>
                D.value
            )
        ]

derive instance Generic (EndpointResponse a e) _

--------------------------------------------------------------------------------

_EndpointSuccess
  :: forall a e. Prism' (EndpointResponse a e) { a :: UUID, b :: a }
_EndpointSuccess = prism' (\{ a, b } -> (EndpointSuccess a b)) case _ of
  (EndpointSuccess a b) -> Just { a, b }
  _ -> Nothing

_EndpointException
  :: forall a e
   . Prism' (EndpointResponse a e) { a :: UUID, b :: String, c :: e }
_EndpointException = prism' (\{ a, b, c } -> (EndpointException a b c))
  case _ of
    (EndpointException a b c) -> Just { a, b, c }
    _ -> Nothing

--------------------------------------------------------------------------------

data MarloweEndpointResult
  = CreateResponse MarloweParams
  | ApplyInputsResponse
  | AutoResponse
  | RedeemResponse
  | CloseResponse

derive instance Eq MarloweEndpointResult

instance Show MarloweEndpointResult where
  show a = genericShow a

instance EncodeJson MarloweEndpointResult where
  encodeJson = defer \_ -> case _ of
    CreateResponse a -> E.encodeTagged "CreateResponse" a E.value
    ApplyInputsResponse -> encodeJson
      { tag: "ApplyInputsResponse", contents: jsonNull }
    AutoResponse -> encodeJson { tag: "AutoResponse", contents: jsonNull }
    RedeemResponse -> encodeJson { tag: "RedeemResponse", contents: jsonNull }
    CloseResponse -> encodeJson { tag: "CloseResponse", contents: jsonNull }

instance DecodeJson MarloweEndpointResult where
  decodeJson = defer \_ -> D.decode
    $ D.sumType "MarloweEndpointResult"
    $ Map.fromFoldable
        [ "CreateResponse" /\ D.content (CreateResponse <$> D.value)
        , "ApplyInputsResponse" /\ pure ApplyInputsResponse
        , "AutoResponse" /\ pure AutoResponse
        , "RedeemResponse" /\ pure RedeemResponse
        , "CloseResponse" /\ pure CloseResponse
        ]

derive instance Generic MarloweEndpointResult _

--------------------------------------------------------------------------------

_CreateResponse :: Prism' MarloweEndpointResult MarloweParams
_CreateResponse = prism' CreateResponse case _ of
  (CreateResponse a) -> Just a
  _ -> Nothing

_ApplyInputsResponse :: Prism' MarloweEndpointResult Unit
_ApplyInputsResponse = prism' (const ApplyInputsResponse) case _ of
  ApplyInputsResponse -> Just unit
  _ -> Nothing

_AutoResponse :: Prism' MarloweEndpointResult Unit
_AutoResponse = prism' (const AutoResponse) case _ of
  AutoResponse -> Just unit
  _ -> Nothing

_RedeemResponse :: Prism' MarloweEndpointResult Unit
_RedeemResponse = prism' (const RedeemResponse) case _ of
  RedeemResponse -> Just unit
  _ -> Nothing

_CloseResponse :: Prism' MarloweEndpointResult Unit
_CloseResponse = prism' (const CloseResponse) case _ of
  CloseResponse -> Just unit
  _ -> Nothing

--------------------------------------------------------------------------------

data MarloweError
  = TransitionError
  | AmbiguousOnChainState
  | UnableToExtractTransition
  | OnChainStateNotFound
  | MarloweEvaluationError TransactionError
  | OtherContractError ContractError

derive instance Eq MarloweError

instance EncodeJson MarloweError where
  encodeJson = defer \_ -> case _ of
    TransitionError -> encodeJson { tag: "TransitionError", contents: jsonNull }
    AmbiguousOnChainState -> encodeJson
      { tag: "AmbiguousOnChainState", contents: jsonNull }
    UnableToExtractTransition -> encodeJson
      { tag: "UnableToExtractTransition", contents: jsonNull }
    OnChainStateNotFound -> encodeJson
      { tag: "OnChainStateNotFound", contents: jsonNull }
    MarloweEvaluationError a -> E.encodeTagged "MarloweEvaluationError" a
      E.value
    OtherContractError a -> E.encodeTagged "OtherContractError" a E.value

instance DecodeJson MarloweError where
  decodeJson = defer \_ -> D.decode
    $ D.sumType "MarloweError"
    $ Map.fromFoldable
        [ "TransitionError" /\ pure TransitionError
        , "AmbiguousOnChainState" /\ pure AmbiguousOnChainState
        , "UnableToExtractTransition" /\ pure UnableToExtractTransition
        , "OnChainStateNotFound" /\ pure OnChainStateNotFound
        , "MarloweEvaluationError" /\ D.content
            (MarloweEvaluationError <$> D.value)
        , "OtherContractError" /\ D.content (OtherContractError <$> D.value)
        ]

derive instance Generic MarloweError _

--------------------------------------------------------------------------------

_TransitionError :: Prism' MarloweError Unit
_TransitionError = prism' (const TransitionError) case _ of
  TransitionError -> Just unit
  _ -> Nothing

_AmbiguousOnChainState :: Prism' MarloweError Unit
_AmbiguousOnChainState = prism' (const AmbiguousOnChainState) case _ of
  AmbiguousOnChainState -> Just unit
  _ -> Nothing

_UnableToExtractTransition :: Prism' MarloweError Unit
_UnableToExtractTransition = prism' (const UnableToExtractTransition) case _ of
  UnableToExtractTransition -> Just unit
  _ -> Nothing

_OnChainStateNotFound :: Prism' MarloweError Unit
_OnChainStateNotFound = prism' (const OnChainStateNotFound) case _ of
  OnChainStateNotFound -> Just unit
  _ -> Nothing

_MarloweEvaluationError :: Prism' MarloweError TransactionError
_MarloweEvaluationError = prism' MarloweEvaluationError case _ of
  (MarloweEvaluationError a) -> Just a
  _ -> Nothing

_OtherContractError :: Prism' MarloweError ContractError
_OtherContractError = prism' OtherContractError case _ of
  (OtherContractError a) -> Just a
  _ -> Nothing

--------------------------------------------------------------------------------

newtype UnspentPayouts = UnspentPayouts (Array RolePayout)

derive instance Eq UnspentPayouts

instance Show UnspentPayouts where
  show a = genericShow a

instance EncodeJson UnspentPayouts where
  encodeJson = defer \_ -> E.encode $ unwrap >$< E.value

instance DecodeJson UnspentPayouts where
  decodeJson = defer \_ -> D.decode $ (UnspentPayouts <$> D.value)

instance Monoid UnspentPayouts where
  mempty = UnspentPayouts mempty

instance Semigroup UnspentPayouts where
  append (UnspentPayouts p1) (UnspentPayouts p2) = UnspentPayouts $ nubEq
    (append p1 p2)

derive instance Generic UnspentPayouts _

derive instance Newtype UnspentPayouts _

--------------------------------------------------------------------------------

_UnspentPayouts :: Iso' UnspentPayouts (Array RolePayout)
_UnspentPayouts = _Newtype
