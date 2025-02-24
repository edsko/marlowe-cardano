module Component.Amount where

import Prologue

import Data.BigInt.Argonaut (BigInt)
import Halogen.Css (classNames)
import Halogen.HTML (HTML, span, text)
import Humanize (humanizeValue)
import Language.Marlowe.Core.V1.Semantics.Types (Token)

amount :: forall w i. Token -> BigInt -> Array String -> HTML w i
amount token quantity classes =
  span [ classNames $ [ "font-semibold" ] <> classes ]
    [ text $ humanizeValue token quantity ]
