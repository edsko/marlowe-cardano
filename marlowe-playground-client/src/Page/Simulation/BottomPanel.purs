module Page.Simulation.BottomPanel (panelContents) where

import Prologue hiding (div)

import Data.BigInt.Argonaut (BigInt)
import Data.BigInt.Argonaut as BigInt
import Data.Foldable (foldMap)
import Data.Lens (preview, to, view, (^.))
import Data.Lens.NonEmptyList (_Head)
import Data.Map as Map
import Data.Tuple.Nested ((/\))
import Effect.Aff.Class (class MonadAff)
import Halogen (ComponentHTML)
import Halogen.Classes (first, rTableCell, rTableEmptyRow)
import Halogen.Classes as Classes
import Halogen.Css (classNames)
import Halogen.HTML (HTML, br_, div, div_, h4, section, text)
import Halogen.HTML.Properties (class_, classes)
import Humanize (humanizeValue)
import Language.Marlowe.Core.V1.Semantics.Types
  ( ChoiceId(..)
  , Party
  , Token
  , TransactionError
  , TransactionWarning
  , ValueId(..)
  , _accounts
  , _boundValues
  , _choices
  )
import Language.Marlowe.Extended.V1.Metadata (MetaData)
import MainFrame.Types (ChildSlots)
import Marlowe.ViewPartials (displayWarningList)
import Page.Simulation.Types (BottomPanelView(..), State)
import Pretty (renderPrettyParty)
import Simulator.Lenses
  ( _SimulationRunning
  , _executionState
  , _marloweState
  , _state
  , _transactionError
  , _transactionWarnings
  )

panelContents
  :: forall m action
   . MonadAff m
  => MetaData
  -> State
  -> BottomPanelView
  -> ComponentHTML action ChildSlots m
panelContents metadata state CurrentStateView = currentStateView metadata state

panelContents _ state WarningsAndErrorsView =
  let
    runtimeWarnings = view
      ( _marloweState <<< _Head <<< _executionState <<< _SimulationRunning <<<
          _transactionWarnings
      )
      state

    mRuntimeError = join $ preview
      ( _marloweState <<< _Head <<< _executionState <<< _SimulationRunning <<<
          _transactionError
      )
      state
  in
    section [ classNames [ "py-4" ] ] $
      [ warningsAndErrorsView runtimeWarnings mRuntimeError ]

currentStateView :: forall p action. MetaData -> State -> HTML p action
currentStateView metadata state =
  div [ classNames [ "Rtable", "Rtable--4cols", "py-4" ] ]
    ( tableRow
        { title: "Accounts"
        , emptyMessage: "No accounts have been used"
        , columns: ("Participant" /\ "Value" /\ mempty)
        , rowData: accountsData
        }
        <> tableRow
          { title: "Choices"
          , emptyMessage: "No Choices have been made"
          , columns: ("Choice ID" /\ "Participant" /\ "Chosen Value")
          , rowData: choicesData
          }
        <> tableRow
          { title: "Let Bindings"
          , emptyMessage: "No values have been bound"
          , columns: ("Identifier" /\ "Value" /\ mempty)
          , rowData: bindingsData
          }
    )
  where
  accountsData =
    let
      (accounts :: Array (Tuple (Tuple Party Token) BigInt)) = state ^.
        ( _marloweState <<< _Head <<< _executionState <<< _SimulationRunning
            <<< _state
            <<< _accounts
            <<< to Map.toUnfoldable
        )

      asTuple (Tuple (Tuple accountOwner tok) value) =
        renderPrettyParty metadata accountOwner
          /\ text (humanizeValue tok value)
          /\ text mempty
    in
      map asTuple accounts

  choicesData =
    let
      (choices :: Array (Tuple ChoiceId BigInt)) = state ^.
        ( _marloweState <<< _Head <<< _executionState <<< _SimulationRunning
            <<< _state
            <<< _choices
            <<< to Map.toUnfoldable
        )

      asTuple (Tuple (ChoiceId choiceName choiceOwner) value) =
        text (show choiceName) /\ renderPrettyParty metadata choiceOwner /\ text
          (BigInt.toString value)
    in
      map asTuple choices

  bindingsData =
    let
      (bindings :: Array (Tuple ValueId BigInt)) = state ^.
        ( _marloweState <<< _Head <<< _executionState <<< _SimulationRunning
            <<< _state
            <<< _boundValues
            <<< to Map.toUnfoldable
        )

      asTuple (Tuple (ValueId valueId) value) = text (show valueId)
        /\ text (BigInt.toString value)
        /\ text ""
    in
      map asTuple bindings

  tableRow { title, emptyMessage, rowData: [] } = emptyRow title emptyMessage

  tableRow { title, columns, rowData } = headerRow title columns <> foldMap
    (\dataTuple -> row dataTuple)
    rowData

  headerRow title (a /\ b /\ c) =
    [ div [ classes [ rTableCell, first, Classes.header ] ] [ text title ] ]
      <> map
        ( \x -> div [ classes [ rTableCell, rTableCell, Classes.header ] ]
            [ text x ]
        )
        [ a, b, c ]

  row (a /\ b /\ c) =
    [ div [ classes [ rTableCell, first ] ] [] ]
      <> map (\x -> div [ class_ rTableCell ] [ x ]) [ a, b, c ]

  emptyRow title message =
    [ div [ classes [ rTableCell, first, Classes.header ] ]
        [ text title ]
    , div [ classes [ rTableCell, rTableEmptyRow, Classes.header ] ]
        [ text message ]
    ]

warningsAndErrorsView
  :: forall action m
   . MonadAff m
  => Array TransactionWarning
  -> Maybe TransactionError
  -> ComponentHTML action ChildSlots m
warningsAndErrorsView [] Nothing = div_ [ text "No problems found" ]

warningsAndErrorsView [] (Just err) = errorView err

warningsAndErrorsView warnings Nothing = warningsView warnings

warningsAndErrorsView warnings (Just err) =
  div_
    [ errorView err
    , br_
    , warningsView warnings
    ]

warningsView
  :: forall action m
   . MonadAff m
  => Array TransactionWarning
  -> ComponentHTML action ChildSlots m
warningsView warnings =
  div_
    [ h4 [ classNames [ "font-semibold", "no-margins", "mb-2" ] ]
        [ text "Warnings" ]
    , displayWarningList warnings
    ]

errorView
  :: forall action m
   . MonadAff m
  => TransactionError
  -> ComponentHTML action ChildSlots m
errorView err =
  div_
    [ h4 [ classNames [ "font-semibold", "no-margins", "mb-2" ] ]
        [ text "Error" ]
    -- TODO: Improve the error messages
    , text $ show err
    ]
