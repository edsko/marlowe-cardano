module Component.CurrentStepActions.State
  ( component
  ) where

import Prologue

import Component.CurrentStepActions.Types (Action(..), DSL, Input', Msg(..))
import Component.CurrentStepActions.View (currentStepActions)
import Data.Map as Map
import Data.Maybe (maybe)
import Effect.Aff.Class (class MonadAff)
import Halogen (raise)
import Halogen as H
import Halogen.Component.Reactive as HR
import Halogen.Store.Connect (connect)
import Halogen.Store.Monad (class MonadStore)
import Halogen.Store.Select (selectEq)
import Store as Store

component
  :: forall query m
   . MonadAff m
  => MonadStore Store.Action Store.Store m
  => H.Component query Input' Msg m
component = connect (selectEq _.roleTokens) $
  HR.mkReactiveComponent
    { deriveState: const unit
    , initialTransient: { choiceValues: Map.empty }
    , render: currentStepActions
    , eval: HR.fromHandleAction handleAction
    }

handleAction :: forall m. Action -> DSL m Unit
handleAction (SelectAction namedAction chosenNum) =
  raise $ ActionSelected namedAction chosenNum

handleAction (ChangeChoice choiceId chosenNum) =
  H.modify_ \s ->
    s
      { transient = s.transient
          { choiceValues = s.transient.choiceValues
              # maybe (Map.delete choiceId) (Map.insert choiceId) chosenNum
          }
      }
