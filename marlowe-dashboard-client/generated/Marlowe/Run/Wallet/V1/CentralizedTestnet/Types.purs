-- File auto generated by purescript-bridge! --
module Marlowe.Run.Wallet.V1.CentralizedTestnet.Types where

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
import Data.MnemonicPhrase (MnemonicPhrase)
import Data.Newtype (class Newtype, unwrap)
import Data.Passphrase (Passphrase)
import Data.Show.Generic (genericShow)
import Data.Tuple.Nested ((/\))
import Data.WalletNickname (WalletNickname)
import Marlowe.Run.Wallet.V1.Types (WalletInfo)
import Type.Proxy (Proxy(Proxy))

newtype CreatePostData = CreatePostData
  { getCreatePassphrase :: Passphrase
  , getCreateWalletName :: WalletNickname
  }

derive instance Eq CreatePostData

instance Show CreatePostData where
  show a = genericShow a

instance EncodeJson CreatePostData where
  encodeJson = defer \_ -> E.encode $ unwrap >$<
    ( E.record
        { getCreatePassphrase: E.value :: _ Passphrase
        , getCreateWalletName: E.value :: _ WalletNickname
        }
    )

instance DecodeJson CreatePostData where
  decodeJson = defer \_ -> D.decode $
    ( CreatePostData <$> D.record "CreatePostData"
        { getCreatePassphrase: D.value :: _ Passphrase
        , getCreateWalletName: D.value :: _ WalletNickname
        }
    )

derive instance Generic CreatePostData _

derive instance Newtype CreatePostData _

--------------------------------------------------------------------------------

_CreatePostData
  :: Iso' CreatePostData
       { getCreatePassphrase :: Passphrase
       , getCreateWalletName :: WalletNickname
       }
_CreatePostData = _Newtype

--------------------------------------------------------------------------------

newtype CreateResponse = CreateResponse
  { mnemonic :: MnemonicPhrase
  , walletInfo :: WalletInfo
  }

derive instance Eq CreateResponse

instance Show CreateResponse where
  show a = genericShow a

instance EncodeJson CreateResponse where
  encodeJson = defer \_ -> E.encode $ unwrap >$<
    ( E.record
        { mnemonic: E.value :: _ MnemonicPhrase
        , walletInfo: E.value :: _ WalletInfo
        }
    )

instance DecodeJson CreateResponse where
  decodeJson = defer \_ -> D.decode $
    ( CreateResponse <$> D.record "CreateResponse"
        { mnemonic: D.value :: _ MnemonicPhrase
        , walletInfo: D.value :: _ WalletInfo
        }
    )

derive instance Generic CreateResponse _

derive instance Newtype CreateResponse _

--------------------------------------------------------------------------------

_CreateResponse
  :: Iso' CreateResponse
       { mnemonic :: MnemonicPhrase, walletInfo :: WalletInfo }
_CreateResponse = _Newtype

--------------------------------------------------------------------------------

newtype RestorePostData = RestorePostData
  { getRestoreMnemonicPhrase :: MnemonicPhrase
  , getRestorePassphrase :: Passphrase
  , getRestoreWalletName :: WalletNickname
  }

derive instance Eq RestorePostData

instance Show RestorePostData where
  show a = genericShow a

instance EncodeJson RestorePostData where
  encodeJson = defer \_ -> E.encode $ unwrap >$<
    ( E.record
        { getRestoreMnemonicPhrase: E.value :: _ MnemonicPhrase
        , getRestorePassphrase: E.value :: _ Passphrase
        , getRestoreWalletName: E.value :: _ WalletNickname
        }
    )

instance DecodeJson RestorePostData where
  decodeJson = defer \_ -> D.decode $
    ( RestorePostData <$> D.record "RestorePostData"
        { getRestoreMnemonicPhrase: D.value :: _ MnemonicPhrase
        , getRestorePassphrase: D.value :: _ Passphrase
        , getRestoreWalletName: D.value :: _ WalletNickname
        }
    )

derive instance Generic RestorePostData _

derive instance Newtype RestorePostData _

--------------------------------------------------------------------------------

_RestorePostData
  :: Iso' RestorePostData
       { getRestoreMnemonicPhrase :: MnemonicPhrase
       , getRestorePassphrase :: Passphrase
       , getRestoreWalletName :: WalletNickname
       }
_RestorePostData = _Newtype
