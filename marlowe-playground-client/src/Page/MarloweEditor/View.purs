module Page.MarloweEditor.View where

import Prologue hiding (div)

import Component.BottomPanel.Types (Action(..)) as BottomPanel
import Component.BottomPanel.View (render) as BottomPanel
import Component.Popper (Placement(..))
import Component.Tooltip.State (tooltip)
import Component.Tooltip.Types (ReferenceId(..))
import Data.Array as Array
import Data.Bifunctor (bimap)
import Data.Enum (toEnum, upFromIncluding)
import Data.Lens ((^.))
import Data.Maybe (maybe)
import Effect.Aff.Class (class MonadAff)
import Halogen (ClassName(..), ComponentHTML)
import Halogen.Classes
  ( flex
  , flexCol
  , flexGrow
  , fullHeight
  , group
  , maxH70p
  , minH0
  , overflowHidden
  , paddingX
  )
import Halogen.Css (classNames)
import Halogen.Extra (renderSubmodule)
import Halogen.HTML (HTML, button, div, option, section, select, slot, text)
import Halogen.HTML.Events (onClick, onSelectedIndexChange)
import Halogen.HTML.Properties (class_, classes, disabled, title)
import Halogen.HTML.Properties as HP
import Halogen.Monaco (monacoComponent)
import Language.Marlowe.Extended.V1.Metadata (MetaData)
import MainFrame.Types (ChildSlots, _marloweEditorPageSlot)
import Marlowe.Monaco as MM
import Page.MarloweEditor.BottomPanel (panelContents)
import Page.MarloweEditor.Types
  ( Action(..)
  , BottomPanelView(..)
  , State
  , _bottomPanelState
  , _editorErrors
  , _editorWarnings
  , _keybindings
  , contractHasErrors
  , contractHasHoles
  )

render
  :: forall m
   . MonadAff m
  => MetaData
  -> State
  -> ComponentHTML Action ChildSlots m
render metadata state =
  div [ classes [ flex, flexCol, fullHeight, paddingX ] ]
    [ section [ classes [ minH0, flexGrow, overflowHidden ] ]
        [ marloweEditor ]
    , section [ classes [ maxH70p ] ]
        [ renderSubmodule
            _bottomPanelState
            BottomPanelAction
            (BottomPanel.render panelTitles wrapBottomPanelContents)
            state
        ]
    ]
  where
  panelTitles =
    [ { title: "Metadata", view: MetadataView, classes: [] }
    , { title: "Static Analysis", view: StaticAnalysisView, classes: [] }
    , { title: warningsTitle, view: MarloweWarningsView, classes: [] }
    , { title: errorsTitle, view: MarloweErrorsView, classes: [] }
    ]

  withCount str arry = str <>
    if Array.null arry then "" else " (" <> show (Array.length arry) <> ")"

  warningsTitle = withCount "Warnings" $ state ^. _editorWarnings

  errorsTitle = withCount "Errors" $ state ^. _editorErrors

  -- TODO: improve this wrapper helper
  actionWrapper = BottomPanel.PanelAction

  wrapBottomPanelContents panelView = bimap (map actionWrapper) actionWrapper $
    panelContents state metadata panelView

otherActions
  :: forall m. MonadAff m => State -> ComponentHTML Action ChildSlots m
otherActions state =
  div [ classes [ group ] ]
    [ editorOptions state
    , viewAsBlocklyButton state
    , sendToSimulatorButton state
    ]

sendToSimulatorButton
  :: forall m
   . MonadAff m
  => State
  -> ComponentHTML Action ChildSlots m
sendToSimulatorButton state =
  div [ HP.id "marloweSendToSimulator", classNames [ "relative" ] ]
    [ button
        [ onClick $ const SendToSimulator
        , disabled disabled'
        , classNames [ "btn" ]
        ]
        [ text "Send To Simulator" ]
    , tooltip tooltipMessage (RefId "marloweSendToSimulator") Bottom
    ]
  where
  disabled' = contractHasErrors state || contractHasHoles state

  tooltipMessage =
    if disabled' then
      "A contract can only be sent to the simulator if it has no errors and no holes"
    else
      "Execute this contract in the Marlowe simulator"

viewAsBlocklyButton :: forall p. State -> HTML p Action
viewAsBlocklyButton state =
  button
    ( [ onClick $ const ViewAsBlockly
      , disabled disabled'
      , classNames [ "btn" ]
      ]
        <> disabledTooltip
    )
    [ text "View as blocks" ]
  where
  -- We only enable this button when the contract is valid, even if it has holes
  disabled' = contractHasErrors state

  disabledTooltip =
    if disabled' then
      [ title "We can't send the contract to blockly while it has errors"
      ]
    else
      []

editorOptions :: forall p. State -> HTML p Action
editorOptions state =
  div [ class_ (ClassName "editor-options") ]
    [ select
        [ HP.id "editor-options"
        , HP.value $ show $ state ^. _keybindings
        , onSelectedIndexChange (maybe DoNothing ChangeKeyBindings <<< toEnum)
        ]
        (map keybindingItem (upFromIncluding bottom))
    ]
  where
  keybindingItem item =
    if state ^. _keybindings == item then
      option [ class_ (ClassName "selected-item"), HP.value (show item) ]
        [ text $ show item ]
    else
      option [ HP.value (show item) ] [ text $ show item ]

marloweEditor :: forall m. MonadAff m => ComponentHTML Action ChildSlots m
marloweEditor = slot _marloweEditorPageSlot unit component unit
  HandleEditorMessage
  where
  component = monacoComponent $ MM.settings $ const $ pure unit
