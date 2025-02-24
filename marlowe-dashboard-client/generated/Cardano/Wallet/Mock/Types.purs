-- File auto generated by purescript-bridge! --
module Cardano.Wallet.Mock.Types where

import Prelude

import Control.Lazy (defer)
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
import Data.Newtype (class Newtype, unwrap)
import Data.PaymentPubKeyHash (PaymentPubKeyHash)
import Data.Show.Generic (genericShow)
import Data.Tuple.Nested ((/\))
import Type.Proxy (Proxy(Proxy))
import Wallet.Emulator.Wallet (Wallet)

newtype WalletInfo = WalletInfo
  { wiWallet :: Wallet
  , wiPaymentPubKeyHash :: PaymentPubKeyHash
  }

instance Show WalletInfo where
  show a = genericShow a

instance EncodeJson WalletInfo where
  encodeJson = defer \_ -> E.encode $ unwrap >$<
    ( E.record
        { wiWallet: E.value :: _ Wallet
        , wiPaymentPubKeyHash: E.value :: _ PaymentPubKeyHash
        }
    )

instance DecodeJson WalletInfo where
  decodeJson = defer \_ -> D.decode $
    ( WalletInfo <$> D.record "WalletInfo"
        { wiWallet: D.value :: _ Wallet
        , wiPaymentPubKeyHash: D.value :: _ PaymentPubKeyHash
        }
    )

derive instance Generic WalletInfo _

derive instance Newtype WalletInfo _

--------------------------------------------------------------------------------

_WalletInfo
  :: Iso' WalletInfo
       { wiWallet :: Wallet, wiPaymentPubKeyHash :: PaymentPubKeyHash }
_WalletInfo = _Newtype
